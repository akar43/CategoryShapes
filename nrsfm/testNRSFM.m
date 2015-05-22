function test_model = testNRSFM(data, train_model)

globals;
params = get_params();

fprintf('Testing NRSfM model\n');

% Generate test set
[~,test] = prep_data(data.test,0,0);

% Take full train labels and test on test set. Just reorder.
test = normalize_test(test, train_model);
nTest = size(test.points,1)/2;
nTestIters = params.nrsfm.test_em_iters;

% Fit NRSFM parameters parallely to instances
p =  TimedProgressBar( nTest, 30, ...
'Testing NRSfM ', ', completed ', 'Testing NRSfM concluded in ' );
parfor i=1:nTest
    test_model_arr(i) = em_single_instance(train_model,test,i,nTestIters);
    p.progress();
end
p.stop();

% Merge test models into a single test_model
test_model = merge_model_arr(test_model_arr);
if(isfield(test,'subtype'))
    test_model.subtype = test.subtype;
end
if(isfield(test,'rotP3d'))
    test_model.rotP3d = test.rotP3d;
end
if(isfield(test,'rotationPred'))
    test_model.rotationPred = test.rotationPred;
end
if(isfield(test,'subtypePred'))
    test_model.subtypePred = test.subtypePred;
end

end
