function show_ply(plyname)
    [vertex,faces] = read_ply(plyname);
    showMesh(struct('vertices',vertex,'faces',faces));
end