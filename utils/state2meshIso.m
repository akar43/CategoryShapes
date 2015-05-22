function outMesh = state2meshIso(state)
% Use isosurface to construct mesh from point cloud
    params = get_params();
    from = params.vis.voxelsFrom;to = params.vis.voxelsTo;step = params.vis.voxelsSteps;
    rangeXYZ = round((to-from)/step)+1;
    [X,Y,Z] = ndgrid(from(1):step:to(1), from(2):step:to(2), from(3):step:to(3));
    tree = vl_kdtreebuild(state.S');
    voxelInds = generateInterestIndices(state.S,from,to,step);
    interestPoints = step*(voxelInds-1)+repmat(from,size(voxelInds,1),1);
    [~,distances] = vl_kdtreequery(tree,state.S',interestPoints');
    dist = inf(rangeXYZ);
    dist(sub2ind(rangeXYZ,voxelInds(:,1),voxelInds(:,2),voxelInds(:,3)))=distances;
    fv = isosurface(X,Y,Z,dist,0.3);
    fv.vertices = state.transform3d(fv.vertices);
    fv.vertices = smoothMesh(fv.faces,fv.vertices,1);
    fv.vertices(:,3) = fv.vertices(:,3) - mean(fv.vertices(:,3));
    outMesh = fv;
end

function pts = generateInterestIndices(S,from,to,step)
S = round((S-repmat(from,size(S,1),1))/step+1);
maxInds = (to-from)/step + 1;
mult = 2;
pts = [];
for i= -mult:mult
    for j=-mult:mult
        for k=-mult:mult
            pts = [pts;[(S(:,1)+i) (S(:,2)+j) (S(:,3)+k)]];
        end
    end
end

pts(:,1) = max(pts(:,1),1);pts(:,1) = min(pts(:,1),maxInds(1));
pts(:,2) = max(pts(:,2),1);pts(:,2) = min(pts(:,2),maxInds(2));
pts(:,3) = max(pts(:,3),1);pts(:,3) = min(pts(:,3),maxInds(3));

end
