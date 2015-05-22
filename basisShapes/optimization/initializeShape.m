function [shape,V,shapePriorMean,deformationPrior,shapePriorInstance,tris,fvN] = initializeShape(statesDir)
% assume that squared norm of each deformation of V = numpoints.
% norm(V(:,k))^2 = numpoints; for all k

%globals
numNeighbors = 10;

%% Initializing Shape - Visual Hull

params=get_params();
from = params.vis.voxelsFrom;to = params.vis.voxelsTo;
steps = params.vis.voxelsSteps;
normalThresh = params.opt.normalThresh;
numbasis = params.opt.numbasis;

for step = steps
    %fprintf('Initializing using Visual Hull...\n');
    rangeXYZ = round((to-from)/step)+1;
    [X,Y,Z] = ndgrid(from(1):step:to(1), from(2):step:to(2), from(3):step:to(3));
    [voxels,occlusions] = learnVisualHull(from,to,step,statesDir);
    occ = reshape(occlusions,rangeXYZ);
    voxelInds = round((voxels-repmat(from,size(voxels,1),1))/step)+1;
    occ(sub2ind(rangeXYZ,voxelInds(:,1),voxelInds(:,2),voxelInds(:,3)))=occlusions;
    thresh = 0.2;
    fv = isosurface(X,Y,Z,occ,thresh);
    thisClass = pascalClassIndex(params.class);
    fv = reducepatch(fv,params.vis.numFacesInMesh(thisClass));
    fvN = patchnormals(fv);

    %if(size(fv.vertices,1) >= params.vis.minPointsInMesh)
    %    break;
    %end
end

%% Computing edges, triangles etc from visHull shape
shape = fv.vertices;
tris = fv.faces;
numpoints = size(shape,1);
edges = [];
for t=1:size(tris,1)
    tri = tris(t,:);
    edgesThis = [tri(1) tri(2);tri(2) tri(3);tri(3) tri(1)];
    edges = [edges;edgesThis];
end
edges = [edges;fliplr(edges)];
edges = unique(edges,'rows');

%% Computing triangles and radial directions
normS = sqrt(sum(shape.^2,2));
directions = shape./repmat(normS,1,3);

%% Initializing Vs
V = rand(3*numpoints,numbasis)*2 - 1;

if params.opt.spherical
    for k=1:numbasis
        deformation = reshape(V(:,k),numpoints,3);
        projections = sum(deformation.*directions,2);
        deformation = directions.*repmat(projections,1,3);
        V(:,k)=deformation(:);
    end
end

for k=1:numbasis
    V(:,k)=V(:,k)/norm(V(:,k));
end
V = V*sqrt(numpoints);
%% Computing adjacency matrix which is used for prior function and remains unchanged (forever)

tree = vl_kdtreebuild(shape');
adj = vl_kdtreequery(tree,shape',shape','NUMNEIGHBORS',numNeighbors);
adj = adj';
%save(fullfile(shapeDir,'models','currentAdj.mat'),'adj');

%% defining the prior function. Basically wants the points in the adjacency matrix to be close to each other.
function grad = shapePenalty(s,springPenalty)
    if(nargin<2)
        springPenalty=1;
        %springPenalty=0;
    end
    grad = zeros(size(s));
    mpt = mean(s,1);
    numpts = size(s,1);
    diff = (s - repmat(mpt,numpts,1));
    r_sq = mean(sum(diff.*diff,2));
    delta = 2*sqrt(r_sq/numpts);
    for i=2:size(adj,2) %the first is the point itself
        tmp = s(adj(:,i),:)-s;
        tmp2 = zeros(size(s));

        if (springPenalty==1)
            tmp2 = -delta*normr(tmp);
        end

        grad = grad + tmp + tmp2;
    end
end

%% Defining the laplacian smoothing prior
function grad = shapePenaltyLaplacian(s)
    ind = edges(:,2);
    N = size(s,1);
    diffs = s(edges(:,1),:) - s(ind,:);
    grad = [accumarray(ind,diffs(:,1),[N 1]) accumarray(ind,diffs(:,2),[N 1]) accumarray(ind,diffs(:,3),[N 1])];
end

%% Defining the prior function for normal consistency. Basically wants normals of adjacent triangles in the same direction - smooth shape
adjTriangles = [];
for i=1:size(tris,1)
    edgesThis = tris(i,:);
    commonTris = tris((find(sum(tris==edgesThis(1) | tris==edgesThis(2) | tris==edgesThis(3),2) > 1)),:); %triangles with one edge in common
    for j=1:size(commonTris,1)
        commonTri = commonTris(j,:);
        ind1 = (commonTri == edgesThis(1));
        ind2 = (commonTri == edgesThis(2));
        ind3 = (commonTri == edgesThis(3));
        if(sum(ind1)+sum(ind2)+sum(ind3))==2 %excluding the triangle itself
            if(sum(ind1)==0)
                adjTri = [edgesThis(1) edgesThis(2) edgesThis(3) commonTri(~(ind2 | ind3))];
            end

            if(sum(ind2)==0)
                adjTri = [edgesThis(2) edgesThis(1) edgesThis(3) commonTri(~(ind1 | ind3))];
            end

            if(sum(ind3)==0)
                adjTri = [edgesThis(3) edgesThis(2) edgesThis(1) commonTri(~(ind2 | ind1))];
            end
            adjTriangles = [adjTriangles;adjTri];
        end
    end
end

function grad = shapePenaltyNormal(s)
    v11s = s(adjTriangles(:,2),:)-s(adjTriangles(:,1),:);
    v21s = s(adjTriangles(:,3),:)-s(adjTriangles(:,1),:);
    v31s = s(adjTriangles(:,4),:)-s(adjTriangles(:,1),:);

    v12s = s(adjTriangles(:,2),:)-s(adjTriangles(:,4),:);
    v22s = s(adjTriangles(:,3),:)-s(adjTriangles(:,4),:);

    n1s = cross(v11s,v21s);
    n1s = normr(n1s);

    n2s = cross(v12s,v22s);
    n2s = normr(n2s);
    normDots = abs(sum(n1s.*n2s,2));

    projs = sum(v31s.*n1s,2).*double(normDots <= normalThresh);
    diffs = repmat(-projs,1,3).*n1s;
    grad = [accumarray(adjTriangles(:,4),diffs(:,1)),accumarray(adjTriangles(:,4),diffs(:,2)),accumarray(adjTriangles(:,4),diffs(:,3))];
end

%% defining the deformation prior function

function [gradV,gradAlpha] = deformationPenalty(V,alpha)
    gradAlpha = -numpoints*alpha; %since |V| = sqrt(numpoints)
    alphasq = sum(alpha.^2,2);
    gradV = zeros(size(V));
    for k=1:size(V,2)
        Vk = reshape(V(:,k),numpoints,3);
        gradVk = 60*shapePenaltyLaplacian(Vk);
        gradV(:,k)=gradVk(:)-alphasq(k)*V(:,k);
    end
end

%% defining no-penalty
function grad = noPenalty(s)
    grad = zeros(size(s));
end

%% Returning Priors

shapePriorMean = @shapePenalty;
shapePriorInstance = @shapePenaltyNormal;
deformationPrior = @deformationPenalty;

end
