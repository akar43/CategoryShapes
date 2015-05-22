function visInferredShapes(class, jobID)
% Visualize fitted basis shapes cached in 'inferredShapes'

% Setup directories
globals;
inferredShapesDir = fullfile(cachedir, class, sprintf('inferredShapes%s',jobID));
meshDir = fullfile(cachedir, class, sprintf('meshes%s',jobID));
dmapDir = fullfile(cachedir, class, sprintf('depthMap%s',jobID));
fnames = getFileNamesFromDirectory(inferredShapesDir,'types',{'.mat'});
hFig = figure;
load(fullfile(datadir,'partNames',class));
for i = 1:length(fnames)
    fprintf('%s: VOC ID = %s\n',class, fnames{i}(1:end-4));
    load(fullfile(inferredShapesDir,fnames{i}));
    try
        mesh = load(fullfile(meshDir,fnames{i}));
    catch
        mesh = state2mesh(state);
    end
    
    subplot(231)
    imshow(state.im);
    title('Image');

    subplot(232)
    im = (color_seg(state.mask,state.im));
    %im = insertText(im,state.kps(1:2,:)',partNames,'FontSize',8);
    imshow(im);
    hold on;
    cmap = distinguishable_colors(size(state.kps,2),[0 1 1]);
    scatter(state.kps(1,:), state.kps(2,:),30,cmap,'Filled');
    hold off;
    title('Image Mask (and Keypoints)');

    subplot(233)
    imVerts = mesh.vertices;
    vertNormals = state.normals*state.cameraRot';

    %Flip z axis to be in the image frame
    imVerts(:,3) = -imVerts(:,3);
    imVerts(:,3) = imVerts(:,3)-min(0,min(imVerts(:,3)));
    zDepth = imVerts(:,3);
    vertNormals(:,3) = -vertNormals(:,3);

    imshow(state.im); hold on;

    %patch('vertices', imVerts, 'faces', mesh.faces, 'CData', zDepth,'VertexNormals',vertNormals,...
    %    'CDataMapping','scaled', 'FaceColor', 'interp', 'FaceAlpha', ...
    %     0.7, 'EdgeColor', 'None');

     patch('vertices', imVerts, 'faces', state.tri, 'FaceColor', 'red', 'VertexNormals',...
         vertNormals, 'FaceAlpha', 0.7, 'EdgeColor','None','FaceLighting','gouraud',...
         'BackFaceLighting','lit');

    camlight; lighting p;
    camproj('orthographic');
    hold off;
    title('Mesh overlayed on Image');

    subplot(234)    
    showMeshTri(mesh);view(0,-90);
    title('Inferred Mesh');

    subplot(235)
    % Colored Point Cloud
    imsize = size(state.im); imsize = imsize(1:2);
    imVerts = mesh.vertices;
    
    % Mask project vertices only in mask
    maskInds = find(state.mask(:));
    imVerts(:,1) = max(1,min(imVerts(:,1),imsize(2)));
    imVerts(:,2) = max(1,min(imVerts(:,2),imsize(1)));
    linInds = sub2ind(imsize,round(imVerts(:,2)),round(imVerts(:,1)));
    [linInds, IA] = intersect(linInds,maskInds);
    imVerts = imVerts(IA,:);
    % Find colors for the points
    rCh = state.im(:,:,1); rCh = rCh(:);
    gCh = state.im(:,:,2); gCh = gCh(:);
    bCh = state.im(:,:,3); bCh = bCh(:);
    ptColors = [rCh(linInds) gCh(linInds) bCh(linInds)];
    % Plot
    scatter3(imVerts(:,1),imVerts(:,2),imVerts(:,3),15,single(ptColors)/255,'filled');
    axis off vis3d equal; view(0,-90);
    title('Colored Point Cloud');

    subplot(236)
    % Texture mapped depth map / Depth map
    try
        load(fullfile(dmapDir,fnames{i}));
    catch
        mesh = reducepatch(mesh,2000);
        dmap = meshToDepth(mesh.vertices,mesh.faces,size(state.mask));
        dmap(isinf(dmap)) = nan;
        dmap(~state.mask) = nan;
    end
    
    hIm = imagesc(imcrop(visualizeDEM(dmap),state.bbox));
    %set(hIm,'AlphaData',repmat(~isnan(imcrop(dmap,state.bbox)),[1 1 3]));
    %warp(dmap,state.im); view(0,90);
    axis equal off;
    title('Depth map');

    %subplotsqueeze(hFig, 1.2);
    pause; clf
end
