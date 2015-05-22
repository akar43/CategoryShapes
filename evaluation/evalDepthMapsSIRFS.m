function dmapErrors = evalDepthMapsSIRFS(class,jobID,metric)
    globals;
    if(nargin<3)
        metric = 'zmae';
    end
    dmapDir = jobDirs(class,jobID,'sirfs');
    evalFileName = jobDirs(class,jobID,'evalDepth');
    statesDir = jobDirs(class, jobID, 'state');
    gtDmapDir = fullfile(cachedir,class,'gtDepthMap');
    
    switch metric
        case 'corr'
            disp('Using Depth Correlation');
        case 'zmae'
            disp('Using Z-MAE');
        case 'absrel'
            disp('Using absolute relative error');
    end
    
    fnames = getFileNamesFromDirectory(dmapDir,'types',{'.mat'});
    fnames = removeFlipNames(fnames);
        
    disp('Depth map evaluation');
    
    dmapErrors = zeros(length(fnames),1);
    p =  TimedProgressBar( length(fnames), 30, ...
    'Depth Map Errors: Remaining ', ', Completed ', 'Depth Map evaluation Time: ' );

    for i=1:length(fnames)
        GtFile = fullfile(gtDmapDir,fnames{i});
        dmapFile = fullfile(dmapDir,fnames{i});
        state = load(fullfile(statesDir,fnames{i}),'state');
        state = state.state;        
        if(~exist(GtFile,'file'))
            warning('Gt depth map not found: %s\n',GtFile);
            dmapErrors(i) = nan;
            continue;
        end
        gtdmap = load(GtFile,'dmap');
        gtdmap = gtdmap.dmap;
        sirfsstate = load(dmapFile);
        dmap = -sirfsstate.state.height;        
        switch metric
            case 'corr'
                dmapErrors(i) = dmapMetricCorr(dmap,gtdmap,state.gtmask);        
            case 'zmae'
                dmapErrors(i) = dmapMetricZMAE(dmap,gtdmap,state.gtmask);
            case 'absrel'
                dmapErrors(i) = dmapMetricRel(dmap,gtdmap,state.gtmask);
        end
        
        % Visualization
        if 1            
            gtdmap(isinf(gtdmap)) = nan;
            dmap(isinf(dmap)) = nan;
            gtdmap(~state.mask) = nan;
            dmap(~state.mask) = nan;
            subplot(1,2,1);                        
            out = visualizeDEM(dmap);
            imagesc(imcrop(out,state.bbox));axis equal off;
            title(sprintf('Opt Depth Map - %.4f',dmapErrors(i)));
            subplot(1,2,2)
            out = visualizeDEM(gtdmap);
            imagesc(imcrop(out,state.bbox)); axis equal off;
            title('Gt Depth Map');
            pause;
            clf;
        end
        p.progress;
    end
    p.stop;
    save(evalFileName,'dmapErrors','fnames');
end
