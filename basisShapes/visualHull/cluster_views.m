function rotClusters = cluster_views(model_3d,inds,nClusters,vis)

    if(nargin<4)
        vis=0;
    end
    rots = model_3d.rots(inds);
    rots = cellfun(@(x)(x(:)'),rots,'UniformOutput',false);
    rots = vertcat(rots{:});
    T = clusterdata(rots,'distance',@riemannian_dist,'linkage','average','maxclust',nClusters);
    nClusters = length(unique(T));
    rotClusters = cell(nClusters,1);
    for i=1:nClusters
        rotClusters{i} = inds(T==i);
    end
    
    % Visualize
    if(vis)
        montage.W = 3000;
        montage.H = 3000;
        montage.sc = 0.5;
        for i=1:nClusters
            ImAll = vis_viewclusters(model_3d, rotClusters{i}, montage);
            figure;imshow(ImAll{1});
        end
    end
       
end

function d = riemannian_dist(R,Rmats)
    N = size(Rmats,1);
    R = reshape(R',[3 3]);
    Rmats = reshape(Rmats',[3 3 N]);
    d = zeros(N,1);
    parfor i=1:N
        d(i) = norm(log(eig(Rmats(:,:,i)'*R)));
    end        
end

function ImAll = vis_viewclusters(model_3d,inds, montage)
    globals;
    pasdir = PASCAL_DIR;
    I = cell(length(inds),1);
    for i=1:length(inds)
        im = imread([pasdir model_3d.voc_image_id{inds(i)} '.jpg']);
        if(model_3d.flip(inds(i)))
            im(:,:,1) = fliplr(im(:,:,1));im(:,:,2) = fliplr(im(:,:,2));im(:,:,3) = fliplr(im(:,:,3));
        end
        imbbox   = model_3d.bbox(inds(i),:);
        I{i} = imcrop(im,imbbox);
    end
    [~,ImAll] = makeMontage(I,montage.W,montage.H,montage.sc);
end