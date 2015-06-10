function visInferredShapes(class, jobID)
% Visualize fitted basis shapes cached in 'inferredShapes'

% Setup directories
globals;
inferredShapesDir = fullfile(cachedir, class, sprintf('inferredShapes%s',jobID));
meshDir = fullfile(cachedir, class, sprintf('meshes%s',jobID));
dmapDir = fullfile(cachedir, class, sprintf('depthMap%s',jobID));
fnames = getFileNamesFromDirectory(inferredShapesDir,'types',{'.mat'});
fnames = removeFlipNames(fnames);
fnames = fnames(randperm(length(fnames)));

hFig = figure;
load(fullfile(datadir,'partNames',class));
for i = 1:length(fnames)
    fprintf('%s: VOC ID = %s\n',class, fnames{i}(1:end-4));
    state = load(fullfile(inferredShapesDir,fnames{i}));
    state = state.state;
    try
        flipstate = load(fullfile(inferredShapesDir,['flip_' fnames{i}]));
        flipstate = flipstate.state;
    catch
        warning('Inferred state for flipped image not found');
    end


    meanVerts = (state.S + flipstate.S)/2;
    %meshVerts =  smoothMesh(state.tri,meshVerts,0);
    meshVerts = state.transform3d(meanVerts);
    mesh = struct('vertices',meshVerts,'faces',state.tri);

    divMesh = struct('vertices',meanVerts,'faces',state.tri);   
    divMesh = linearSubdivision(divMesh);divMesh = linearSubdivision(divMesh);   
    divVerts = divMesh.vertices;

%     try
%         mesh = load(fullfile(meshDir,fnames{i}));
%         flipmesh = load(fullfile(meshDir,['flip_' fnames{i}]));
%     catch
%         mesh = state2mesh(state);
%         flipmesh = state2mesh(flipstate);
%     end


    %state = flipstate; mesh = flipmesh;
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
    %showMeshTri(mesh);view(0,-90);
    %invMesh = mesh; invMesh.vertices = state.invtransform3d(invMesh.vertices);
    %invFlipMesh = flipmesh; invFlipMesh.vertices = flipstate.invtransform3d(invFlipMesh.vertices);
    %finMesh = invMesh;finMesh.vertices = (invMesh.vertices + invFlipMesh.vertices)/2;
    %finMesh.vertices = state.transform3d(finMesh.vertices);
    showMeshTri(mesh);view(0,-90);colormap jet

    title('Inferred Mesh');

    subplot(235)
    % Colored Point Cloud
    imsize = size(state.im); imsize = imsize(1:2);

    flipImVerts = flipstate.transform3d(divVerts);
    flipVisPtsIdx = getVisiblePoints(struct('vertices',flipImVerts,'faces',divMesh.faces));
    flipImVerts = flipImVerts(flipVisPtsIdx,:);

    % Get colors from flipped image
    maskIndsFlip = find(flipstate.mask(:));
    flipImVerts(:,1) = max(1,min(flipImVerts(:,1),imsize(2)));
    flipImVerts(:,2) = max(1,min(flipImVerts(:,2),imsize(1)));
    linIndsFlip = sub2ind(imsize,round(flipImVerts(:,2)),round(flipImVerts(:,1)));
    [linIndsFlip, IA] = intersect(linIndsFlip,maskIndsFlip);
    flipImVerts = flipImVerts(IA,:);

    rCh = flipstate.im(:,:,1); rCh = rCh(:);
    gCh = flipstate.im(:,:,2); gCh = gCh(:);
    bCh = flipstate.im(:,:,3); bCh = bCh(:);
    ptColorsFlip = [rCh(linIndsFlip) gCh(linIndsFlip) bCh(linIndsFlip)];
    plotVertsFlip = flipstate.invtransform3d(flipImVerts);
    plotVertsFlip = state.transform3d(plotVertsFlip);
    scatter3(plotVertsFlip(:,1),plotVertsFlip(:,2),plotVertsFlip(:,3),...
            15,single(ptColorsFlip)/255,'filled');hold on;

    % Mask project vertices only in mask
    imVerts = state.transform3d(divVerts);
    visPtsIdx = getVisiblePoints(struct('vertices',imVerts,'faces',divMesh.faces));
    imVerts = imVerts(visPtsIdx,:);

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
    %plotVerts = state.invtransform3d(imVerts);
    plotVerts = imVerts;
    scatter3(plotVerts(:,1),plotVerts(:,2),plotVerts(:,3),15,single(ptColors)/255,'filled');hold off;
    %scatter3(imVerts(:,1),imVerts(:,2),imVerts(:,3),15,single(ptColors)/255,'filled');
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
end

function visPointsIdx = getVisiblePoints(mesh)
vertices = mesh.vertices; faces = mesh.faces;
vert1 = vertices(faces(:,1),:);
vert2 = vertices(faces(:,2),:);
vert3 = vertices(faces(:,3),:);
centroid = mean(mesh.vertices);
orig = centroid + [0 0 10000];
orig = repmat(orig,length(vert1),1);
faceCenters = (vert1+vert2+vert3)/3;
[intersection] = TriangleRayIntersection(orig,faceCenters-orig,vert1,vert2,vert3,'planeType','one sided');
facesVis = faces(intersection,:); visPointsIdx = unique(facesVis(:));
end
