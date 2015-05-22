function model_3d = train_nrsfm(cls,train_set)
    globals;
    params = get_params();
    md = isnan(train_set.points(1:end/2,:));
    points = train_set.points;
    points_bak = points;
    points(isnan(points))=0;
    try
        seg.poly_x = train_set.poly_x;
        seg.poly_y = train_set.poly_y;
    catch
        seg = train_set.mask;
    end

    % Setup variables for converting to PASCAL 3D frame
    load(fullfile(datadir,'partNames',cls));
    load(fullfile(datadir,'voc_kp_metadata'));
    cInd = find(ismember(metadata.categories,cls));
    [~,I] = sort(metadata.kp_names{cInd});
    invI(I) = 1:numel(I);
    rightCoordSys = metadata.right_coordinate_sys{cInd};
    rightCoordSys(1:6) = invI(rightCoordSys(:));
    names = partNames(rightCoordSys);

    % Do non-rigid SFM
    [P3, S_bar, V, RO, Tr, Z, sigma_sq, ~, ~, ~, ~,c]...
      = em_sfm(points, md, params.nrsfm.nBasis, seg, train_set.imsize, train_set.bbox,...
      params.nrsfm.tol, params.nrsfm.max_em_iter,rightCoordSys,train_set.rotP3d);

    model_3d.class          = cls;
    model_3d.S_bar          = S_bar;
    model_3d.defBasis       = V;
    model_3d.part_names     = train_set.labels;
    model_3d.sigma_sq       = sigma_sq;
    model_3d.points3        = P3;
    model_3d.rots           = RO;
    model_3d.trs            = Tr;
    model_3d.def_weights    = Z;
    model_3d.voc_image_id   = train_set.voc_image_id;
    if(isfield(train_set,'voc_rec_id'))
        model_3d.voc_rec_id     = train_set.voc_rec_id;
    end
    model_3d.bbox           = train_set.bbox;
    model_3d.points2        = points_bak;
    model_3d.params         = params;
    model_3d.c              = c;
    model_3d.seg            = seg;
    if(isfield(train_set,'flip'))
        model_3d.flip = train_set.flip;
    end
    if(isfield(train_set,'subtype'))
        model_3d.subtype = train_set.subtype;
    end
    if(isfield(train_set,'rotP3d'))
        model_3d.rotP3d = train_set.rotP3d;
    end

end
