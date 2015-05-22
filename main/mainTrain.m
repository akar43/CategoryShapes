function basisShapeModel = mainTrain(class,exptID,paramStruct)
if(nargin<3)
    paramStruct = {};
end

if(nargin<2)
    exptID = '';
end

%% Setting up directory and file names
startup;
globals;
mkdirOptional(fullfile(cachedir,class));
params = get_params(paramStruct);
params.class = class;

%% Reading data for NRSFM
data = prepPascalData(class);

%% Run NRSFM and cache model / Load cached models
nrsfmModel = runTrainNRSFM(data,class);

%% Run and cache basis shape model
basisShapeModel = trainBasisShapes(nrsfmModel, class, exptID);

end
