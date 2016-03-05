function feat = rcnnFeaturesSingleBox(dataStruct, rcnn_model,mirror,labelsIn)
%% dataStruct has voc_image_id, bbox as fields
% make sure that caffe has been initialized for this model
if rcnn_model.cnn.init_key ~= caffe('get_init_key')
  error('You probably need to call rcnn_load_model');
end
if(nargin<3)
    mirror=0;
end
if(nargin<4)
    labelsIn = false;
end
% Each batch contains 256 (default) image regions.
% Processing more than this many at once takes too much memory
% for a typical high-end GPU.
disp('Extracting image patches');
[batches, batch_padding] = rcnnExtractRegionsSingleBox(dataStruct, rcnn_model, mirror);
batch_size = rcnn_model.cnn.batch_size;
%disp(['numBatches = ' num2str(length(batches))])
%keyboard;
% compute features for each batch of region images
feat_dim = -1;
feat = [];
curr = 1;
disp('Computing Features');
for j = 1:length(batches)
  % forward propagate batch of region images
  %keyboard;
  if(labelsIn)
      labels = zeros(1,1,1,batch_size);
      labels(1:min(length(dataStruct.labels)-(j-1)*batch_size,batch_size)) = dataStruct.labels(curr:min(j*batch_size,length(dataStruct.labels)));
      f = caffe('forward', {batches{j};single(labels)});
  else
      f = caffe('forward', batches(j));
  end
  f = f{1};
  %keyboard;
  f = f(:);
  %keyboard;

  % first batch, init feat_dim and feat
  if j == 1
    feat_dim = length(f)/size(batches{j},4);
    feat = zeros(size(dataStruct.bbox,1), feat_dim, 'single');
  end

  f = reshape(f, [feat_dim batch_size]);
  % last batch, trim f to size
  if j == length(batches)
      %disp(['padding = ' (num2str(batch_padding))])
    if batch_padding > 0
      f = f(:, 1:end-batch_padding);
    end
  end

  feat(curr:curr+size(f,2)-1,:) = f';
  curr = curr + batch_size;
end
