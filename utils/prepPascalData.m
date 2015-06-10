function data = prepPascalData(class)
%% Setup the training data struct
globals;

% Change this if you want to use your own data
dataFile = fullfile(datadir,'pascalData',class);

% Load trainval ids for PASCAL
load(fullfile(datadir, 'pascalTrainValIds.mat'));

% Load the PASCAL data struct
load(dataFile);

% Augment PASCAL data struct with viewpoint prediction network features
% pascal_data = augmentPosenetFeat(pascal_data,class);

% Augment with PASCAL3D data - used for evaluation to align
% learned models to PASCAL 3D frame
% Comment this if you dont want to align to PASCAL 3D frame.
pascal_data = augmentPascal3Ddata(pascal_data,class);

% Create train test split
if(1)
    % Train/Test on everything
    data.train = pascal_data;
    data.test  = pascal_data;
else
    % Train on PASCAL detection train and test on PASCAL test
    data.train = filterData(pascal_data,trainIds);
    data.test = filterData(pascal_data,valIds,0); %remove flipped instances
end

% Compute actual poses from pose features for test set
%data.test = computePosePredictions(data.test);

end
