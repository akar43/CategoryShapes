function visAllMeanShapes(classes,id)    
    N = length(classes);
    for i=1:length(classes)
        subplot(ceil(sqrt(N)),ceil(sqrt(N)),i);
        shapeModels = jobDirs(classes{i},id,'shapeModel');             
        tmp = load(shapeModels);        
        showMeshTri(struct('vertices',tmp.shapeModelOpt.S,'faces',tmp.shapeModelOpt.tri));  
        colormap jet
        view(3);        
    end    
end