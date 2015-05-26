function [jobID] = mainTest(class,trainExpId,testExpId,paramStruct)

if(nargin<4)
    paramStruct= {};
end

startup;
globals;
jobID = strcat('Test',trainExpId, testExpId);

%% Load parameters from trained model

% Load trained model
shapeModelOptFile = fullfile(cachedir,class,sprintf('shapeModelOpt%s.mat',trainExpId));
if(~exist(shapeModelOptFile,'file'))
    error('Trained Basis Shape Model not found at %s',shapeModelOptFile);
end
load(shapeModelOptFile);

% Setup params
clearvars -global params
global params;
params = shapeModelOpt.params;
for i=1:2:length(paramStruct)
    cmd = sprintf('params.%s = %s;',paramStruct{i},paramStruct{i+1});
    eval(cmd);
end

%% Reading test data for NRSFM
data = prepPascalData(class);

%% Run NRSFM and cache
nrsfmTestModel = runTestNRSFM(data,class);

%% Fit basis shapes to test instances
testBasisShapes(shapeModelOpt,nrsfmTestModel,jobID);

%% Compute meshes from inferred states
computeMeshesFromStates(class, jobID);

%% Compute depth maps from meshes
%getDepthMapsFromMeshes(class,jobID)

%% Compute SIRFS on top of above depth maps (NOTE: Takes a long time!)
%shapeSIRFS(class,jobID);

fprintf('\nJobID = %s\n', jobID);
fprintf('\nTrainID = %s\n', trainExpId);
end
