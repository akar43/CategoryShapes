function [] = getDepthMapsFromMeshes(class,jobID)
%GETDEPTHIMAGE Summary of this function goes here
%   Detailed explanation goes here
globals
statesDir = jobDirs(class,jobID,'state');
meshDir = jobDirs(class,jobID,'mesh');
depthMapsDir = jobDirs(class,jobID,'dmap');
fnames = getFileNamesFromDirectory(meshDir,'types',{'.mat'});
mkdirOptional(depthMapsDir);

%% Loading precomputed shape
p =  TimedProgressBar( length(fnames), 30, ...
    'Generating Depth Maps: Remaining ', ', Completed ', 'Depth Map Time: ' );
parfor i=1:length(fnames)
%for i=1:length(fnames)
    meshFile = fullfile(meshDir,fnames{i});
    dmapFile = fullfile(depthMapsDir,fnames{i});
    if(exist(dmapFile,'file'))
        continue;
    end
    stateFile = fullfile(statesDir,fnames{i});
    state = load(stateFile);state=state.state;
    mesh = load(meshFile);
    mesh = reducepatch(mesh,2000);
    depthIm = meshToDepth(mesh.vertices,mesh.faces,size(state.mask));
    dmap = depthIm;
    dmap(isinf(dmap)) = nan;
    dmap(~state.mask) = nan;
    savefunc(dmapFile,dmap);
    p.progress;
end
p.stop;
end

function savefunc(file,dmap)
    save(file,'dmap');
end

