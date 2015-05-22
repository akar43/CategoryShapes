function [train_set,test_set] = prep_data(data,train_ratio,flip)
% Function to take data and normalize keypoints, filtered instances and
% generate train/test split (random).

% INPUT:
% data: Struct array of pascal instances with following fields
%   voc_image_id: Image ID in pascal
%   voc_red_id: Record id in pascal
%   pascal_bbox/bbox: Bounding box in [x,y,w,h] (Use bbox)
%   kps: Keypoints in [Kx2] matrix
%   part_names: Names of keypoints (Kx1) cell
%   poly_x and poly_y: Contour polygon
%   params: Filtering parameters
%    minKps = Instances with > minKps visible keypoints are kept
%    bboxthresh = Filter instances with bbox size less than this threshold
%                 (ratio with image size)
%    maxbboxdim = Resize bounding boxes so that maximum dimension is
%                 maxbboxdim
%    train_ratio= Ratio training set size to full set size

% OUTPUT:
% train/test_set: Pascal structure filtered by number of visible keypoints
%                 and bboxsize with following fields
%   points: 2NxK matrix with 2D keypoints (Location of instance i = points[i,nTrain+i]))
%   ids: Index numbers from original data structure (because it permutes)
%   voc_image_id, voc_rec_id: Same as above
%   bbox: Nx4 bounding box matrix
%   labels: Part names
%   poly_x,poly_y: Same as above

    globals;
    params = get_params();
    if(nargin<3)
        flip = 0;
    end
    kps  = cat(3,data(:).kps);
    allbbox = vertcat(data(:).pascal_bbox);
    imsizes = vertcat(data(:).imsize);
    image_ids = {data(:).voc_image_id}';
    rec_ids = [data(:).voc_rec_id]';
    try
        poly_x = {data(:).poly_x}';
        poly_y = {data(:).poly_y}';
    catch
        masks = {data(:).mask}';
    end

    if(isfield(data(1),'subtype'))
        subtype = [data(:).subtype]';
    end

    if(isfield(data(1),'rotP3d'))
        rotP3d =  {data(:).rotP3d}';
    else
        rotP3d = {};
    end

    if(isfield(data(1),'rotationPred'))
        rotationPred = {data(:).rotationPred}';
    end

    if(isfield(data(1),'subtypePred'))
        subtypePred = vertcat(data(:).subtypePred);
    end
    if(flip)
        flips = vertcat(data(:).flip);
    end

    % Standardize part_names for '_' (Deva cars)
    for i=1:length(data(1).part_names)
        part_names{i} = strrep(data(1).part_names{i},' ','_');
    end

    % Parameters for train/test set extraction
    minKps = params.nrsfm.minKps;
    bboxthresh = params.nrsfm.bboxthresh;
    maxbboxdim = params.nrsfm.norm_dim;
    points = normkps(kps,allbbox,maxbboxdim);

    % Delete instances with less than minKps visible keypoints
    points = [squeeze(points(:,1,:))';squeeze(points(:,2,:))'];
    nNans = sum(isnan(points(1:end/2,:)),2);
    inds2delnans = nNans>(size(points,2)-minKps);

    % Delete small bounding boxes
    inds2delbbox = del_bboxes(allbbox,imsizes,bboxthresh);
    inds2del = inds2delnans | inds2delbbox;
    points([inds2del;inds2del],:)=[];

    % Generate random permutation of valid instances
    % select train/test set
    nImages = size(points,1)/2;

    nTrain  = ceil(nImages*train_ratio);
    if(~flip)
        perm = randperm(size(points,1)/2);
    else
        perm = randperm(size(points,1)/4);
        perm = [perm (perm+nImages/2)];
    end
    perm = round(perm);
    permset = [points(perm,:);points(nImages+perm,:)];
    validInds = find(inds2del==0);
    validInds = validInds(perm);

    %% Set up train_set structure
    train_set.points = permset([1:nTrain nImages+1:nImages+nTrain],:);
    train_set.ids = validInds(1:nTrain);
    train_set.voc_image_id = image_ids(train_set.ids);
    train_set.voc_rec_id  = rec_ids(train_set.ids);
    train_set.bbox = allbbox(train_set.ids,:);
    train_set.labels = part_names;
    try
        train_set.poly_x = poly_x(train_set.ids);
        train_set.poly_y = poly_y(train_set.ids);
    catch
        train_set.mask = masks(train_set.ids);
    end
    train_set.imsize = imsizes(train_set.ids,:);
    if(flip)
        train_set.flip = flips(train_set.ids);
    end

    if(isfield(data(1),'rotationPred'))
        train_set.rotationPred = rotationPred(train_set.ids);
    end
    if(isfield(data(1),'subtypePred'))
        train_set.subtypePred = subtypePred(train_set.ids);
    end

    if(isfield(data(1),'subtype'))
        train_set.subtype = subtype(train_set.ids);
    end

    if(isfield(data(1),'rotP3d'))
        train_set.rotP3d = rotP3d(train_set.ids);
    else
        train_set.rotP3d = rotP3d;
    end

    %% Set up test_set structure
    test_set.points  = permset([nTrain+1:nImages nImages+nTrain+1:end],:);
    test_set.ids  = validInds(nTrain+1:end);
    test_set.voc_image_id = image_ids(test_set.ids);
    test_set.voc_rec_id  = rec_ids(test_set.ids);
    test_set.bbox = allbbox(test_set.ids,:);
    test_set.labels = part_names;
    try
        test_set.poly_x = poly_x(test_set.ids);
        test_set.poly_y = poly_y(test_set.ids);
    catch
        test_set.mask = masks(test_set.ids);
    end
    test_set.imsize = imsizes(test_set.ids,:);
    if(flip)
        test_set.flip = flips(test_set.ids);
    end

    if(isfield(data(1),'rotationPred'))
        test_set.rotationPred = rotationPred(test_set.ids);
    end
    if(isfield(data(1),'subtypePred'))
        test_set.subtypePred = subtypePred(test_set.ids);
    end

    if(isfield(data(1),'subtype'))
        test_set.subtype = subtype(test_set.ids);
    end

    if(isfield(data(1),'rotP3d'))
        test_set.rotP3d = rotP3d(test_set.ids);
    else
        test_set.rotP3d = rotP3d;
    end

end
