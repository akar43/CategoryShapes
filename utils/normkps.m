function normkps = normkps(points,bbox,maxbboxdim)

% Bounding boxes as [x,y,w,h]
% Keypoints as nKps x 2 x nImages matrix
% Bounding boxes scaled such that the maximum bounding box
% dimension is 'maxbboxdim'
nImages = size(points,3);
normkps = zeros(size(points));

for i=1:nImages
    if(mod(i,100)==0)
        %fprintf('Resizing box: %d/%d\n',i,nImages);
    end
    tr = bbox(i,1:2);
    sc = maxbboxdim/max(bbox(i,3),bbox(i,4));
    normkps(:,:,i) = sc*bsxfun(@minus,points(:,:,i),tr);
end

end
