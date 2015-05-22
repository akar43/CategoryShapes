function pos=read_pascal(cls,year,keypoints,segmentations)

% Read pascal to generate filtered instances of classes

globals;
dataset_fg = 'trainval';
conf.year=year;
conf.dev_kit=[BASE_DIR 'data/VOC2011/VOCdevkit'];
VOCopts    = get_voc_opts(conf);

% Setup keypoints and segmentations voc_id
kps_voc_id = cellfun(@(x,y) [x, '_', y], keypoints.voc_image_id, arrayfun(@num2str, keypoints.voc_rec_id, 'Uniform', false), 'UniformOutput', false);
segs_voc_id = cellfun(@(x,y) [x, '_', y], segmentations.voc_image_id, arrayfun(@num2str, segmentations.voc_rec_id, 'Uniform', false), 'UniformOutput', false);


  % Positive examples from the foreground dataset
  ids      = textread(sprintf(VOCopts.imgsetpath, dataset_fg), '%s');
  pos      = [];
  numpos   = 0;
  for i = 1:length(ids);
    if(mod(i,500)==0)
        fprintf('Parsed ids %d/%d\n',i,length(ids));
    end
    % Parse record and exclude difficult examples
    rec           = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds       = strmatch(cls, {rec.objects(:).class}, 'exact');
    count         = length(clsinds(:));
    % Skip if there are no objects in this image
    if count == 0
      continue;
    end

    diff          = [rec.objects(clsinds).difficult];
    trunc         = [rec.objects(clsinds).truncated];
    if(~isempty(clsinds) && isfield(rec.objects(clsinds(1)),'occluded'))
        occl = [rec.objects(clsinds).occluded];
    else
        occl = true(size(clsinds));
    end

    clsinds2del = diff | trunc | occl; % Change this for different datasets
    %clsinds2del = diff;
    clsinds(clsinds2del)=[];

    count         = length(clsinds(:));
    % Skip if there are no objects in this image
    if count == 0
      continue;
    end

    % Create one entry per bounding box in the pos array
    for j = clsinds(:)'
      numpos = numpos + 1;
      j_voc_id = [rec.filename(1:end-4) '_' num2str(j)];
      ki = find(ismember(kps_voc_id,j_voc_id));
      si = find(ismember(segs_voc_id,j_voc_id));
      bbox   = rec.objects(j).bbox;
      pos(numpos).imsize = [rec.size.height rec.size.width];
      pos(numpos).voc_image_id = rec.filename(1:end-4);
      pos(numpos).voc_rec_id = j;
      %pos(numpos).im      = [VOCopts.datadir rec.imgname];
      pos(numpos).pascal_bbox   = [bbox(1:2) bbox(3)-bbox(1)+1 bbox(4)-bbox(2)+1]; %(x,y,w,h)
      pos(numpos).view    = rec.objects(j).view;
      pos(numpos).kps     = squeeze(keypoints.coords(ki,:,:));
      pos(numpos).part_names  = keypoints.labels;
      pos(numpos).bbox        = keypoints.bbox(ki,:);
      pos(numpos).poly_x      = segmentations.poly_x{si};
      pos(numpos).poly_y      = segmentations.poly_y{si};
      pos(numpos).class       = cls;
    end
  end
  pascal_data= pos;
  fname = [cachedir 'pascal_filt_data/pascal_' cls '_filt.mat'];
  save(fname,'pascal_data');
end

function VOCopts = get_voc_opts(conf)
% cache VOCopts from VOCinit
persistent voc_opts;

key = conf.year;
if isempty(voc_opts) || ~voc_opts.isKey(key)
  if isempty(voc_opts)
    voc_opts = containers.Map();
  end
  tmp = pwd;
  cd(conf.dev_kit);
  addpath([cd '/VOCcode']);
  VOCinit;
  cd(tmp);
  voc_opts(key) = VOCopts;
end
VOCopts = voc_opts(key);
end
