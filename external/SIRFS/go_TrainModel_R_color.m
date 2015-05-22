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


clear all;

rand('twister',5489)
randn('state',0)

CONSTANTS;

N_GAUSSIANS = 40;
N_TRAIN = 100000;

in_directory = MIT_LABORATORY_FOLDER;

% MODE = 'test'
% MODE = 'train';

out_file = ['./prior.mat'];
names = MIT_TRAIN;
% names = [MIT_TRAIN, MIT_TEST];

try
  load(out_file, 'prior');
  fprintf('Loaded existing prior file.\n');
catch
  prior = [];
  fprintf('No existing prior file, making a new one.\n');
end

HALF_WIDTH = 2;

for name_i = 1:length(names)
  
  name = names{name_i};
  
  fprintf('loading %s\n', name)
  
  A = imread([in_directory, name, '/reflectance.png']);
  A = double(A) ./ double(intmax('uint16'));
  background = any(A == 0,3);
  A = log(max(eps,A));
  A(repmat(background, [1,1,3])) = nan;
    
  I = imread([in_directory, name, '/diffuse.png']);
  I = double(I) ./ double(intmax('uint16'));
  V_im = ~any(I == 0,3);
  
  M_im = medianFilterMat_mask(~V_im, HALF_WIDTH);
 
  A(repmat(~V_im, [1,1,3])) = nan;
  Av = reshape(A, [], 3);

  As{name_i} = Av(~any(isnan(Av),2),:);
  MAs{name_i} = M_im * Av;
  
end


As = cellfun(@(x) randomlySelect(x, 30000), As, 'UniformOutput', false);
A = cat(1, As{:});

prior.reflectance.color.A_train = A;

[A_white, whiten_params] = whiten(A, 0, 0.01);
prior.reflectance.color.A_whiten = whiten_params.map;

As_white = {};
for i = 1:length(As)
  As_white{i} = As{i} * whiten_params.map;
end
A_white = A * whiten_params.map;


prior.reflectance.color.bin_low =  [-7, -7, -7];
prior.reflectance.color.bin_high = [ 4,  4,  4];

% lambdas = 2.^[4:.5:10];
% robust_costs = 1;%[0,1];
% LLs = [];
% for ri = 1:length(robust_costs)
%   for li = 1:length(lambdas)
%     for j = 1:length(As_white)
%       A_train = cat(1,As_white{setdiff(1:length(As_white), j)});
%       A_test = As_white{j};
%       [junk, LL] = smoothHist3_fit(A_train, prior.reflectance.color.bin_low, prior.reflectance.color.bin_high, lambdas(li), robust_costs(ri));
%       
%       s = splat3_fast_wrapper(A_test, prior.reflectance.color.bin_low, prior.reflectance.color.bin_high);
%       LLs(ri,li,j) = sum(sum(sum(LL .* s.N)));
%     end
%   end
% end
% 
% cost = -sum(LLs,3);
% [ri, li] = find(cost == min(cost(:)));
% lambda = lambdas(li)
% robust_cost = robust_costs(ri)

lambda = 512;
robust_cost = 1;

A_train = cat(1,As_white{:});
[prior.reflectance.color.Aw_hist, LL] = smoothHist3_fit(A_train, prior.reflectance.color.bin_low, prior.reflectance.color.bin_high, lambda, robust_cost);
prior.reflectance.color.Aw_hist = prior.reflectance.color.Aw_hist - min(prior.reflectance.color.Aw_hist(:));





MAs = cellfun(@(x) randomlySelect(x, 3000), MAs, 'UniformOutput', false);
MA = cat(1, MAs{:});

prior.reflectance.color.MA.GSM_mvn = GSM_mvn_fitsmart(MA, 40);


save(out_file, 'prior');


