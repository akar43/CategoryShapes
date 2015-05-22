function h_fig = showMesh(mesh,color,h)
    if(nargin<3)
        %h = figure;
    else
        figure(h);
    end

    if(nargin<2)
        color = [1 0 0];
    end
    if(size(mesh.vertices,1)==3)
        mesh.vertices = mesh.vertices';
    end
    
    if(size(mesh.faces,1)==3)
        mesh.faces = mesh.faces';
    end
    h = patch('vertices',mesh.vertices,'faces',mesh.faces,'edgecolor','none',...
        'FaceColor',color,'FaceAlpha',0.9);       
    
    axis equal off vis3d
    lighting gouraud
    camlight
    camlight(-80,-10)

    if(nargout>0)
        h_fig = h;
    end
end
