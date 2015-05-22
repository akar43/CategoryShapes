function kpGrad = keypointGrad(S,state,params,tree)
    neighbors = params.opt.kpNeighbours;
    if(params.opt.truncatedLoss)
        outlierMagMax = 5;
        outlierMagMin = 1.5;
        prctileGood = 80;
    else
        outlierMagMax = Inf;
        outlierMagMin = 0;
        prctileGood = 100;
    end
    thisS = state.transform3d(S);
    %thisS(:,3) = thisS(:,3) - mean(thisS(:,3));
    thiskps = state.kps';
    %thiskps(:,3) = thiskps(:,3) + mean(thisS(:,3));
    %mean(thisS(:,3))
    if(nargin<4)
        %h = tic;
        tree = vl_kdtreebuild(thisS');
        %fprintf('Time to build 3d tree: %.3f\n',toc(h));
    end
    [ids,~] = vl_kdtreequery(tree,thisS',thiskps','NUMNEIGHBORS',neighbors);
    ids = ids'; ids=ids(:);

    kpRep = repmat(thiskps,neighbors,1);

    
    diffs = (kpRep-thisS(ids,:));
    %diffs = 1/neighbors*(kpRep-thisS(ids,:));
    diff3d = [accumarray(ids,diffs(:,1),[size(thisS,1),1]) accumarray(ids,diffs(:,2),[size(thisS,1),1])...
         accumarray(ids,diffs(:,3),[size(thisS,1),1])];

    kpGrad = 1/state.cameraScale*diff3d*state.cameraRot;
    kpGradMag = sqrt(sum(kpGrad.^2,2));

    % Satisfy 80 percentile of the constraints.
    thresh = prctile(kpGradMag(kpGradMag~=0),prctileGood);

    outlierMag = min(outlierMagMax,thresh);
    if(outlierMag<outlierMagMin)
        outlierMag = Inf;
    end
    outliersIdx = sqrt(sum(kpGrad.^2,2))>outlierMag;    
    kpGrad(outliersIdx,:) = 0;
    
    % Visualization
    if 0
        h = figure;imshow(state.im); hold on;
        plot3(thisS(ids,1),thisS(ids,2),thisS(ids,3)-mean(thisS(:,3)),'gx','LineWidth',10);
        set(gca,'zdir','reverse');
        plot3(thiskps(:,1),thiskps(:,2),thiskps(:,3)-mean(thiskps(:,3)),'ro','LineWidth',10);
        pause
        plot3(thisS(:,1),thisS(:,2),thisS(:,3)-mean(thisS(:,3)),'bx','LineWidth',10);
        pause;
        close(h);
    end
end
