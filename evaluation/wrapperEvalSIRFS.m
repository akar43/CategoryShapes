function dmapErrors = wrapperEvalSIRFS(classes)
    globals
    dmapErrors = cell(length(classes),1);
    
    map = load(fullfile(cachedir,'test_sets.mat'));
    map = map.map; map = map(~cellfun(@isempty,map));
    map = cellfun(@(x)(strcat(x,'.mat')),map,'UniformOutput',false);
    map = map(:);

    for ii=1:length(classes)
        dmapDir = fullfile(cachedir,classes{ii},'sirfsDir');
        gtDmapDir = fullfile(cachedir,classes{ii},'gtDepthMap');
        evalFileName = fullfile(cachedir,classes{ii},'evalStructSIRFS.mat');
        disp(classes{ii});
        if(exist(evalFileName,'file'))
            tmp = load(evalFileName);
            idx = ismember(tmp.fnames(:),map);
            dmapErrors{ii} = tmp.dmapErrors(idx);
            continue;
        end
        dmapErrors{ii} = evalSIRFS(dmapDir,gtDmapDir,evalFileName);
        disp(size(dmapErrors{ii},1));
    end
    fprintf('Class\t\tDepth Correlation (Mean)\n');
    for ii=1:length(classes)
        fprintf('%s\t\t%1.3f\n',classes{ii},mean(dmapErrors{ii}(~isnan(dmapErrors{ii}))));
    end

    fprintf('Class\t\tDepth Correlation (Median)\n');
    for ii=1:length(classes)
        fprintf('%s\t\t%1.3f\n',classes{ii},median(dmapErrors{ii}(~isnan(dmapErrors{ii})))*100);
    end

end

function dmapErrors = evalSIRFS(dmapDir,gtDmapDir,evalFileName)
    globals;
    fnames = getFileNamesFromDirectory(dmapDir,'types',{'.mat'});
    disp('Depth map evaluation');
    dmapErrors = zeros(length(fnames),1);
    p =  TimedProgressBar( length(fnames), round(length(fnames)/4), ...
    'Depth Map Errors: Remaining ', ', Completed ', 'Total Time: ' );

    parfor i=1:length(fnames)
        GtFile = fullfile(gtDmapDir,fnames{i});
        dmapFile = fullfile(dmapDir,fnames{i});
        try
            gtdmap = load(GtFile,'dmap');gtdmap = gtdmap.dmap;
        catch
            dmapErrors(i) = nan;
            continue;
        end
        dmap = load(dmapFile);
        mask = dmap.state.mask; dmap = dmap.state.dmap;
        %dmapErrors(i) = dmapMetric(dmap,gtdmap,mask);
        dmapErrors(i) = dmapMetricZMAE(dmap,gtdmap,mask);
        p.progress;
    end
    p.stop;
    save(evalFileName,'dmapErrors','fnames');
end
