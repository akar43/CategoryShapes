function [] = shapeSIRFS(class,jobID)
%GETDEPTHIMAGE Summary of this function goes here
%   Detailed explanation goes here

statesDir = jobDirs(class,jobID,'state');
sirfsstatedir = jobDirs(class,jobID,'sirfs');
dmapDir = jobDirs(class,jobID,'dmap');
mkdirOptional(sirfsstatedir);
fnames = getFileNamesFromDirectory(dmapDir,'types',{'.mat'});

fprintf('\n%%%%%%%%%%%% SIRFS %%%%%%%%%%%%\n');
%% Loading precomputed shape
for i=1:length(fnames)
%for i=1:length(fnames)    
    sirfsdmapFile = fullfile(sirfsstatedir,fnames{i});
    if(exist(sirfsdmapFile,'file'))
        continue;
    end
    stateFile = fullfile(statesDir,fnames{i});
    state = load(stateFile);state=state.state;
    dmapFile = fullfile(dmapDir,fnames{i});
    dmap = load(dmapFile); dmap = dmap.dmap;
    sirfsstate = getsirfsstate(state,dmap);   
    savefunc(sirfsdmapFile,sirfsstate);
    %vis_PSIRFS(sirfsstate); pause    
end
end

function savefunc(file,state)
    save(file,'state');
end

function sirfsstate = getsirfsstate(state,depthIm)
    sigma = 3; % Controls the "bandwidth" of the input depth (the standard deviation of a Gaussian at which point the signal becomes reliable)
    mult = 5; % Controls the importance of the input depth (the multiplier on the loss)
    niters = 200;
    depthIm(isinf(depthIm)) = nan;
    depthIm = -depthIm;
    input_image = im2double(state.im);
    input_image(input_image<1/255) = 1/255;
    dmapMask = ~isinf(depthIm) & ~isnan(depthIm);
    %imshow(color_seg(dmapMask,state.im));
    sirfsstate = SIRFS(input_image, dmapMask, depthIm, ...
        ['params.DO_DISPLAY = 0; params.N_ITERS_OPTIMIZE = ' num2str(niters) ';params.USE_INIT_Z = true; params.INIT_Z_SIGMA = ',...
        num2str(sigma), ';params.multipliers.height.init = { ', num2str(mult), ' };']);
%     sirfsstate = SIRFS(input_image, (state.mask), [], ...
%         ['params.DO_DISPLAY = 0; params.N_ITERS_OPTIMIZE = ' num2str(niters) ';']);
    sirfsstate.mask = dmapMask;
    sirfsstate.im = input_image;
    sirfsstate.dmap = sirfsstate.height;
end
