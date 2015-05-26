function visNRSFMmodel(class,jobID)
% Visualize the NRSFM outputs
% class - Class to visualize
% jobID - suffix of the stateDir to visualize

globals;
stateDir = fullfile(cachedir,class,sprintf('statesDir%s',jobID));
if(~exist(stateDir,'dir'))
    error('State files not found at %s\n',stateDir);
end
fnames = getFileNamesFromDirectory(stateDir,'types',{'.mat'});
fnames = removeFlipNames(fnames);
load(fullfile(datadir,'partNames',class));
for i = 1:length(fnames)
    load(fullfile(stateDir,fnames{i}));
    
    subplot(221)
    imshow(state.im);
    title('Image');
    
    subplot(222)
    im = (color_seg(state.mask,state.im));   
    im = insertText(im,state.kps(1:2,:)',partNames,'FontSize',8);
    imshow(im);
    hold on;
    cmap = distinguishable_colors(size(state.kps,2),[0 1 1]);
    scatter(state.kps(1,:), state.kps(2,:),30,cmap,'Filled');
    hold off;
    title('Mask and Inferred Keypoints');
    
    subplot(223)
    tri = convhull(state.kps(1,:),state.kps(2,:),state.kps(3,:));    
    showMeshTri(struct('vertices',state.kps','faces',tri));
    hold on;
    for j = 1:length(partNames)
        text(state.kps(1,j),state.kps(2,j),state.kps(3,j),partNames{j},...
            'Interpreter','None','BackgroundColor','yellow','FontSize',8);
    end
    hold off
    view(0,-90);
    title('Convex hull of 3D keypoints');
    
    subplotsqueeze(gcf,1.2);
    pause;
end