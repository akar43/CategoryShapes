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


function [loss_Z, d_loss_Z] = priorZ(Z, data, params, N, dN_Z)

loss_Z = 0;
d_loss_Z = 0;
losses_Z = [];

mult_smooth = params.multipliers.height.smooth{1} * ((1/((params.Z_MEDIAN_HALFWIDTH*2+1)^2))/numel(Z));

if mult_smooth ~= 0

  [KZ, dKZ] = getK_fast(Z);
  C = data.prior.height.MKZ.GSM;
  
  M = data.Z_median_filter_mat;
  M_T = data.Z_median_filter_mat_T;
  
  MKZ = M * KZ(:);
  
  abs_MKZ = abs(MKZ);
  sign_MKZ = sign(MKZ);
  
  epsilon = params.Z_SMOOTH_EPSILON{1};
  if epsilon > 0
    soft_MKZ = sqrt(abs_MKZ.^2 + epsilon.^2);
  else
    soft_MKZ = abs_MKZ;
  end
  
%   epsilon = 10^-4;
%   abs_MKZ = max(epsilon, abs_MKZ);
  [L, dL_mask] = interp1_fixed_sum_fast(soft_MKZ(:), C.lut.bin_range(1), C.lut.bin_width, C.lut.F_cost);
%   dL_mask(abs_MKZ <= epsilon) = 0;
  
  if epsilon > 0
    dL_mask = dL_mask .* (abs_MKZ ./ max(eps,soft_MKZ));
  end

  dL_mask = dL_mask .* sign_MKZ;
  
  dL_KZ = reshape(M_T * dL_mask, size(KZ));%reshape(dL_mask' * M, size(KZ));
  
  losses_Z.curvature = sum(L(:));
  loss_Z = loss_Z + mult_smooth * losses_Z.curvature;
  d_loss_Z = d_loss_Z + mult_smooth * getK_backprop_fast_mat(dL_KZ, dKZ);
  
end


if (params.USE_INIT_Z)

  mult_init = params.multipliers.height.init{1}/10;
  
  pow = params.multipliers.height.init_power{1}/2;
  epsilon = 1/100;

  Zi = data.Z_init;
  V = ~isnan(Zi);
  
  sigma = params.INIT_Z_SIGMA;
  pad = ceil(2.5*sigma);
  f = exp(-([-pad : pad]/sigma).^2);
  f = f ./ sum(f);
    
  Zb = conv2(conv2(Z, f(:), 'same'), f(:)', 'same');
    
  delta = Zb(V) - Zi(V);
  
  soft_delta = (delta.^2 + epsilon.^2);
  
  losses_Z.init = sum(soft_delta.^pow)/numel(delta);
  loss_Z = loss_Z + mult_init * losses_Z.init;
  
  dL = zeros(size(Z));
  dL(V) = (mult_init/numel(delta) * 2*pow) .* soft_delta.^(pow-1) .* delta;
  
  dL = conv2(conv2(dL, f(:), 'same'), f(:)', 'same');
  
  d_loss_Z = d_loss_Z + dL;
  
end


if nargin < 6
  [N, dN_Z] = getNormals_conv(Z);
end
N1 = N(:,:,1);
N2 = N(:,:,2);
N3 = N(:,:,3);

d_loss_N = {};
d_loss_N{1} = zeros(size(N1));
d_loss_N{2} = zeros(size(N2));
d_loss_N{3} = zeros(size(N3));



if (params.multipliers.height.contour_mult{1} ~= 0)

  mult_normal = 60 * params.multipliers.height.contour_mult{1} / numel(Z);
  pow = params.multipliers.height.contour_power{1};
  
  C_idx = data.border.idx;
  C_N = data.border.normal;
    
  NZ = [N1(C_idx), N2(C_idx)];
  X = sum(NZ .* C_N,2);
  
  C_loss = max(0, 1-X).^pow;
    
  ep = 10^-3;
  valid = (X < (1-ep)) & (X > (-1+ep));
    
  d_loss_X = mult_normal .* bsxfun(@times, -pow .* valid .* ((1-X).^(pow-1)), C_N);
  
  losses_Z.contour = sum(C_loss);
  loss_Z = loss_Z + mult_normal * losses_Z.contour;
  
  d_loss_N{1} = d_loss_N{1} + reshape(sparse(C_idx, 1, d_loss_X(:,1), numel(Z), 1), size(Z));
  d_loss_N{2} = d_loss_N{2} + reshape(sparse(C_idx, 1, d_loss_X(:,2), numel(Z), 1), size(Z));
  
end






mask = true(size(Z));
mult_slant = params.multipliers.height.slant{1} * (1 / nnz(mask));

X = -log(N3(mask));
epsilon = 0.01;
X_soft = sqrt(X.^2 + epsilon.^2);

losses_Z.slant = sum(X_soft);
loss_Z = loss_Z + mult_slant * losses_Z.slant; % Actual PDF is sum(-log(2*N3(mask)))
d_loss_N{3}(mask) = d_loss_N{3}(mask) + (-mult_slant) .* (X ./ max(eps,X_soft)) ./ max(eps,N3(mask));

d_loss_D1 = (d_loss_N{1} .* dN_Z.F1_1 + d_loss_N{2} .* dN_Z.F2_1 + d_loss_N{3} .* dN_Z.F1_3);
d_loss_D2 = (d_loss_N{1} .* dN_Z.F1_2 + d_loss_N{2} .* dN_Z.F2_2 + d_loss_N{3} .* dN_Z.F2_3);

d_loss_Z = d_loss_Z + conv3d( d_loss_D1, dN_Z.f1) + conv3d( d_loss_D2, dN_Z.f2);


