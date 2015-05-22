function [occGrad,occlusionErrors] = occlusionGrad(S,state)

occGrad = zeros(size(S));
numpoints = size(S,1);

mask = double(state.mask);
[Y,X]=size(mask);
mkp = mean(state.kps,2);% we had shifted everything by this when computing projected points so shift back now

%% Finding points projected outside the image
points2d = state.cameraScale*state.cameraRot*S'; %% Verify this later
points2d = points2d' + repmat(mkp',size(S,1),1);
points2d = round(points2d(:,1:2)); %% Verify correctness later

badX = double(points2d(:,1)>X) + double(points2d(:,1)<1);
badY = double(points2d(:,2)>Y) + double(points2d(:,2)<1);

%% Visualization
%imagesc(mask);hold on;
%plot(points2d(:,1),points2d(:,2));pause();
%close;

%% Restructuring to ease computation to determine of projected points inside silhoutte
points2d = points2d*[Y;1]-Y;
points2d(points2d>X*Y)=X*Y;
points2d(points2d<1)=1;

mask = double(mask(:)==0);
occlusionErrors = double((mask(points2d)+badX+badY)>0);
occGrad = repmat(occlusionErrors,1,3).*(repmat(mean(S,1),numpoints,1)-S);

end
