function [model] = em_single_instance(model_3d,test, instance, max_em_iter)
%EM_SINGLE_INSTANCE Summary of this function goes here
%   Detailed explanation goes here
params = get_params();

%% Changing test data for just the particular instance
N = size(test.points,1)/2;
testInstance.points = test.points([instance N+instance],:);
testInstance.voc_image_id{1} = test.voc_image_id{instance};
testInstance.labels = test.labels;
testInstance.bbox = test.bbox(instance,:);
testInstance.imsize = test.imsize(instance,:);
try
    testInstance.poly_x = test.poly_x(instance);
    testInstance.poly_y = test.poly_y(instance);
catch
    testInstance.mask = test.mask{instance};
end
testInstance.bbox   = test.bbox(instance,:);
if(isfield(test,'voc_rec_id'))
    testInstance.voc_rec_id(1) = test.voc_rec_id(instance);
end
if(isfield(test,'flip'))
    testInstance.flip(1) = test.flip(instance);
end

%% Obtaining the model
model = test_nrsfm(testInstance,model_3d,max_em_iter);

end

