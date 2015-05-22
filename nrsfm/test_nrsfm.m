function test_model = test_nrsfm(test,model_3d,test_em_iters)
% Use a trained shape model to predict keypoints on new instances
% given the bounding box and visible keypoints
% NOTE: The keypoints are already scaled to make all bboxes the same size
    params = get_params();
    P = test.points;
    MD = isnan(P(1:end/2,:));
    P(isnan(P)) = 0;
    tol = params.nrsfm.tol;
    max_em_iter = test_em_iters;
    try
        seg.poly_x = test.poly_x;
        seg.poly_y = test.poly_y;
    catch
        seg = test.mask;
    end
    % Do EM for inference with missing data
    [P3, RO, Tr, basis_coeffs,c] = em_sfm_known_shape(P, MD, model_3d.S_bar,...
        model_3d.defBasis, model_3d.sigma_sq, seg, test.imsize, test.bbox, tol, max_em_iter);

    %Set up test_model

    test_model.class = model_3d.class;
    test_model.S_bar = model_3d.S_bar;
    test_model.defBasis = model_3d.defBasis;
    test_model.part_names = model_3d.part_names;
    test_model.sigma_sq = model_3d.sigma_sq;
    test_model.points3 = P3;
    test_model.rots = RO;
    test_model.trs = Tr;
    test_model.def_weights = basis_coeffs;
    test_model.voc_image_id = test.voc_image_id;
    if(isfield(test,'voc_rec_id'))
        test_model.voc_rec_id = test.voc_rec_id;
    end
    if(isfield(test,'flip'))
        test_model.flip = test.flip;
    end
    test_model.bbox = test.bbox;
    test_model.points2 = test.points;
    test_model.params = params;
    test_model.c = c;
    test_model.seg = seg;
end
