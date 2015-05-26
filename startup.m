% Startup script. Initialize all globals and add paths

global BASE_DIR
global PASCAL_DIR
global cachedir
global datadir
global PASCAL3Ddir

currDir = pwd;
BASE_DIR = [currDir '/'];
cachedir  = fullfile(currDir,'cache');
datadir   = fullfile(currDir,'data');
PASCAL_DIR = fullfile(currDir,'data','VOCdevkit/VOC2012/JPEGImages/');
PASCAL3Ddir = fullfile(currDir,'data','PASCAL3D+_release1.0/');

folders = {'main','sirfsPrior/','nrsfm/','evaluation/'...
    'visualize/','basisShapes/','utils/', 'external/SIRFS'};
for i=1:length(folders)
    addpath(genpath(folders{i}));
end
mkdirOptional(cachedir);
clear i;
clear currDir;
clear folders;
% Change vlfeat path if you already have it somewhere
run('./external/vlfeat-0.9.20/toolbox/vl_setup.m');
