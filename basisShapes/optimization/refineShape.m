function [gradS,gradV,gradAlpha] = refineShape(S,V,alpha,stateFiles,lambda,shapePrior,deformationPrior,shapePriorInstance,iter)

% V is (numpoints*3 X K)
% alpha is K X length(fnames)

%% Initializations
params = get_params();

%numcores = max(matlabpool('size'),1);

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    numcores = 0;
else
    numcores = poolobj.NumWorkers;
end

gradICPS = zeros(size(S));
gradICPV = zeros(size(V));
gradICPAlpha = zeros(size(alpha));
numpoints = size(S,1);
K = size(V,2);
numimages = length(stateFiles);

gOS = zeros([size(S) numcores]);
gOV = zeros([size(V) numcores]);
gOA = zeros([size(alpha) numcores]);
cO = zeros([numpoints,1,numcores]);

gSS = zeros([size(S) numcores]);
gSV = zeros([size(V) numcores]);
gSA = zeros([size(alpha) numcores]);

gPS = zeros([size(S) numcores]);
gPV = zeros([size(V) numcores]);
gPA = zeros([size(alpha) numcores]);

gKS = zeros([size(S) numcores]);
gKV = zeros([size(V) numcores]);
gKA = zeros([size(alpha) numcores]);

normS = sqrt(sum(S.^2,2));
directions = S./repmat(normS,1,3);

%% Parallely computing gradients

%h = tic;
localParams = params;
parfor c = 1:numcores
    [gKS(:,:,c),gKV(:,:,c),gKA(:,:,c),gOS(:,:,c),gOV(:,:,c),gOA(:,:,c),cO(:,:,c),...
        gSS(:,:,c),gSV(:,:,c),gSA(:,:,c),gPS(:,:,c),gPV(:,:,c),gPA(:,:,c)]...
        =computeGrads(S,V,alpha,stateFiles,lambda,shapePriorInstance,c,numcores,localParams);
end

gradOcclusionS = sum(gOS,3);
gradOcclusionV = sum(gOV,3);
gradOcclusionAlpha = sum(gOA,3);
occlusionCount = sum(cO,3);

gradSilS = sum(gSS,3);
gradSilV = sum(gSV,3);
gradSilAlpha = sum(gSA,3);

gradShapePriorS = sum(gPS,3);
gradShapePriorV = sum(gPV,3);
gradShapePriorAlpha = sum(gPA,3);

gradKeypointS = sum(gKS,3);
gradKeypointV = sum(gKV,3);
gradKeypointAlpha = sum(gKA,3);

%% Computing soft occlusion grad for the shape
gradOcclusionS = repmat(double((occlusionCount/numimages-0.02)>0),1,3).*gradOcclusionS; %hacking here

%% Computing gradients from priors
%h = tic;
gradPriorS = lambda(3)*shapePrior(S);
[gradPriorV,deformationPriorGradAlpha] = deformationPrior(V,alpha);
gradPriorV = lambda(4)*gradPriorV;
deformationPriorGradAlpha = lambda(4)*deformationPriorGradAlpha;
%fprintf('Prior computation: %.3fs\n',toc(h));


%% Display all gradients
fprintf('%d\t%3.3f\t%3.3f\t%3.3f\t%3.3f\t%3.3f\t%3.3f\t',...
iter, mean(sqrt(sum(mean(gKS,3).^2,2))),mean(sqrt(sum(mean(gOS,3).^2,2)))...
    ,mean(sqrt(sum(mean(gSS,3).^2,2))),mean(sqrt(sum(mean(gPS,3).^2,2))),...
    mean(sqrt(sum(gradPriorS.^2,2))),mean(sqrt(sum(gradPriorV.^2,2))));

%% Computing overall change in shape
gradS = gradICPS + gradOcclusionS + gradPriorS + gradSilS + gradShapePriorS + gradKeypointS;
gradV = gradICPV + gradOcclusionV + gradPriorV + gradSilV + gradShapePriorV + gradKeypointV;
gradAlpha = gradICPAlpha + gradOcclusionAlpha + deformationPriorGradAlpha + gradSilAlpha...
    + gradShapePriorAlpha + gradKeypointAlpha;

%% Computing grad along radial direction to preserve mesh
if(params.opt.spherical)
    projections = sum(gradS.*directions,2);
    gradS = directions.*repmat(projections,1,3);
    for k=1:K
        deformation = reshape(gradV(:,k),numpoints,3);
        projections = sum(deformation.*directions,2);
        deformation = directions.*repmat(projections,1,3);
        gradV(:,k)=deformation(:);
    end
end

end
