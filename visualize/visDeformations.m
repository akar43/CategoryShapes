function visDeformations(class,trainId)
    globals
    sc = 0.1;    

    shName = jobDirs(class,trainId,'shapeModel');
    try
        tmp = load(shName);
    catch
        error('File not found. Make sure you are using the trainId and not jobID returned by mainTest');
    end
    tmp = tmp.shapeModelOpt;
    subplot(2,2,1);
    plot3(tmp.S(:,1),tmp.S(:,2),tmp.S(:,3),'.','LineWidth',3);
    axis equal off vis3d;
    title([class]);
    subplot(2,2,2)
    showMeshTri(struct('faces',tmp.tri,'vertices',tmp.S));
    title([class]);

    subplot(2,2,3)
    nBasis = size(tmp.alpha,1);
    for j=1:nBasis
        range = (max(tmp.alpha(j,:)) - min(tmp.alpha(j,:)))*sc;
        tt = linspace(mean(tmp.alpha(j,:)) - range,mean(tmp.alpha(j,:)) + range,100);
        for k=tt
            ttverts = tmp.S + reshape(k*tmp.V(:,j),size(tmp.S));
            h = showMeshTri(struct('faces',tmp.tri,'vertices',ttverts));
            view(-40,20);
            title(sprintf('Basis %d',j));            
            pause(0.02);cla(h);
        end
        pause(0.1);
    end
    
end
