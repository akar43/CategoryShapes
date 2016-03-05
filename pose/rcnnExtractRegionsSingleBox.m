function [batches, batch_padding] = rcnnExtractRegionsSingleBox(dataStruct, rcnn_model,mirror,padRatio)

globals;
if(nargin<4)
    padRatio = 0;
end

singleImage = length(dataStruct.voc_image_id) == 1;
if(singleImage)
    im = imread(fullfile(PASCAL_DIR,[dataStruct.voc_image_id{1} '.jpg']));
    im = single(im(:,:,[3 2 1]));
end

num_boxes = size(dataStruct.bbox,1);
batch_size = rcnn_model.cnn.batch_size;
num_batches = ceil(num_boxes / batch_size);
batch_padding = batch_size - mod(num_boxes-1, batch_size) - 1;

crop_mode = rcnn_model.detectors.crop_mode;
image_mean = rcnn_model.cnn.image_mean;
crop_size = size(image_mean,1);
crop_padding = rcnn_model.detectors.crop_padding;

batches = cell(num_batches, 1);
for batch = 1:num_batches
%  disp(batch);
%parfor batch = 1:num_batches
  batch_start = (batch-1)*batch_size+1;
  batch_end = min(num_boxes, batch_start+batch_size-1);

  ims = zeros(crop_size, crop_size, 3, batch_size, 'single');
  for j = batch_start:batch_end
    bbox = dataStruct.bbox(j,:);
    if(~singleImage)
        im = imread(fullfile(PASCAL_DIR,[dataStruct.voc_image_id{j} '.jpg']));
        im = single(im(:,:,[3 2 1]));
    end
    [crop] = rcnn_im_crop(im, bbox, crop_mode, crop_size, ...
        crop_padding, image_mean);
    if(mirror)
        %size(crop)
        for k=1:size(crop,3)
            crop(:,:,k) = fliplr(crop(:,:,k));
        end
    end
    % swap dims 1 and 2 to make width the fastest dimension (for caffe)
    ims(:,:,:,j-batch_start+1) = permute(crop, [2 1 3]);
  end

  batches{batch} = ims;
end
