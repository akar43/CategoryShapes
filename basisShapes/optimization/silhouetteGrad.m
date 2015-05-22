function [silGrad] = silhouetteGrad(S,state,params,tree,points2d)

%silGrad = zeros(size(S));
numpoints = size(S,1);
neighbors = 10;
%mask = double(state.mask);
if(params.opt.truncatedLoss)
    outlierMagMax = 150;
    outlierMagMin = 50;
    prctileGood = 80;
else
    outlierMagMax = Inf;
    outlierMagMin = 0;
    prctileGood = 100;
end
%% Finding points projected outside the image
if(nargin<5)
    points2d = transform2d(S,state.cameraRot,state.cameraScale,state.translation);
    points2d = round(points2d);
end

if(nargin<4)
    tree = vl_kdtreebuild(points2d');
end
%% Finding correspoinding points for the boundary keypoints
bdry = state.bdry;
diff2d = zeros(size(points2d));
if(size(bdry,1)>0)
    %[ids,~] = kdtree_nearest_neighbor(tree,bdry);
    [ids,~] = vl_kdtreequery(tree,points2d',bdry','NUMNEIGHBORS',neighbors);
    % ids is neighbors X Nsil array
    bdryRep = repmat(bdry,neighbors,1);
    ids = ids';ids=ids(:);
    %size(ids)
    diffs = 1/neighbors*(bdryRep-points2d(ids,:));
    diff2d = [accumarray(ids,diffs(:,1),[size(points2d,1),1]) accumarray(ids,diffs(:,2),[size(points2d,1),1])];

    diffMag = sqrt(sum(diff2d.^2,2));

    %% Truncated silhouette loss for outliers
    thresh = prctile(diffMag(diffMag~=0),prctileGood);
    outlierMag = min(outlierMagMax,thresh);
    if(outlierMag<outlierMagMin)
        outlierMag = Inf;
    end
    outliersIdx = diffMag>outlierMag;
    diff2d(outliersIdx,:) = 0;
    %for i=1:size(ids,2)
    %    diff2d(ids(:,i),:) = diff2d(ids(:,i),:) + 1/neighbors*((repmat(bdry(i,:),neighbors,1) - points2d(ids(:,i),:)));
    %end
end

%% Computing gradient
diff3d = [diff2d zeros(numpoints,1)];
silGrad = 1/state.cameraScale*diff3d*state.cameraRot;
silGrad = silGrad/size(bdry,1);
end
