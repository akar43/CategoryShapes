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


function [loss_A, d_loss_A] = priorA(A, data, params)

if size(A,3) == 1

  loss_A = 0;
  d_loss_A = zeros(size(A));
  
  mult_smooth = params.multipliers.reflectance.smooth{1} * (3/((params.A_MEDIAN_HALFWIDTH*2+1)^2))/numel(A);  
  
  if mult_smooth ~= 0
    
    M = data.A_median_filter_mat;
    M_T = data.A_median_filter_mat_T;
    
    model = data.prior.reflectance.gray.MA.GSM;
    
    MA = M*A(:);
    
    [L, dL] = interp1_fixed_sum_fast(MA, model.lut.bin_range(1), model.lut.bin_width, model.lut.F_cost);
    
    loss_A = loss_A + (mult_smooth) * sum(L(:));
    
    d_loss_A = d_loss_A + (mult_smooth) * reshape((M_T * dL), size(A));
    
  end
  
  
  mask = data.valid;
  Av = A(mask);
  
  d_loss_Av = zeros(size(Av));
  
  mult_entropy = params.multipliers.reflectance.entropy{1};  
  mult_hist = params.multipliers.reflectance.hist{1} / (8*size(Av,1));
  
  if (mult_entropy ~= 0) || (mult_hist ~= 0)
    
    low =  data.prior.reflectance.gray.A_range(1);
    high = data.prior.reflectance.gray.A_range(2);
      
    dV = 0;
    A_splat = splat1(Av, low, high);
    
    sigma = params.multipliers.reflectance.entropy_sigma{1}/20;
    
    if mult_entropy ~= 0
      
      [v, dv] = renyi1_fixed_sub(Av, A_splat, sigma, 2);
      
      loss_A = loss_A + mult_entropy * v;
      dV = dV + mult_entropy * dv;
      
    end
    
    if mult_hist ~= 0
      
      F = data.prior.reflectance.gray.A_spline;
      v = sum(sum(sum(F .* A_splat.N)));
      dv = F;
      
      loss_A = loss_A + mult_hist * v;
      dV = dV + mult_hist * dv;
      
    end

    d_loss_Av = d_loss_Av + splat1_backprop(dV, A_splat);
  
  end
  
  d_loss_A(mask) = d_loss_A(mask) + d_loss_Av(:);
  
else
  
  d_loss_A = zeros(size(A));
  
  mult_smooth = params.multipliers.reflectance.smooth{1};
  mult_mod_smooth = (3/((params.A_MEDIAN_HALFWIDTH*2+1)^2))/numel(A);
  
  
  if mult_smooth ~= 0
    
    M = data.A_median_filter_mat;
    M_T = data.A_median_filter_mat_T;
    
    model = data.prior.reflectance.color.MA.GSM_mvn;
    
    W = model.Sigma_whiten;
    
    Av = reshape(A, [], 3)';
    WAv = W*Av;
    MAW = WAv * M_T;
    mahal_dist = 0.5 * sum(MAW.^2,1)';
    
    epsilon = params.A_SMOOTH_EPSILON{1};
    if epsilon > 0
      mahal_dist_soft = sqrt(mahal_dist.^2 + epsilon.^2);
    else
      mahal_dist_soft = mahal_dist;
    end
    
    F = model.LL_zero - model.lut.F;
    [LL, dLL_dist] = interp1_fixed_sum_fast(mahal_dist_soft, model.lut.bin_range(1), model.lut.bin_width, F);
    
    if epsilon > 0
      dLL_dist = dLL_dist .* (mahal_dist ./ max(eps,mahal_dist_soft));
    end
    
    dLL = (M_T * bsxfun(@times, dLL_dist, MAW')) * W;
    
    losses_A.smooth = mult_mod_smooth * sum(LL(:));
    
    d_loss_A = d_loss_A + (mult_mod_smooth * mult_smooth) * reshape(dLL, size(A));
    
    
  else
    losses_A.smooth = 0;
  end
  
  
  
  mask = data.valid;
  mask_rep = repmat(mask, [1,1,3]);
  
  Av = reshape(A(mask_rep), [], 3);
  d_loss_Av = zeros(size(Av));
  
  mult_entropy = params.multipliers.reflectance.entropy{1};
  mult_mod_entropy = 1;
  
  mult_hist = params.multipliers.reflectance.hist{1};
  mult_mod_hist = 1 / (8*size(Av,1));
  
  if (mult_entropy ~= 0) || (mult_hist ~= 0)
    
    sigma = params.multipliers.reflectance.entropy_sigma{1}/20;
    C = data.prior.reflectance.color.A_whiten;
    
    Av_white = Av * C;
    
    low =  data.prior.reflectance.color.bin_low;
    high = data.prior.reflectance.color.bin_high;
    
    dV = 0;
    A_splat = splat3_fast_wrapper(Av_white, low, high);
    
    if mult_entropy ~= 0
      [v, dv] = renyi3_fixed_sub(Av_white, A_splat, sigma, 2);
      
      losses_A.entropy = mult_mod_entropy * v;
      dV = dV + (mult_mod_entropy * mult_entropy) * dv;
      
    else
      losses_A.entropy = 0;
    end
    
    if mult_hist ~= 0
      
      F = data.prior.reflectance.color.Aw_hist;
      v = sum(sum(sum(F .* A_splat.N)));
      dv = F;
      
      losses_A.hist = mult_mod_hist * v;
      dV = dV + (mult_mod_hist * mult_hist) * dv;
      
    else
      losses_A.hist = 0;
    end
    
    d_loss_Av = d_loss_Av + splat3_backprop_fast_wrapper(dV, A_splat) * C;
    
  else
    losses_A.entropy = 0;
    losses_A.hist = 0;
  end
  
  
  loss_A = mult_smooth * losses_A.smooth + mult_entropy * losses_A.entropy + mult_hist * losses_A.hist;
  
  d_loss_A(mask_rep) = d_loss_A(mask_rep) + d_loss_Av(:);
  
end
