function [shapeModelOpt] = learnDenseShape(statesDir,class,jobID)

%% Initializations
globals;
params=get_params();

%% Penalty coefficients and max allowed changes
lambda = params.opt.lambda;
maxDelta = params.opt.maxDelta;
stepsize = params.opt.trainStepSize;

%% Loading/Initializing using Visual Hull
shapeFile = fullfile(cachedir,class,sprintf('currentShape%s.mat',jobID));
initShapeFile = fullfile(cachedir,class,sprintf('InitShape%s.mat',jobID));

if(exist(initShapeFile,'file'))
    fprintf('Loading cached Visual Hull initialization from \n%s\n',initShapeFile);
    load(initShapeFile);
else
    [S,V,shapePriorMean,deformationPrior,shapePriorInstance,tri,normals] =...
        initializeShape(statesDir);
    initMesh = struct('vertices',S,'faces',tri);
    fnames = getFileNamesFromDirectory(statesDir,'types',{'.mat'},'mode','path');
    alpha = initializeAlpha(S,V,fnames);
    save(initShapeFile,'S','shapePriorMean','deformationPrior','shapePriorInstance',...
        'fnames','V','alpha','tri','normals','initMesh');
end

%% Iterating to learn shapes
fprintf('\nOptimizing shapes via block co-ordinate descentn\n');
fprintf('Iter\tKPGrad\tOccGrad\tSilGrad\tSIPrior\tShPrior\tDfPrior\tStep\n');
for iter = 1:params.opt.trainIters
    %disp(['Iteration ' int2str(iter)]);
    [gradS,gradV,gradAlpha] = refineShape(S,V,alpha,fnames,lambda,...
        shapePriorMean,deformationPrior,shapePriorInstance,iter);
    if(mod(iter,2))
        %% Updating shape & basis
        step = min([maxDelta(1)/max(max(abs(gradS))),maxDelta(2)...
            /max(max(abs(gradV))),stepsize]);
        fprintf('%3.5f\n',step);
        S = step*gradS + S;
        V = step*gradV + V;

        % Visualization
        if(mod(iter,100)==-1)
            close all;
            subplot(1,2,1);
            plot3(S(:,1),S(:,2),S(:,3),'b.');hold on;axis equal;
            subplot(1,2,2);
            trisurf(tri,S(:,1),S(:,2),S(:,3));axis equal;
            pause();close all;
        end
    else
        %% Normalizing alpha for each image
        mGrad = max(abs(gradAlpha),[],2);
        limGrad = min(mGrad,maxDelta(3)/stepsize);
        scale = limGrad./mGrad;
        gradAlpha = gradAlpha.*repmat(scale,1,size(gradAlpha,2));
        step = min(maxDelta(3)/max(max(abs(gradAlpha))),stepsize);
        fprintf('%3.5f\n',step);
        alpha = step*gradAlpha + alpha;
    end

    %% Renormalizing V
    for k=1:params.opt.numbasis
        den = norm(V(:,k))/sqrt(size(S,1));
        V(:,k)=V(:,k)/den;
        alpha(k,:)=den*alpha(k,:);
    end

end

save(shapeFile,'S','shapePriorMean','deformationPrior','shapePriorInstance',...
    'fnames','V','alpha','tri','normals','initMesh','params');
shapeModelOpt = load(shapeFile);
end
