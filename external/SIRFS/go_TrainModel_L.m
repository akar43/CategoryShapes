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

CONSTANTS

REGENERATE_DATA = 1;

rand('twister',5489)
randn('state',0)

if REGENERATE_DATA
  
  names = MIT_TRAIN;
  
  Ls = {};
  for name_i = 1:length(names)
    
    name = names{name_i};
    load([MIT_LABORATORY_FOLDER, name, '/L.mat'])
    L = cat(3,color_lights.light{:}, color_lights.diffuse, color_lights.shading);
    Ls{name_i} = L;
  end
  Ls = cat(3,Ls{:});
  
  % Ls = Ls(:,Ls(3,:) > 0);
  
  valid = false(1, size(Ls,3));
  for i = 1:size(Ls,3)
    valid(i) = validSH(Ls(:,:,i));
  end
  
  % figure; visLights(Ls(:,:,valid)); title('keep'); drawnow;
  % figure; visLights(Ls(:,:,~valid)); title('discard'); drawnow;
  
  Ls = Ls(:,:,valid);
  
  Ldata.train_color = Ls;
  Ldata.train_gray = mean(Ls,2);
  
  
  load natural_lights
  
  
  
  Ls_flip = Ls;
  Ls_flip([2,5,6],:) = -Ls_flip([2,5,6],:);
  
  Ls = cat(3, Ls, Ls_flip);
  
  Ls_yuv_base = L_rgb2yuv(Ls);
  
  Ls_yuv = {};
  for c = [2, 2.5, 3]
    Ls_yuv{end+1} = Ls_yuv_base .* repmat([1, 2.^-(c-1), 2.^-(c-1)], [9, 1, size(Ls_yuv_base,3)]);
  end
  Ls_yuv = cat(3,Ls_yuv{:});
  
  Ls = L_yuv2rgb(Ls_yuv);
  
  mults = [2.5,3,3.5];%[1, 1.5, 2, 2.5];
  Ls2 = {};
  for m = mults
    Ls2{end+1} = Ls*m;
  end
  Ls = cat(3,Ls2{:});
  
  
  Ls2 = {};
  for i = 1:size(Ls,3)
    L = Ls(:,:,i);
    if validSH(L)
      V = log(visSH_color(Ls(:,:,i)));
      c4 = 0.886227;
      L(1,:) = L(1,:) - max(V(:))/c4;
      V2 = log(visSH_color(L));
      Ls2{end+1} = L;
    end
  end
  Ls2 = cat(3,Ls2{:});
  Ls = Ls2;
  
  
  X = {};
  for i = 1:size(Ls,3)
    v = log(visSH_color(Ls(:,:,i), [32,32]));
    v = v - max(v(:));
    X{i} = v(~isnan(v));
  end
  X = cat(2,X{:});
  Dsq = distMat(X', X');
  
  too_close = triu(Dsq < 2,1);
  keep = ~any(too_close,1);
  Ls = Ls(:,:,keep);
  
  
  
  rand('twister',5489)
  randn('state',0)
  ridx = randperm(size(Ls,3));
  idx_train = ridx(1:round(size(Ls,3)/2));
  idx_test = ridx((round(size(Ls,3)/2)+1):end);
  
  Ls_train = Ls(:,:,idx_train);
  Ls_test = Ls(:,:,idx_test);
  
  
  Ldata.natural_train_color = Ls_train;
  Ldata.natural_test_color = Ls_test;
  
  save Ldata
else
  load Ldata
end


Ls = Ldata.natural_train_color;
X = reshape(Ls, [], size(Ls,3))';
[Xw, L_whiten_params] = whiten(X, 1, 0.01);
Ldata.whiten.natural_color = L_whiten_params;
Ldata.gaussian.natural_color.mu = mean(X,1);
Ldata.gaussian.natural_color.Sigma = cov(X);
Ldata.X.natural_color = X;


X = (X(:,1:9) + X(:,9+[1:9]) + X(:,18+[1:9]))/3;
[Xw, L_whiten_params] = whiten(X, 1, 0.01);
Ldata.whiten.natural_gray = L_whiten_params;
Ldata.gaussian.natural_gray.mu = mean(X,1);
Ldata.gaussian.natural_gray.Sigma = cov(X);
Ldata.X.natural_gray = X;




Ls = Ldata.train_color;
X = reshape(Ls, [], size(Ls,3))';

mu = mean(X);
Sigma = cov(X);

LL = lmvnpdf(X, mu, Sigma);
LL = LL - max(LL(:));
X = X(LL > prctile(LL, 50),:);
Ls = Ls(:,:,LL > prctile(LL, 50),:);

p = perms(1:3);
Ls2 = {};
for i = 1:size(p,1)
  Ls2{i} = Ls(:,p(i,:),:);
end
Ls = cat(3,Ls2{:});

Lf = Ls;
Lf([2,5,6],:,:) = -Lf([2,5,6],:,:);
Ls = cat(3, Ls, Lf);

V = {};
for i = 1:size(Ls,3)
  v = visSH_color(Ls(:,:,i), [150,150]);
  v = v ./ max(v(:));
  v(isnan(v)) = 0;
  V{i} = v;
end
V = cat(4,V{:});
montage(V)

X = reshape(Ls, [], size(Ls,3))';
[Xw, L_whiten_params] = whiten(X, 1, 0.01);
Ldata.whiten.laboratory_color = L_whiten_params;
Ldata.gaussian.laboratory_color.mu = mean(X,1);
Ldata.gaussian.laboratory_color.Sigma = cov(X);
Ldata.X.laboratory_color = X;


X = (X(:,1:9) + X(:,9+[1:9]) + X(:,18+[1:9]))/3;
[Xw, L_whiten_params] = whiten(X, 1, 0.01);
Ldata.whiten.laboratory_gray = L_whiten_params;
Ldata.gaussian.laboratory_gray.mu = mean(X,1);
Ldata.gaussian.laboratory_gray.Sigma = cov(X);
Ldata.X.laboratory_gray = X;


load prior


prior.lights = [];

prior.lights.color.laboratory = [];
prior.lights.color.laboratory.whiten_params = Ldata.whiten.laboratory_color;
prior.lights.color.laboratory.gaussian.mu = Ldata.gaussian.laboratory_color.mu;
prior.lights.color.laboratory.gaussian.Sigma = Ldata.gaussian.laboratory_color.Sigma;

prior.lights.color.natural = [];
prior.lights.color.natural.whiten_params = Ldata.whiten.natural_color;
prior.lights.color.natural.gaussian.mu = Ldata.gaussian.natural_color.mu;
prior.lights.color.natural.gaussian.Sigma = Ldata.gaussian.natural_color.Sigma;


prior.lights.gray.laboratory = [];
prior.lights.gray.laboratory.whiten_params = Ldata.whiten.laboratory_gray;
prior.lights.gray.laboratory.gaussian.mu = Ldata.gaussian.laboratory_gray.mu;
prior.lights.gray.laboratory.gaussian.Sigma = Ldata.gaussian.laboratory_gray.Sigma;

prior.lights.gray.natural = [];
prior.lights.gray.natural.whiten_params = Ldata.whiten.natural_gray;
prior.lights.gray.natural.gaussian.mu = Ldata.gaussian.natural_gray.mu;
prior.lights.gray.natural.gaussian.Sigma = Ldata.gaussian.natural_gray.Sigma;


save prior prior

