function shapeModelOpt = trainBasisShapes(nrsfmModel, class, jobID)
% Run and cache basis shape model
globals

% Setup file names
shapeModelOptFile = jobDirs(class,jobID,'shapeModel');
statesDir = jobDirs(class,jobID,'state');
mkdirOptional(statesDir);

fprintf('\n%%%%%%%%%%%% Learning Basis Shapes %%%%%%%%%%%%\n');
% Train basis shape model / load cached model
if(exist(shapeModelOptFile,'file'))
    fprintf('Loading cached Basis Shape Model from \n%s\n',shapeModelOptFile);
    load(shapeModelOptFile);
else
    % Compute state files from nrsfmModel for faster distributed processing
    h = tic;
    getStateFiles(nrsfmModel,statesDir);
    shapeModelOpt = learnDenseShape(statesDir,class,jobID);
    fprintf('Caching Basis Shape Model at \n%s\n',shapeModelOptFile);
    save(shapeModelOptFile,'shapeModelOpt');
    fprintf('Basis Shape Learning time - %.3f secs\n',toc(h));
end

end
