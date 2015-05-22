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


function [results, state, data, params, avg_err] = go_Solve(eval_string)

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

if params.SHAPE_FROM_SHADING
  fprintf('params.multipliers.sfs = \n');
  disp(params.multipliers.sfs)
else
  fprintf('params.multipliers.reflectance = \n');
  disp(params.multipliers.reflectance)
end

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
  
    data.true.shading = imread([MIT_NATURAL_FOLDER, name, '/shading_color.png']);
    data.true.shading = double(data.true.shading) ./ double(intmax('uint16'));
    
    data.true.im = imread([MIT_NATURAL_FOLDER, name, '/diffuse.png']);
    data.true.im = double(data.true.im) ./ double(intmax('uint16'));
    
    load([MIT_NATURAL_FOLDER, name, '/L.mat']);
    data.true.light = L;
    
  else
    
    loaded = load([MIT_LABORATORY_FOLDER, name, '/shading_corrected_color.mat']);
    data.true.shading = loaded.shading_correct;
    
    data.true.im = imread([MIT_LABORATORY_FOLDER, name, '/diffuse.png']);
    data.true.im = double(data.true.im) ./ double(intmax('uint16'));
    
    load([MIT_LABORATORY_FOLDER, name, '/L.mat']);
    data.true.light = color_lights.diffuse;

  end

  data.true.mask = all(imread([MIT_LABORATORY_FOLDER, name, '/mask.png']) > 0,3);
  
  load([MIT_LABORATORY_FOLDER, name, '/crop_idx.mat'])
    
  for field = {'height', 'reflectance', 'im', 'shading', 'mask'}
    field = field{1};
    data.true.(field) = data.true.(field)(crop_idx1, crop_idx2,:);
  end
  
  if ~params.USE_COLOR_IMAGES
    
    data.true.reflectance = mean(data.true.reflectance,3);
    data.true.shading = mean(data.true.shading,3);
    data.true.im = mean(data.true.im,3);
    data.true.light = mean(data.true.light,2);
    
    params.NATURAL_ILLUMINATION = 0;
    
  end
  
  
  if params.RESIZE_INPUT ~= 1
  
    sz_before = size(data.true.height);
    
    Z = inpaintZ(data.true.height, 0, 1);
    
    S = data.true.shading;
    S(S==0) = nan;
    S = inpaintZ(S, 1, 0);
    
    A = data.true.reflectance;
    A(A==0) = nan;
    A = inpaintZ(A, 1, 0);
    
    I = data.true.im;
    I(I==0) = nan;
    I = inpaintZ(I, 1, 0);
    
    M = double(data.true.mask);
    
    I = max(0, min(1, imresize(I, params.RESIZE_INPUT)));
    S = max(0, min(1, imresize(S, params.RESIZE_INPUT)));
    A = max(0, min(1, imresize(A, params.RESIZE_INPUT)));
    Z = imresize(Z, params.RESIZE_INPUT)*params.RESIZE_INPUT;
    %     plot(Z2(end/2,:)); hold on; plot(Z(end/2,:)); hold on;
    M = imresize(M, params.RESIZE_INPUT) > 0.5;
    
    Z(~M) = nan;
    I(repmat(~M, [1,1,size(I,3)])) = 0;
    S(repmat(~M, [1,1,size(I,3)])) = 0;
    A(repmat(~M, [1,1,size(I,3)])) = 0;
    
    data.true.shading = S;
    data.true.reflectance = A;
    data.true.im = I;
    data.true.mask = M;
    data.true.height = Z;
    
  end
  
  
  im = data.true.im;
  shading = data.true.shading;
  
  valid = all(im > 0,3);
  im(repmat(~valid, [1,1,size(im,3)])) = nan;  
  shading(repmat(~valid, [1,1,size(im,3)])) = nan;  
  
  log_im = log(im);
  log_shading = log(shading);
  
  data.true.im = im;
  data.true.log_im = log_im;
  data.true.log_shading = log_shading;
  
  data.valid = valid;
  
  data.Z_median_filter_mat = medianFilterMat_mask(~data.valid, params.Z_MEDIAN_HALFWIDTH);
  data.A_median_filter_mat = medianFilterMat_mask(~data.valid, params.A_MEDIAN_HALFWIDTH);
  
  data.Z_median_filter_mat_T = data.Z_median_filter_mat';
  data.A_median_filter_mat_T = data.A_median_filter_mat';
  
  data.border = getBorderNormals(data.true.mask);
  
  data.true.normal = getNormals_conv(data.true.height);
  
  if ~params.SOLVE_SHAPE
    
    data.given.height = inpaintZ(data.true.height, 0, 1);
    [data.given.normal, data.given.d_normal_Z] = getNormals_conv(data.given.height);

  end
  
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
  
  if params.USE_COLOR_IMAGES
    data.prior.light = data.prior.lights.color.(LIGHT_MODEL);
  else
    data.prior.light = data.prior.lights.gray.(LIGHT_MODEL);
  end
  
  
  if params.USE_INIT_Z

    sigma = params.INIT_Z_SIGMA;
    pad = ceil(2.5*sigma);
    
    Z = data.true.height;
    Zp = nan(size(Z) + 2*pad);
    Zp(pad + [1:size(Z,1)], pad + [1:size(Z,2)]) = Z;
    Zp = inpaintZ(Zp, 0, 1);
    
    f = exp(-([-pad : pad]/sigma).^2);
    f = f ./ sum(f);
    
    Zb = conv2(conv2(Zp, f(:), 'same'), f(:)', 'same');
    Zb = Zb(pad + [1:size(Z,1)], pad + [1:size(Z,2)]);
    
    data.Z_init = Zb;
    data.Z_init(isnan(Z)) = nan;
    
  end
  
  start_time = clock;
    
  params.LOSSFUN = 'lossfun_sirfs';
  
  [state] = do_Solve(data, params);
  
  state.solve_time = etime(clock, start_time);
 
  if params.SHAPE_FROM_SHADING
    [err] = getError_SFS(state, data.true)
  else
    [err] = getError(state, data.true)
  end
    
  results{name_i}.err = err;
  results{name_i}.multipliers = params.multipliers;
  results{name_i}.solve_time = state.solve_time;
  
  state_pad = state;
  state_pad.height = nan(crop_init_size);
  if ~params.SHAPE_FROM_SHADING
    state_pad.reflectance = nan([crop_init_size,size(state.reflectance,3)]);
    state_pad.reflectance_exp = nan([crop_init_size,size(state.reflectance,3)]);
    state_pad.reflectance_max = nan([crop_init_size,size(state.reflectance,3)]);
  end
  state_pad.shading = nan([crop_init_size,size(state.shading,3)]);
  state_pad.normal = nan([crop_init_size,3]);
  
  if params.RESIZE_INPUT ~= 1
  
    state.shading = max(0, min(1, imresize(state.shading, sz_before)));
    if ~params.SHAPE_FROM_SHADING
      state.reflectance = max(0, min(1, imresize(inpaintZ(state.reflectance, 1, 0), sz_before)));
    end
    state.normal = imresize(state.normal, sz_before);
    state.normal = bsxfun(@rdivide, state.normal, sqrt(sum(state.normal.^2,3)));
    state.height = imresize(inpaintZ(state.height, 0, 1), sz_before)/params.RESIZE_INPUT;
    data.valid = imresize(double(data.valid), sz_before)>0.5;
  
  end
  
  
  state_pad.height(crop_idx1, crop_idx2) = state.height;
  if ~params.SHAPE_FROM_SHADING
    state_pad.reflectance(crop_idx1, crop_idx2,:) = state.reflectance;
  end
  state_pad.shading(crop_idx1, crop_idx2,:) = state.shading;
  state_pad.normal(crop_idx1, crop_idx2,:) = state.normal;
  
  invalid = true(crop_init_size);
  invalid(crop_idx1, crop_idx2) = ~data.valid;
  
  state_pad.height(invalid) = nan;
  if ~params.SHAPE_FROM_SHADING
    state_pad.reflectance(repmat(invalid,[1,1,size(state_pad.reflectance,3)])) = nan;
  end
  state_pad.shading(repmat(invalid,[1,1,size(state_pad.shading,3)])) = nan;
  state_pad.normal(repmat(invalid,[1,1,3])) = nan;
  
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

err = results{1}.err;
avg_err = [];
count = [];
for s = fieldnames(err)'
  s = s{1};
  avg_err.(s) = 0;
  count.(s) = 0;
end

for i = 1:length(results)
  err = results{i}.err;
  for s = fieldnames(err)'
    s = s{1};
    avg_err.(s) = avg_err.(s) + log(err.(s));
    count.(s) = count.(s) + 1;
  end
end

for s = fieldnames(err)'
  s = s{1};
  avg_err.(s) = exp(avg_err.(s) / count.(s));
end



