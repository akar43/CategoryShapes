function train_model = runTrainNRSFM(data,class)

% Run and cache NRSFM. Load cached NRSFM model if available
globals;
params = get_params();

% Path to cached NRSFM model
shapeModelNRSFMFile = fullfile(cachedir,class,'shapeModelNRSFM.mat');

fprintf('\n%%%%%%%%%%%% NRSFM %%%%%%%%%%%%\n');

% Run NRSFM if cached model not found
if(exist(shapeModelNRSFMFile,'file'))
    fprintf('Loading cached NRSFM model from \n%s\n',shapeModelNRSFMFile);
    load(shapeModelNRSFMFile,'train_model');
else
    % Setup training data struct (filter instances and normalize keypoints)
    [train,~] = prep_data(data.train,1,params.nrsfm.flip);
    
    % Train model
    fprintf('Train Non Rigid SFM model \n');    
    train_model = train_nrsfm(params.class,train);
    
    % Caching trained NRSFM model
    fprintf('Caching NRSFM model in \n%s\n',shapeModelNRSFMFile);
    save(shapeModelNRSFMFile,'train_model');
end

end