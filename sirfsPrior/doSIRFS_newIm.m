function sirfsdmap = doSIRFS_newIm(state,depthIm)
sigma = 3; % Controls the "bandwidth" of the input depth (the standard deviation of a Gaussian at which point the signal becomes reliable)
    mult = 5; % Controls the importance of the input depth (the multiplier on the loss)
    niters = 500;
    depthIm(isinf(depthIm)) = nan;
    depthIm = -depthIm;
    input_image = im2double(state.im);
    input_image(input_image<1/255) = 1/255;
    sirfsdmap = SIRFS(input_image, (state.mask), depthIm, ...
        ['params.DO_DISPLAY = 0; params.N_ITERS_OPTIMIZE = ' num2str(niters) ';params.USE_INIT_Z = true; params.INIT_Z_SIGMA = ',...
        num2str(sigma), ';params.multipliers.height.init = { ', num2str(mult), ' };']);
    sirfsdmap.mask = state.mask;
    sirfsdmap.im = input_image;
end