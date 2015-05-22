function [] = postProcessMeshes(fnames,meshDir,meshDirFinal,smoothIter,flipZ)
%POSTPROCESSMESHES Summary of this function goes here
%   Detailed explanation goes here

    
parfor i = 1:length(fnames)
    meshFile = fullfile(meshDir,fnames{i});
    meshFileSave = fullfile(meshDirFinal,fnames{i});
    mesh = load(meshFile);
    tri = mesh.tri;
    vertices = mesh.vertices;
    if(smoothIter > 0)
        vertices = smoothMesh(tri,vertices',smoothIter);
        vertices = vertices';
    end
    if(flipZ)
        vertices(3,:) = -vertices(3,:);
    end
    savefunc(meshFileSave,vertices,tri);
end
end

function [] = savefunc(file,vertices,tri)
save(file,'vertices','tri');
end