function test_model = merge_model_arr(test_model_arr)
    test_model.class = test_model_arr(1).class;
    test_model.S_bar = test_model_arr(1).S_bar;
    test_model.defBasis = test_model_arr(1).defBasis;
    test_model.part_names = test_model_arr(1).part_names;
    test_model.sigma_sq = test_model_arr(1).sigma_sq;
    test_model.points3 = vertcat(test_model_arr(:).points3);
    test_model.points3 = [test_model.points3(1:3:end,:);test_model.points3(2:3:end,:);...
        test_model.points3(3:3:end,:)];
    test_model.rots = [test_model_arr(:).rots];
    test_model.trs = vertcat(test_model_arr(:).trs);
    test_model.def_weights = vertcat(test_model_arr(:).def_weights);
    test_model.voc_image_id = [test_model_arr(:).voc_image_id]';
    if(isfield(test_model_arr(1),'voc_rec_id'))
        test_model.voc_rec_id = vertcat(test_model_arr(:).voc_rec_id);
    end
    test_model.bbox = vertcat(test_model_arr(:).bbox);
    test_model.points2 = vertcat(test_model_arr(:).points2);
    test_model.points2 = [test_model.points2(1:2:end,:);test_model.points2(2:2:end,:)];
    test_model.params = test_model_arr(1).params;
    test_model.c = vertcat(test_model_arr(:).c);
    if(isfield(test_model_arr(1),'flip'))
        test_model.flip = vertcat(test_model_arr(:).flip);
    end
    
    try
        for i=1:length(test_model_arr)
            test_model.seg.poly_x{i} = test_model_arr(i).seg.poly_x{1};
            test_model.seg.poly_y{i} = test_model_arr(i).seg.poly_y{1};
        end
        test_model.seg.poly_x = test_model.seg.poly_x';
        test_model.seg.poly_y = test_model.seg.poly_y';
    catch
        test_model.seg = {test_model_arr(:).seg}';
    end
end
