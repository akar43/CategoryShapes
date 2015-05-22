function test_model = runTestNRSFM(data,class)

% Run and cache NRSFM. Load cached NRSFM model if available
globals;

% Path to cached NRSFM model
shapeModelNRSFMFile = fullfile(cachedir,class,'shapeModelNRSFM.mat');

fprintf('\n%%%%%%%%%%%% NRSFM %%%%%%%%%%%%\n');

if(~exist(shapeModelNRSFMFile,'file'))
    error('Trained NRSFM model not found! Run training first');
end

models = load(shapeModelNRSFMFile);

%% Run NRSFM if cached model not found
if(isfield(models,'test_model'))
    fprintf('Loading cached NRSFM model from \n%s\n',shapeModelNRSFMFile);
    test_model = models.test_model;
else    
    train_model = models.train_model;
    
    % Test model
    fprintf('Test Non Rigid SFM model \n');    
    test_model = testNRSFM(data,train_model);
    
    % Caching trained NRSFM model
    fprintf('Caching NRSFM model in \n%s\n',shapeModelNRSFMFile);
    save(shapeModelNRSFMFile,'train_model','test_model');
end

end