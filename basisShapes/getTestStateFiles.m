function [] = getTestStateFiles(model_3d,statesDir,relax,goodInds)

globals;
paramsLocal = params;
PASCAL_DIR_local = PASCAL_DIR;
cachedir_local = cachedir;
if(nargin<4)
    goodInds = true(length(model_3d.c),1);
end
parfor instance = 1:length(model_3d.c)
    state = struct;
    if(~goodInds(instance))
        continue;
    end
    %% Read image
    if(strcmp(model_3d.voc_image_id{instance}(end-2:end),'jpg')~=0)
        fname = [PASCAL_DIR_local model_3d.voc_image_id{instance}];
    else
        fname = [PASCAL_DIR_local model_3d.voc_image_id{instance} '.jpg'];
    end
    im = imread(fname);

    %% Flip handling and file names
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
        continue; %done want the to make state files for flipped test instances
        im(:,:,1) = fliplr(im(:,:,1));im(:,:,2) = fliplr(im(:,:,2));im(:,:,3) = fliplr(im(:,:,3));
        voc_id = ['flip_' voc_id];
    end

    %% bbox and bboxScale, bboxTr
    bbox = model_3d.bbox(instance,:); % Used this for bbox scaling!
    % Keep all the information in bbox while scaling
    bbox = [floor(bbox(1:2)) ceil(bbox(3:4))];
    sc = max(bbox(3),bbox(4))/model_3d.params.nrsfm.norm_dim;
    nImages = size(model_3d.points3,1)/3;
    tr = bbox(1,1:2)';

    %% Mask
    if(ismember('mask',relax))
        sdsthresh = 50;
        sdsdir = fullfile(cachedir_local,model_3d.class,['SDSmasks' num2str(sdsthresh)]);
        % [sdsbbox, bboxmask] = thisSDSMask(sdsdir,voc_id);
        % mask = zeros(size(im,1),size(im,2));
        % mask(sdsbbox(2):sdsbbox(4),sdsbbox(1):sdsbbox(3))= bboxmask;
        % mask = logical(mask);
        mask = logical(imread(fullfile(sdsdir, [voc_id '.png'])));
        segs = model_3d.seg;
        if(~iscell(segs))
            gtmask = roipoly(im,segs.poly_x{instance},segs.poly_y{instance});
        else
            gtmask = segs{instance};
        end
        state.mask = mask;
        state.gtmask = gtmask;
    else
        segs = model_3d.seg;
        if(~iscell(segs))
            mask = roipoly(im,segs.poly_x{instance},segs.poly_y{instance});
        else
            mask = segs{instance};
        end
        gtmask = mask;
        %mask = roipoly(im,segs.poly_x{instance}{1},segs.poly_y{instance}{1});
        state.mask = mask;
        state.gtmask = gtmask;
    end
    [~,occlusionIDX] = bwdist(state.mask);


    %% translation
    if(ismember('translation',relax))
        translation = bbox([1 2]) + bbox([3 4])/2;
        translation = translation';
    else
        vis_points = [model_3d.points3(instance,:);model_3d.points3(nImages+instance,:);...
            model_3d.points3(2*nImages+instance,:)];
        vis_points = sc*vis_points;
        vis_points(1:2,:) = vis_points(1:2,:)+repmat(tr,[1,size(model_3d.points3,2)]);
        translation = mean(vis_points(1:2,:),2);
    end

    %% scale
    if(model_3d.c(instance)<0 || sc<0)
        disp('Negative scale!');
        continue;
    end
    if(ismember('scale',relax))
        scale = sc;
    else
        scale = model_3d.c(instance)*sc;
    end

    %% keypoints
    if(ismember('kps',relax))
        kps = [];
    else
        vis_points = [model_3d.points3(instance,:);model_3d.points3(nImages+instance,:);...
        model_3d.points3(2*nImages+instance,:)];
        vis_points = sc*vis_points;
        vis_points(1:2,:) = vis_points(1:2,:)+repmat(tr,[1,size(model_3d.points3,2)]);
        kps = vis_points;
        translation = mean(vis_points(1:2,:),2);
    end
    %% rotation

    if(ismember('rotation',relax))
        rotation = model_3d.rotationPred{instance}{paramsLocal.opt.rotationPredNum};
    else
        rotation = model_3d.rots{instance};
        %rotationP3d = model_3d.rotP3d{instance};
        %rotation = model_3d.rotP3d{instance};
    end

    %% Setup state file output
    state.im= im;
    state.voc_id = voc_id;
    state.bbox = bbox;
    state.cameraRot = rotation;
    %state.cameraP3d = rotationP3d;

    state.cameraScale = scale;
    state.translation = translation;
    state.bdry = getBoundary(state.mask);
    state.occlusionIDX = occlusionIDX;
    state.kps = kps;
    state.transform3d = giveTransformFunc3d(state.cameraRot,state.cameraScale,state.translation);
    state.invtransform3d = giveInvTransformFunc3d(state.cameraRot,state.cameraScale,state.translation);
    savefunc(fullfile(statesDir, [voc_id '.mat']), state);

end

end

function savefunc(fname,state)
save(fname,'state');
end

function bdry = getBoundary(mask)
f = [0 1 0;1 0 1; 0 1 0];
[I,J] = find(mask.*(conv2(double(mask),f,'same')<4));
bdry = [J,I];
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

function [bbox, mask] = thisSDSMask(sdsdir,voc_id)
    sdsfile = fullfile(sdsdir,voc_id);
    sds = load(sdsfile);
    bbox = sds.bbox;
    mask = sds.mask;
end
