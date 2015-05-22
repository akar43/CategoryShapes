function meshErrors = evalMeshes(class,jobID)
% Evaluate meshes with Hausdorff distance

globals;
meshDir = jobDirs(class,jobID,'mesh');
inferredShapeDir = jobDirs(class,jobID,'inferredShape');    
evalFileName = jobDirs(class,jobID,'evalMesh');

if(~exist(meshDir,'dir'))
    error('Meshes not found in %s\n. Compute them first!',meshDir);
end

fnames = getFileNamesFromDirectory(meshDir,'types',{'.mat'});
fnames = removeFlipNames(fnames);
p3dDir = fullfile(PASCAL3Ddir,sprintf('Annotations/%s_pascal',class));        

% Load the CAD models
p3dCAD = load(fullfile(PASCAL3Ddir,sprintf('CAD/%s',class)));
p3dCAD = p3dCAD.(class);

disp('Mesh Evaluation');
meshErrors = zeros(length(fnames),1);
try
    load(evalFileName);
    warning('Eval file found at %s\n',evalFileName);
catch        
    meshErrors = zeros(length(fnames),1);
end

p =  TimedProgressBar( length(fnames), 30, ...
'Computing mesh errors: Remaining ', ', Completed ', 'Mesh Evaluation Time: ' );
parfor i=1:length(fnames)        
    meshFile = fullfile(meshDir,fnames{i});
    fvPred = load(meshFile);
    voc_id = fnames{i}(1:end-4);
    toks =  regexp(voc_id,'[_.]','split');
    im_id = [toks{1} '_' toks{2}];
    rec_id = str2double(toks{3});

    if(~exist(fullfile(p3dDir,[im_id '.mat']),'file'))
        warning('Pascal3D file not found!\n');
        meshErrors(i) = nan;
        continue;
    end        
    p3drec = load(fullfile(p3dDir,im_id));
    p3drec = p3drec.record.objects(rec_id);
    thisCAD = p3dCAD(p3drec.cad_index);
    xIm = projectp3d(thisCAD.vertices,p3drec);
    if(isempty(xIm))
        warning('Pascal3D file annotations missing!\n');
        meshErrors(i) = nan;
        continue;
    end

    % Load inferred state
    state = load(fullfile(inferredShapeDir,fnames{i}));
    state = state.state;

    % Transform point clouds back into canonical frame and size        
    gtPts = state.invtransform3d(xIm);
    predPts = state.invtransform3d(fvPred.vertices);

    % Translate to be 0 centered
    [rotmatGt,cornersGt] = minboundbox(gtPts(:,1),gtPts(:,2),gtPts(:,3),'v',1);
    [rotmatPred,cornersPred] = minboundbox(predPts(:,1),predPts(:,2),predPts(:,3),'v',1);        
    meanGt = mean(cornersGt); meanPred = mean(cornersPred);
    gtPtsTr = bsxfun(@minus,gtPts,meanGt);
    predPtsTr = bsxfun(@minus,predPts,meanPred);
    gtPtsRotTr = gtPtsTr;%*rotmatGt;
    predPtsRotTr = predPtsTr;%*rotmatPred;

    meshErrors(i) = HausdorffDist(gtPtsRotTr,predPtsRotTr,1);

    % Visualization
    if 0            
        subplot(121)            
        showMesh(struct('vertices',gtPtsTr,'faces',thisCAD.faces),[1 0 0]);
        hold on;
        cornersGt = bsxfun(@minus,cornersGt,meanGt);
        plotminbox(cornersGt);
        showMesh(struct('vertices',predPtsTr,'faces',fvPred.faces),[0 0 1]);
        hold on;
        cornersPred = bsxfun(@minus,cornersPred,meanPred);
        plotminbox(cornersPred);
        hold off;
        title('Before alignment');
        subplot(122)
        showMesh(struct('vertices',gtPtsRotTr,'faces',thisCAD.faces),[1 0 0]);
        hold on;
        showMesh(struct('vertices',predPtsRotTr,'faces',fvPred.faces),[0 0 1]);
        hold off;            
        title(['After Alignment. Error: ' num2str(meshErrors(i))]);
        %axis on; xlabel('x');ylabel('y');zlabel('z');
        %keyboard;
        pause; clf
    end
    p.progress;
end
p.stop;

save(evalFileName,'meshErrors','fnames');

end


