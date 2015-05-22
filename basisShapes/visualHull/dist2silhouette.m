function diff2d = dist2silhouette(S,state)


%% Parameters
params=get_params();
maxDistThresh = params.vis.maxTSDF;
minDistThresh = params.vis.minTSDF;

%% Initializations
bdry = zeros(size(state.mask));
bdryidx = sub2ind(size(state.mask),state.bdry(:,2),state.bdry(:,1));
bdry(bdryidx) = 1;
mask = state.mask;
[Y,X]=size(mask);
mkp = mean(state.kps,2);% we had shifted everything by this when computing projected points so shift back now

%% Finding points projected outside the image
points2d = state.cameraScale*state.cameraRot*S'; %% Verify this later
points2d = points2d' + repmat(mkp',size(S,1),1);
points2d = round(points2d(:,1:2)); %% Verify correctness later
%points2d = state.transform(S);
%points2d = round(points2d); %% Verify correctness later

badX = double(points2d(:,1)>X) + double(points2d(:,1)<1);
badY = double(points2d(:,2)>Y) + double(points2d(:,2)<1);

%% Padding the image
padding = round(max([max(0,1-min(points2d(:,1))),max(0,max(points2d(:,1))-X),...
          max(0,1-min(points2d(:,2))),max(0,max(points2d(:,2))-Y)]));
      
if(padding>10000)
    disp('Something is going wrong !! High value of padding');
    disp(padding);
end
pad_im = padarray(bdry,[padding padding]);

%% Image distance transform
%tic
[distMat,~] = bwdist(pad_im);
p2d = round(points2d+padding);
diff2d = distMat(sub2ind(size(pad_im),p2d(:,2),p2d(:,1)));

pad_mask = padarray(mask,[padding padding]);
inMask = pad_mask(sub2ind(size(pad_im),p2d(:,2),p2d(:,1)));
diff2d(inMask) = -diff2d(inMask);

diff2d = 1/state.cameraScale*diff2d;
diff2d = max(minDistThresh,diff2d);
diff2d = min(maxDistThresh,diff2d);
%toc

end
