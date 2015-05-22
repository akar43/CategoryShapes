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
  A = mean(A,3);
  
  background = A == 0;
  A = log(max(eps,A));
  A(background) = nan;
  
  M_im = medianFilterMat_mask(background, HALF_WIDTH);
 
  As{name_i} = A(~background);
  MAs{name_i} = M_im * A(:);
  
  idx = find(~background);
  idx1 = randomlySelect(idx, 10000);
  idx2 = randomlySelect(idx, 10000);
  DAs{name_i} = A(idx1) - A(idx2);
  
end


As = cellfun(@(x) randomlySelect(x, 30000), As, 'UniformOutput', false);

prior.reflectance.gray.A_train = cat(1,As{:});

prior.reflectance.gray.A_range = [-7, 4];

% lambdas = 2.^[0:1:7];
% robust_costs = 1;%[0,1];
% LLs = [];
% for ri = 1:length(robust_costs)
%   for li = 1:length(lambdas)
%     for j = 1:length(As)
%       
%       A_train = cat(1,As{setdiff(1:length(As), j)});
%       A_test = As{j};
%       
%       [junk, LL] = smoothHist1_fit(A_train, prior.reflectance.gray.A_range(1), prior.reflectance.gray.A_range(2), lambdas(li), robust_costs(ri));
%       
%       s = splat1(A_test, prior.reflectance.gray.A_range(1), prior.reflectance.gray.A_range(2));
%       LLs(ri,li,j) = sum(sum(sum(LL .* s.N)));
%     end
%   end
% end
% 
% cost = -sum(LLs,3);
% [ri, li] = find(cost == min(cost(:)));
% lambda = lambdas(li)
% robust_cost = robust_costs(ri)

lambda = 32;
robust_cost = 1;

A_train = cat(1,As{:});
prior.reflectance.gray.A_spline = smoothHist1_fit(A_train, prior.reflectance.gray.A_range(1), prior.reflectance.gray.A_range(2), lambda, robust_cost);
prior.reflectance.gray.A_spline = prior.reflectance.gray.A_spline - min(prior.reflectance.gray.A_spline(:));





MAs = cellfun(@(x) randomlySelect(x, 30000), MAs, 'UniformOutput', false);
MA = cat(1, MAs{:});

prior.reflectance.gray.MA.MA_train = MA;
prior.reflectance.gray.MA.GSM = GSM_fit(MA, 40, 0);


save(out_file, 'prior');


