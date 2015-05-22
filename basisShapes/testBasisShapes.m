function testBasisShapes(shapeModelOpt, nrsfmTestModel, jobID)

globals
params = get_params();
class = params.class;

fprintf('\n%%%%%%%%%%%% Testing Basis Shapes %%%%%%%%%%%%\n');
%% Generate state files with relaxations specified in params
statesDirTest = jobDirs(class,jobID,'state');
mkdirOptional(statesDirTest);
getTestStateFiles(nrsfmTestModel, statesDirTest, params.opt.relaxInit);

%% Fit basis shapes and store in inferredShapesOptDir
inferredShapesOptDir = jobDirs(class,jobID,'inferredShape');
mkdirOptional(inferredShapesOptDir);
fitKnownShapes(shapeModelOpt,statesDirTest,inferredShapesOptDir);

end