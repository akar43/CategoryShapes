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
    
  I = imread([in_directory, name, '/diffuse.png']);
  I = double(I) ./ double(intmax('uint16'));
  V_im = ~any(I == 0,3);
  
  load([in_directory, name, '/Z.mat']);
  Z = depth; clear depth;
  
  
  V_Z = ~isnan(Z);
  
  Z = inpaintZ(Z, 0, 1);
  KZ = getK_fast(Z);
    
  [N, junk] = getNormals_conv(Z);
  N1 = N(:,:,1);
  N2 = N(:,:,2);
  N3 = N(:,:,3);
  NZ{name_i} = N3(V_Z);
  
  B = getBorderNormals(V_im);
  NZ_normal{name_i} = sum([N1(B.idx), N2(B.idx)] .* B.normal,2);
  
  figure(3);
  imagesc([visualizeDEM(Z)]); imtight; colormap('gray');
  drawnow;
  
  M_Z = medianFilterMat_mask(~V_Z, HALF_WIDTH);
  MKZs{name_i} = M_Z * KZ(:);
  
end


NZ = cellfun(@(x) randomlySelect(x, 30000), NZ, 'UniformOutput', false);
NZ = cat(1, NZ{:});
prior.height.NZ_train = NZ;


c = min(cellfun(@(x) length(x), NZ_normal));
NZ_normal = cellfun(@(x) randomlySelect(x, c), NZ_normal, 'UniformOutput', false);
NZ_normal = cat(1,NZ_normal{:});

x_step = 0.01;
x = -1:x_step:1;

X = NZ_normal;
X = X(~isnan(X));

[n] = hist(X, x); 
n = n ./ (x_step * sum(n));

bs = -10:0.05:10;
gs = 0.25:0.025:1.25;
losses = nan(length(gs), length(bs));
shifts = nan(length(gs), length(bs));
for gi = 1:length(gs)
  g = gs(gi);
  for bi = 1:length(bs)
    b = bs(bi);
    
    cost = (b * (1-x).^g);
    shift = log(sum(exp(-cost))*x_step);
    
    cost = cost + shift;
    loss = sum(cost .* n);
    
    if loss <= min(losses(:))
      plot(x, exp(-cost), 'b-'); hold on;
      plot(x, n, 'r-')
      hold off;
      drawnow;
    end

    losses(gi,bi) = loss;

  end
end

[gi,bi] = find(losses == min(losses(:)));

prior.height.normal = [];
prior.height.normal.mult = bs(bi);
prior.height.normal.power = gs(gi);
prior.height.normal.X_train = X;


MKZ = MKZs(:);
MKZ = cellfun(@(x) randomlySelect(x, 30000), MKZ, 'UniformOutput', false);
MKZ = cat(1, MKZ{:});
prior.height.MKZ.MKZ_train = MKZ;
prior.height.MKZ.GSM = GSM_fit(MKZ, 40, 0);


save(out_file, 'prior');


