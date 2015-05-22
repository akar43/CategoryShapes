function outMesh = state2mesh(state)
% Use original triangulation and smooth to construct mesh from deformed point cloud    
    S = state.S;
    verts = state.transform3d(S);    
    newVerts =  smoothMesh(state.tri,verts,2);
    newVerts(:,3) = newVerts(:,3) - mean(newVerts(:,3));    
    outMesh.vertices = newVerts;
    outMesh.faces = state.tri;
end