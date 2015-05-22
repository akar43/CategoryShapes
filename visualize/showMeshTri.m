function h = showMeshTri(fv)
    hfig = trisurf(fv.faces,fv.vertices(:,1),fv.vertices(:,2),fv.vertices(:,3),fv.vertices(:,2),...
        'CDataMapping','scaled','FaceColor','interp','SpecularStrength',0.2,'EdgeAlpha',0.2,...
        'LineStyle','-.');
    
    %camlight
    %camlight(-80,-10)
    lighting p
    axis equal off vis3d
    if(nargout>0)
        h = hfig;
    end
end