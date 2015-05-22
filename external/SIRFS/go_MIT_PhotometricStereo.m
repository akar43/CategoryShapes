% Copyright ©2013. The Regents of the University of California (Regents).
% All Rights Reserved. Permission to use, copy, modify, and distribute
% this software and its documentation for educational, research, and
% not-for-profit purposes, without fee and without a signed licensing
% agreement, is hereby granted, provided that the above copyright notice,
% this paragraph and the following two paragraphs appear in all copies,
% modifications, and distributions. Contact The Office of Technology
% Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA
% 94720-1620, (510) 643-7201, for commercial licensing opportunities.
%
% Created by Jonathan T Barron and Jitendra Malik, Electrical Engineering
% and Computer Science, University of California, Berkeley.
%
% IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
% SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
% ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
% REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
% PROVIDED HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


function state = go_Solve(eval_string)

rand('twister',5489)
randn('state',0)

curdir = pwd;
if strcmp(curdir(1:10), '/Users/jon')
%   compile
else
  fprintf('not compiling\n');
  
  try
    maxNumCompThreads(1)
  catch ME
    fprintf('ERR: %s\n', ME.message);
  end
  
end

if nargin == 0
  eval_string = '';
end

CONSTANTS;

params.EVAL_STRING = eval_string;
eval(params.EVAL_STRING);

PARAMETERS;

fprintf('%s\n', params.EVAL_STRING);
eval(params.EVAL_STRING);

load(params.PRIOR_MODEL_STRING)

fprintf('params.multipliers.reflectance = \n');
disp(params.multipliers.reflectance)

fprintf('params.multipliers.height = \n');
disp(params.multipliers.height)

fprintf('params.multipliers.light = \n');
disp(params.multipliers.light)

if isfield(params, 'EVAL_NAMES')
  names = params.EVAL_NAMES;
else
%   names = MIT_TEST;
%   names = {'apple'};
%   names = {'frog1'};
%   names = {'paper1'};
%   names = {'frog2'};
%   names = {'turtle'};
%   names = {'panther'};
%   names = {'raccoon'};
%   names = {'dinosaur'};
  names = {'paper2'};
%   names = {'cup2'};
%   names = {'box'};
%   names = {'sun'};
end

for name_i = 1:length(names)
  name = names{name_i};

  
  load([MIT_LABORATORY_FOLDER, name, '/Z.mat']);
  clear lights
  data.true.height = depth;
  
  data.true.reflectance = imread([MIT_LABORATORY_FOLDER, name, '/reflectance.png']);
  data.true.reflectance = double(data.true.reflectance) ./ double(intmax('uint16'));

  
  if params.NATURAL_ILLUMINATION
  
    assert(0); % no data for this
    
  else
    
    dirents = dir([MIT_LABORATORY_FOLDER, name, '/light*.png']);
    data.true.ims = {};
    for im_i = 1:length(dirents)
      data.true.ims{im_i} = double(imread([MIT_LABORATORY_FOLDER, name, '/', dirents(im_i).name])) ./ double(intmax('uint16'));
    end
    
  end

  data.true.mask = all(imread([MIT_LABORATORY_FOLDER, name, '/mask.png']) > 0,3);
  
  load([MIT_LABORATORY_FOLDER, name, '/crop_idx.mat'])
    
  for field = {'height', 'reflectance', 'mask'}
    field = field{1};
    data.true.(field) = data.true.(field)(crop_idx1, crop_idx2,:);
  end
  
  for im_i = 1:length(data.true.ims)
    data.true.ims{im_i} = data.true.ims{im_i}(crop_idx1, crop_idx2,:);
  end
  
  data.valids = {};
  data.true.log_ims = {};
  for im_i = 1:length(data.true.ims)
    im = data.true.ims{im_i};
  
    valid = all(im > 0,3);
    im(repmat(~valid, [1,1,size(im,3)])) = nan;
    log_im = log(im);
    
    data.true.ims{im_i} = im;
    data.true.log_ims{im_i} = log_im;
    data.valids{im_i} = valid;
  end
      
  data.valid = sum(cat(3, data.valids{:}),3) > 0;
  
  data.Z_median_filter_mat = medianFilterMat_mask(~data.valid, params.Z_MEDIAN_HALFWIDTH);
  data.A_median_filter_mat = medianFilterMat_mask(~data.valid, params.A_MEDIAN_HALFWIDTH);
  
  data.Z_median_filter_mat_T = data.Z_median_filter_mat';
  data.A_median_filter_mat_T = data.A_median_filter_mat';
  
  data.border = getBorderNormals(data.true.mask);
  
  data.true.normal = getNormals_conv(data.true.height);
  
  data.prior = prior;

  for v = params.GLOBAL_VARS
    eval(['global ', v{1}, ';']);
    eval([v{1}, ' = [];']);
  end
  
  if params.NATURAL_ILLUMINATION
    LIGHT_MODEL = 'natural';
  else
    LIGHT_MODEL = 'laboratory';
  end
  
  data.prior.light = data.prior.lights.color.(LIGHT_MODEL);
  
  start_time = clock;
    
  params.LOSSFUN = 'lossfun_sirfs_multi';
  
  [state] = do_Solve(data, params);
  
  state.solve_time = etime(clock, start_time);
 
  invalid = true(crop_init_size);
  invalid(crop_idx1, crop_idx2) = ~data.valid;

  state_pad = state;
  
  state_pad.height = nan(crop_init_size);
  state_pad.height(crop_idx1, crop_idx2) = state.height;
  state_pad.height(invalid) = nan;
  
  state_pad.normal = nan([crop_init_size,3]);
  state_pad.normal(crop_idx1, crop_idx2,:) = state.normal;
  state_pad.normal(repmat(invalid,[1,1,3])) = nan;
  
  for im_i = 1:length(state.reflectances)
    state_pad.reflectances{im_i} = nan([crop_init_size,size(state.reflectances{im_i},3)]);
    state_pad.reflectances{im_i}(crop_idx1, crop_idx2,:) = state.reflectances{im_i};
    state_pad.reflectances{im_i}(repmat(invalid,[1,1,size(state_pad.reflectances{im_i},3)])) = nan;
  
    state_pad.shadings{im_i} = nan([crop_init_size,size(state.shadings{im_i},3)]);
    state_pad.shadings{im_i}(crop_idx1, crop_idx2,:) = state.shadings{im_i};
    state_pad.shadings{im_i}(repmat(invalid,[1,1,size(state_pad.shadings{im_i},3)])) = nan;
  end
  
  state = state_pad;
  
  if ~isempty(params.DUMP_OUTPUT)
    system(['mkdir ', params.DUMP_OUTPUT]);
    save([params.DUMP_OUTPUT, '/', name, '.mat'], 'state');
  end
  
end

if ~isempty(params.OUTPUT_FILENAME)

  fprintf('Saving results and params to %s... ', params.OUTPUT_FILENAME);
  save(params.OUTPUT_FILENAME, 'results', 'params');
  fprintf('done.\n');

end

