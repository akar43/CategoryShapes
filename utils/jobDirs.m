function dirName = jobDirs(class,jobID,tag)

globals;
clsDir = fullfile(cachedir,class);
jobcat = @(x)strcat(x,jobID);
statesDir = fullfile(clsDir,jobcat('statesDir'));
inferredShapesDir = fullfile(clsDir,jobcat('inferredShapes'));
meshesDir = fullfile(clsDir,jobcat('meshes'));
dmapDir = fullfile(clsDir,jobcat('depthMap'));
sirfsDir = fullfile(clsDir,jobcat('sirfs'));
shapeModelOptFile = fullfile(clsDir,strcat(jobcat('shapeModelOpt'),'.mat'));
shapeModelNRSFMFile = fullfile(clsDir,'shapeModelNRSFM.mat');
evalMeshesFile = fullfile(clsDir,strcat(jobcat('evalMeshes'),'.mat'));
evalDepthFile = fullfile(clsDir,strcat(jobcat('evalDepth'),'.mat'));

switch tag
    case 'state'
        dirName = statesDir;
    case 'inferredShape'
        dirName = inferredShapesDir;
    case 'mesh'
        dirName = meshesDir;
    case 'dmap'
        dirName = dmapDir;
    case 'sirfs'
        dirName = sirfsDir;
    case 'shapeModel'
        dirName = shapeModelOptFile;
    case 'nrsfm'
        dirName = shapeModelNRSFMFile;
    case 'evalMesh'
        dirName = evalMeshesFile;
    case 'evalDepth'
        dirName = evalDepthFile;
    otherwise
        error('Which directory name do you want?');
end

end