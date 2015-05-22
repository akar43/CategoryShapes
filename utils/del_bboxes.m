function inds2del = del_bboxes(bbox,imsize,thresh)
    bboxsize = prod(bbox(:,3:4),2);
    imsize  = prod(imsize,2);
    inds2del = (bboxsize./imsize<thresh);
%     parfor i=1:nImages
%         fprintf('Checking bboxsize: %d/%d\n',i,nImages);
%         im=imread([pasdir image_id{i} '.jpg']);
%         imsize = numel(im);
%         bboxsize = prod(bbox(i,3:4));
%         if(bboxsize/imsize<thresh)
%             inds2del(i)=1;
%         end
%     end
end
