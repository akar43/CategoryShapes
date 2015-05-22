% Copyright �2013. The Regents of the University of California (Regents).
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


function output = SIRFS(input_image, input_mask, input_height, eval_string)
% output = SIRFS(input_image, input_mask, input_height, eval_string)
% runs SIRFS on input_image, subject to the masking in input_mask.
% Also takes in input_height, in case you want to constrain the shape to be
% similar to some other shape, or if you want to fix the shape to
% something.
% eval_string is a string that is evaluated, that can be used to set
% parameters for some experiment. See README.txt for some examples

assert(isa(input_image, 'double')) % input images should be real-valued, from 0 to 1.
assert(isa(input_mask, 'logical')) % input masks should be logical

X = input_image(repmat(input_mask, [1,1,size(input_image,3)])); % non-masked pixels
assert(all(X <= 1)) % input images shouldn't be greater than 1, not that it matters much.
assert(all(X >= (1/255))) % Really dark pixels mess stuff up badly, because we work in logs.


rand('twister',5489)
randn('state',0)

curdir = pwd;
if strcmp(curdir(1:10), '/Users/jon')
%   compile
else
  %fprintf('not compiling\n');
  
  try
    warning off;
    maxNumCompThreads(1);
    warning on;
  catch ME
    fprintf('ERR: %s\n', ME.message);
  end
  
end

if nargin < 4
  eval_string = '';
end

CONSTANTS;

params.EVAL_STRING = eval_string;
eval(params.EVAL_STRING);

PARAMETERS;

%fprintf('%s\n', params.EVAL_STRING);
eval(params.EVAL_STRING);

load(params.PRIOR_MODEL_STRING)

if params.SHAPE_FROM_SHADING
%  fprintf('params.multipliers.sfs = \n');
%  disp(params.multipliers.sfs)
else
%  fprintf('params.multipliers.reflectance = \n');
%  disp(params.multipliers.reflectance)
end

%fprintf('params.multipliers.height = \n');
%disp(params.multipliers.height)

%fprintf('params.multipliers.light = \n');
%disp(params.multipliers.light)

params.USE_COLOR_IMAGES = size(input_image,3) == 3;

if ~params.USE_COLOR_IMAGES
  params.NATURAL_ILLUMINATION = 0;
end

data.true.im = input_image;
    
im = data.true.im;
    
valid = input_mask;
im(repmat(~valid, [1,1,size(im,3)])) = nan;
log_im = log(im);

data.true.im = im;
data.true.log_im = log_im;

if params.SHAPE_FROM_SHADING
  data.true.shading = im;
  data.true.log_shading = log_im;
end

data.valid = valid;
data.true.mask = valid;

data.Z_median_filter_mat = medianFilterMat_mask(~data.valid, params.Z_MEDIAN_HALFWIDTH);
data.A_median_filter_mat = medianFilterMat_mask(~data.valid, params.A_MEDIAN_HALFWIDTH);

data.Z_median_filter_mat_T = data.Z_median_filter_mat';
data.A_median_filter_mat_T = data.A_median_filter_mat';

data.border = getBorderNormals(data.true.mask);

data.prior = prior;
    
  
if ~params.SOLVE_SHAPE
  
  data.given.height = inpaintZ(input_height, 0, 1);
  [data.given.normal, data.given.d_normal_Z] = getNormals_conv(data.given.height);
  
end

if params.USE_INIT_Z
  
  data.Z_init = input_height;
  data.Z_init(isnan(input_height)) = nan;
  
end


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

    
params.LOSSFUN = 'lossfun_sirfs';
    
output = do_Solve(data, params);
    


