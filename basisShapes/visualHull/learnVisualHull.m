 function [voxels,occlusions] = learnVisualHull(from,to,step,statesDir,fnames,wts)

if(nargin<5)
    fnames = getFileNamesFromDirectory(statesDir,'types',{'.mat'});
end

if(nargin<6)
    wts = ones(length(fnames));
end

for i=1:length(fnames)
    fnames{i} = fullfile(statesDir,fnames{i});
end

X = length(from(1):step:to(1));
Y = length(from(2):step:to(2));
Z = length(from(3):step:to(3));
voxels = zeros(X*Y*Z,3);
occlusions = zeros(X*Y*Z,1);

for i=1:X
    for j=1:Y
        for k=1:Z
            voxels((i-1)*Y*Z+(j-1)*Z+k,:)=[from(1)+(i-1)*step,from(2)+(j-1)*step,from(3)+(k-1)*step];
        end
    end
end

numimages = length(fnames);

pBar =  TimedProgressBar( numimages, 30, ...
    'Visual Hull initialization ', ', completed ', 'Visual Hull computation ' );
for i=1:numimages    
    state = load(fnames{i},'state');
    %occlusions = occlusions + wts(i)*(double(dist2silhouette(voxels,state.state)>0));
    %occlusions = occlusions + wts(i)*(dist2silhouette(voxels,state.state));
    occlusions = occlusions + wts(i)*(dist2silhouette(voxels,state.state));
    %occlusions = occlusions + wts(i)*volumeIntersection(voxels,state.state);
    pBar.progress();
end
pBar.stop();
end

