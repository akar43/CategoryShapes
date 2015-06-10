function [] = fitKnownShapes(shapeModelOpt,statesDir,inferredShapesDir)

%% Setup optimization parameters
params = get_params();
relaxOpt = params.opt.relaxOpt;
lambda = params.opt.lambda;
maxiter = params.opt.testIters;
Sbar = shapeModelOpt.S;
V = shapeModelOpt.V;
N = shapeModelOpt.normals;
tri = shapeModelOpt.tri;
shapePriorInstance = shapeModelOpt.shapePriorInstance;

%% Read file names to fit basis shapes to
fnames = getFileNamesFromDirectory(statesDir,'types',{'.mat'});
%fnames = removeFlipNames(fnames);

%% Fit basis shapes
pBar =  TimedProgressBar( length(fnames), 30, ...
    'Fitting Basis shapes: Remaining ', ', Completed ', 'Fitted Basis Shapes in: ' );

parfor i=1:length(fnames)
    optimizeTestShape(fullfile(statesDir,fnames{i}),lambda,Sbar,V,N,tri,...
        shapePriorInstance,maxiter,fullfile(inferredShapesDir,fnames{i}),relaxOpt,params);
    pBar.progress();
end
pBar.stop();

end

%% Helper function to actually do the optimization
function [] = optimizeTestShape(fname,lambda,Sbar,V,N,tri,shapePriorInstance,maxiter,saveFile,relaxOpt,params)
%% PARAMS
stepsize = params.opt.testStepSize;
maxDelta = params.opt.maxDelta(3);

stateFile = fname;
state = load(stateFile);state = state.state;
K = size(V,2);
alpha = zeros(K,1);
numpoints = size(Sbar,1);

if(exist(saveFile,'file'))
    return;
end
%% iterations to learn alpha
initRot = state.cameraRot;
for iter=1:maxiter
    stepScale = 1;
    stepTr = 0.1;
    stepRot = 0.002;
    rotPriorStep = 0.1;

    if(det(state.cameraRot)>1.0001 || det(state.cameraRot)<0.9999)
        q = dcm2quat(state.cameraRot);
        state.cameraRot = quat2dcm(q/norm(q)); %wish I didn't have to do this - but such is life !
    end

    S = Sbar + reshape(V*alpha(:,1),numpoints,3);

    % Visualization
    if(mod(iter,10)==-1)
         vertices = S;
         subplot(2,2,1);
         verticesP = (state.cameraRot*vertices')';
         plot3(verticesP(:,1),verticesP(:,2),verticesP(:,3),'r.');
         axis equal;axis vis3d;view(0,-90);
         %disp(state.cameraRot);
         xlabel('x');ylabel('y');zlabel('z');

         subplot(2,2,2);
         p2 = transform2d(vertices,state.cameraRot,state.cameraScale,state.translation);
         imshow(color_seg(state.mask,state.im)); hold on; axis equal;axis off;axis vis3d;
         plot(p2(:,1),p2(:,2),'r.');

         subplot(2,2,3);
         imagesc(state.im);axis equal;axis off;axis vis3d;
         if(iter > maxiter - 10)
             disp('done');
             pause();close all;
         else
             pause(0.02);
         end
         clf
    end

    %% Image projection of points
    p2d = transform2d(S,state.cameraRot,state.cameraScale,state.translation);
    p2d = round(p2d);

    %% Occlusion Reasoning
    [occGrad,~] = occlusionGradOptimal(S,state,p2d);
    occGrad = lambda(1)*occGrad;

    %% Silhouette Consistency

    if(mod(iter-1,20)==0 || sum(ismember({'scale','translation'},relaxOpt)))
        % Finding projected points
        tree = vl_kdtreebuild(p2d');
    end
    silGrad = lambda(2)*silhouetteGrad(S,state,params, tree,p2d); %we also keep track of how many constraints each point violates
    silGrad = silGrad*500; % because we divide by number of silhouette points


    %% Keypoint Gradient
    if(ismember('kps',relaxOpt) && ~isempty(state.kps))
        kpGrad = lambda(6)*keypointGrad(S,state,params);
    else
        kpGrad = zeros(size(S));
    end

    %% Priors
    gradPriorAlpha = -(lambda(4)*numpoints)*alpha;
    shapePriorGrad = lambda(5)*shapePriorInstance(S);

    %% translation and scale gradients
    gradS2d = occGrad + silGrad + kpGrad;
    gradP3d = state.cameraScale*state.cameraRot*gradS2d';
    gradP2d = gradP3d(1:2,:);
    gradTr = mean(gradP2d,2);
    Sbar2d = bsxfun(@minus,p2d,mean(p2d,1));Sbar2d = Sbar2d';
    gradScale = mean(gradP2d(:).*Sbar2d(:))/state.cameraScale;

    %% Rotation gradients (experimental)
    gradRot = gradP3d*S/numpoints;
    %R = R_0 * expm(delta) = R_0(I+delta)
    gradDelta = state.cameraRot*gradRot;
    gradSkewDelta = (gradDelta-gradDelta')/2;
    deltaPrior = real(logm(state.cameraRot'*initRot));
    deltaPrior(abs(deltaPrior)<eps) = 0;
    normTwist = norm(gradSkewDelta,'fro');

    %% Deformation weight gradients
    gradShapePriorAlpha(:,1) = V'*shapePriorGrad(:);
    gradSilAlpha = V'*silGrad(:);
    gradOcclusionAlpha = V'*occGrad(:);
    gradKeypointAlpha = V'*kpGrad(:);
    gradAlpha = gradOcclusionAlpha + gradPriorAlpha + gradSilAlpha + gradShapePriorAlpha + gradKeypointAlpha; % + gradICPAlpha


    %% Updating transformation parameters
    step = min(maxDelta/max(max(abs(gradAlpha))),stepsize);
    if(iter > maxiter/2)
        alpha = alpha+step*gradAlpha;
    end
    stepScale = min(stepScale,0.02*state.cameraScale/abs(gradScale));
    if(ismember('scale',relaxOpt))
        state.cameraScale = state.cameraScale + gradScale*stepScale;
    end
    stepTr = min(stepTr,2/max(abs(gradTr)));
    if(ismember('translation',relaxOpt))
        state.translation = state.translation + gradTr*stepTr;
    end
    if(ismember('rotation',relaxOpt))
        stepRot = min(stepRot,pi/(50*normTwist));
        %stepRot = min(stepRot,pi/(25*normTwist));
        delta = expm(stepRot*gradSkewDelta + deltaPrior*rotPriorStep);
        if(det(delta) ~= 1)
            %disp('wtf');
	        %keyboard;
            %delta(1,:) = delta(1,:)/norm(delta(1,:));
            %delta(2,:) = delta(2,:)/norm(delta(2,:));
            %delta(3,:) = delta(3,:)/norm(delta(3,:));
        end
        state.cameraRot = state.cameraRot*delta;
    end
end

S = Sbar + reshape(V*alpha,numpoints,3);

%% Saving
state.alpha = alpha;
state.normals = N;
state.tri = tri;
state.S = S;
save(saveFile,'state');

end
