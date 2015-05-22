function show_off(fname,color)
	[vertex,face] = read_off(fname);
    if(~exist('color','var'))
        showMesh(struct('faces',face,'vertices',vertex));
    else
        showMesh(struct('faces',face,'vertices',vertex),color);
    end
end
