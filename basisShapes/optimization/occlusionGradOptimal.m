function [occGrad,occlusionErrors] = occlusionGradOptimal(S,state,p2d)

%mask = double(state.mask);
[Y,X]=size(state.mask);
%mkp = mean(state.kps,2);% we had shifted everything by this when computing projected points so shift back now
%occlusionErrors = zeros(numpoints,1);

%% Finding points projected outside the image
%points2d = state.cameraScale*state.cameraRot*S'; %% Verify this later
%points2d = points2d' + repmat(mkp',size(S,1),1);
%points2d = round(points2d(:,1:2)); %% Verify correctness later
if(nargin<3)
    p2d = transform2d(S,state.cameraRot,state.cameraScale,state.translation);
    p2d = round(p2d); %% Verify correctness later
end

badX = (p2d(:,1)>X);p2d(badX,1)=X;
badX = (p2d(:,1)<1);p2d(badX,1)=1;
badY = (p2d(:,2)>Y);p2d(badY,2)=Y;
badY = (p2d(:,2)<1);p2d(badY,2)=1;

%% Computing nearest silhoutte point and gradient
%tic
diff3d = zeros(size(S));
IDX_2 = state.occlusionIDX;
sil_nbridx = IDX_2(sub2ind([Y X],p2d(:,2),p2d(:,1)));
[Ys,Xs] = ind2sub([Y X],sil_nbridx);
diff2d = double([Xs Ys]) - p2d;
diff3d(:,1:2)=diff2d;

occlusionErrors = double(sum(abs(diff3d),2)>=2);
occGrad = 1/state.cameraScale*diff3d*state.cameraRot;

end
