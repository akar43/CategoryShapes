function [] = getStateFiles(model_3d,statesDir,goodInds)

globals;
PASCAL_DIR = PASCAL_DIR;
if(nargin<3)
    goodInds = true(length(model_3d.c),1);
end
params = get_params();
viewClusters = cluster_views(model_3d,find(goodInds(:)),params.vis.numRotClusters,0);
%pBar =  TimedProgressBar( length(model_3d.c), 30, ...
%    'Generating state files ', ', completed ', 'Generated state files in ' );

parfor instance = 1:length(model_3d.c)

    if(~goodInds(instance))
        continue;
    end
    %% Read image
    if(strcmp(model_3d.voc_image_id{instance}(end-2:end),'jpg')~=0)
        fname = [PASCAL_DIR model_3d.voc_image_id{instance}];
    else
        fname = [PASCAL_DIR model_3d.voc_image_id{instance} '.jpg'];
    end
    im = imread(fname);

    %% Get Segmentation from pascal annotations
     %disp(['Instance ' num2str(instance)]);
     if(isfield(model_3d,'voc_rec_id'))
         voc_id = [model_3d.voc_image_id{instance} '_' num2str(model_3d.voc_rec_id(instance))];
     else
         voc_id = [model_3d.voc_image_id{instance} '_1'];
     end
    if(isfield(model_3d,'flip'))
        flip = model_3d.flip(instance);
    else
        flip = 0;
    end

    if(flip)
        im(:,:,1) = fliplr(im(:,:,1));im(:,:,2) = fliplr(im(:,:,2));im(:,:,3) = fliplr(im(:,:,3));
        voc_id = ['flip_' voc_id];
    end

    segs = model_3d.seg;
    if(iscell(segs))
        mask = segs{instance};               
    else
        mask = roipoly(im,segs.poly_x{instance},segs.poly_y{instance});       
    end
    
    [~,occlusionIDX] = bwdist(mask);
    %mask = roipoly(im,segs.poly_x{instance}{1},segs.poly_y{instance}{1});

    %% Prepare data for instance from model structure
    bbox = model_3d.bbox(instance,:); % Used this for bbox scaling!
    % Keep all the information in bbox while scaling
    bbox = [floor(bbox(1:2)) ceil(bbox(3:4))];
    sc = max(bbox(3),bbox(4))/model_3d.params.nrsfm.norm_dim;
    nImages = size(model_3d.points3,1)/3;
    tr = bbox(1,1:2)';
    vis_points = [model_3d.points3(instance,:);model_3d.points3(nImages+instance,:);...
        model_3d.points3(2*nImages+instance,:)];
    vis_points = sc*vis_points;
    vis_points(1:2,:) = vis_points(1:2,:)+repmat(tr,[1,size(model_3d.points3,2)]);
    %vis_points(3,:) = -vis_points(3,:);


    %% visualization

    %subplot(2,2,1), imagesc(im); rectangle('Position',bbox,'EdgeColor','r','LineWidth',1);axis equal;
    %hold on;plot(vis_points(1,:),vis_points(2,:),'r.','MarkerSize',20);
    %hold on; trimesh(f',vis_points(1,:),vis_points(2,:),'LineWidth',3);axis equal;
    %subplot(2,2,2), imagesc(dmap);colormap('jet');axis equal;
    %hold on; trimesh(f',vis_points(1,:),vis_points(2,:),'LineWidth',3);axis equal;
    %subplot(2,2,3), imagesc(mask);colormap('gray');axis equal;
    %subplot(2,2,4),trimesh(f,vis_points(1,:),vis_points(2,:));axis equal;
    %pause();close all;

    %% Setup state file output
    state=struct;
    %state.dmapCoarse = dmap;
    state.mask = mask;
    state.gtmask= mask;
    state.im=im;
    state.voc_id = voc_id;
    state.kps = vis_points;
    state.bbox = bbox;
    %state.cameraPos = cameraPos;
    %state.cameraF = cameraF;
    state.cameraRot = model_3d.rots{instance};
    state.cameraScale = model_3d.c(instance)*sc;
    state.def_weights = model_3d.def_weights(instance,:);
    state.translation = mean(state.kps(1:2,:),2);

    state.transform3d = giveTransformFunc3d(state.cameraRot,state.cameraScale,state.translation);
    state.invtransform3d = giveInvTransformFunc3d(state.cameraRot,state.cameraScale,state.translation);
    state.bdry = getBoundary(state.mask);
    state.occlusionIDX = occlusionIDX;
    state.viewClusters = viewClusters;
    state.globalID = instance;   
    savefunc(fullfile(statesDir, [voc_id '.mat']), state);
    %pBar.progress();
end
%pBar.stop();
end

function savefunc(fname,state)
save(fname,'state');
end

function tfun3d = giveTransformFunc3d(R,c,tr)

function S3d = tf(S)
S3d = c*R*S';
tr3 = [tr;zeros(1,size(tr,2))];
S3d = bsxfun(@plus,S3d,tr3);
S3d = S3d';
end

tfun3d = @tf;
end

function tfun3d = giveInvTransformFunc3d(R,c,tr)

function S3d = invtf(S)
tr3 = [tr' zeros(size(tr,2),1)];
S3d = bsxfun(@minus,S,tr3);
S3d = (S3d*R)/c;
end

tfun3d = @invtf;
end

function bdry = getBoundary(mask)
f = [0 1 0;1 0 1; 0 1 0];
[I,J] = find(mask.*(conv2(double(mask),f,'same')<4));
bdry = [J,I];
end
