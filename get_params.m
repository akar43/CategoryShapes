function params = get_params(paramStruct)
%Set up parameter structure for the model

%% If global parameters exist return
if(nargin<1)
    paramStruct = {};
end
globals
if(exist('params','var'))
    if(isfield(params,'nrsfm') && isfield(params,'opt') && isfield(params,'vis'))
        params = params;
        return
    end
end

%% NRSFM Parameters
nrsfm = struct;
nrsfm.minKps = 5; %For PASCAL
nrsfm.bboxthresh = 0.01; %For PASCAL
nrsfm.norm_dim = 10;
nrsfm.max_em_iter = 200;
nrsfm.tol = 1e-7;
nrsfm.nBasis = 4;
nrsfm.test_em_iters = 200;
nrsfm.debug = 0;
nrsfm.debugInterval = 50;
nrsfm.occ_lambda = 1;
nrsfm.flip = 1;

%% BASIS SHAPE MODEL PARAMETERS
opt = struct;
opt.numpoints = 5000;
opt.numbasis = 4;
opt.trainIters = 500;
opt.testIters = 500;
% Max allowed change in one iteration. Limits for (S,V,alpha) respectively
opt.maxDelta = [0.1 0.1 0.1];


opt.trainStepSize = 1e-3; %recommended 1e-3
opt.testStepSize = 1e-5; %recommended 1e-5

% lambda(1) is penalty for occlusion violation : recommended 2
% lambda(2) is penalty for silhouette covergae : recommended 2
% lambda(3) is penalty for mean shape smoothness : recommended 200
% lambda(4) is penalty for deformation L2 regularization and smoothness : recommended 0.2
% lambda(5) is penalty for instances shape : recommended 0.2
% lambda(6) is penalty for keypoint correspondences : recommended 5

opt.lambda = [2 2 200 0.2 0.2 5];
opt.testlambda = opt.lambda;
opt.normalizeByViews = 0;
opt.truncatedLoss = 0;
% whether you want to contrain points to move radially only during optimization.
% Using 1 helps for convex shapes
opt.spherical = 0;
opt.normalThresh = 0.9;
opt.numRegions = 6;
opt.kpNeighbours = 10;
% Use relaxed initilization
% add a combination of 'scale' or 'translation' or 'mask' or 'rotation' here
opt.relaxInit = {'scale','translation','rotation','kps'};
opt.relaxInit = {};
if(ismember('kps',opt.relaxInit'))
    opt.relaxInit = unique(horzcat(opt.relaxInit,{'scale','translation','rotation'}));
end
% Optimize the following - things in relaxInit have to appear below
% add a combination of 'scale' or 'translation' or 'mask' or 'rotation' here
opt.relaxOpt = unique(horzcat(opt.relaxInit,{'scale','translation','rotation','kps'}));
opt.rotationPredNum = 1;


%% VISUAL HULL INITIALIZATION
vis = struct;
vis.numRotClusters = 6; % Number of rotation clusters. Note that final TSDF importance weights while learning will sum up to numRotClusters
vis.voxelsFrom = [-10 -10 -10];vis.voxelsTo = [10 10 10];
vis.voxelsSteps = 0.2; % defines the voxel range and density
vis.minTSDF = -0.1;vis.maxTSDF = Inf; % thresholds for TSDF calcluations
vis.minPointsInMesh = 1000;
vis.numFacesInMesh = [3000,3000,NaN,2500,NaN,2500,2500,NaN,4000,NaN,...
    NaN,NaN,NaN,3500,NaN,NaN,NaN,2000,2500,1500];

%% SIRFS
sirfs = struct;

%% Returning Params
global params
params.nrsfm = nrsfm;
params.vis = vis;
params.opt = opt;
params.sirfs = sirfs;

for i=1:2:length(paramStruct)
    cmd = sprintf('params.%s = %s;',paramStruct{i},paramStruct{i+1});
    eval(cmd);
end


