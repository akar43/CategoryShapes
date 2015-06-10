function [] = computeMeshesFromStates(class,jobID)
%COMPUTEMESHES Summary of this function goes here
%   Detailed explanation goes here
globals;
inferredShapesOptDir = jobDirs(class,jobID,'inferredShape');
meshDir = jobDirs(class,jobID,'mesh');
mkdirOptional(meshDir);

fnames = getFileNamesFromDirectory(inferredShapesOptDir,'types',{'.mat'});
fnames = removeFlipNames(fnames);

p =  TimedProgressBar( length(fnames), 30, ...
    'Computing Meshes: Remaining ', ', Completed ', 'Meshes Computed in: ' );

parfor i=1:length(fnames)
    state = load(fullfile(inferredShapesOptDir,fnames{i}));
    meshFile = fullfile(meshDir,fnames{i});
    if(exist(meshFile,'file'))
        continue;
    end
    fv = state2mesh(state.state);
    %fv = state2meshIso(state.state);
    savefunc(meshFile,fv.vertices,fv.faces);
    p.progress;
end
p.stop;
end

function savefunc(file,vertices,faces)
    save(file,'vertices','faces');
end
