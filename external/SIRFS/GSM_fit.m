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


function [model] = GSM_fit(data, K, HALF_GAUSSIAN)

if nargin < 3
  HALF_GAUSSIAN = 0;
end
  

N_ITERS = 200;

if K == 1
  x = 0;
else
  x = (-(K-1)/2 : (K-1)/2) / ((K-1)/2);
end

clear model;
if HALF_GAUSSIAN == 1
  model.mu = 0;
else
  model.mu = 0;%median(data);
end
% sig = max(abs(data - model.mu))/10;
% model.sigs = sig .* (30.^(3*x));
% model.sigs = mean(abs(data - model.mu)) * sqrt(200.^(x-0.15));
% model.sigs = prctile((data - model.mu).^2, [2.5:5:97.5]);
% K = 20;

if K == 1
  model.sigs = sqrt(mean((data - model.mu).^2));
else
  m = mean(abs(data - model.mu))/1000;
  M = 3*max(abs(data - model.mu));

  model.sigs = exp(log(m) : ((log(M) - log(m)) / (K-1)) : log(M));
  
%   step = 100/(K);
%   model.sigs = prctile(abs(data - model.mu), [step : step : 100]);
%   model.sigs = 2*sqrt(prctile((data - model.mu).^2, [1:(98/(K-1)):99]));
end

% model.sigs = prctile((data - model.mu).^2, 100*(2.^[-10:.1:0]));
K = length(model.sigs);

model.pis = ones(1, K);
model.pis = model.pis / sum(model.pis);

M = max(abs(data(:)))/2;
queue = [-M, 0, M];

Ps = zeros(length(data), K);
for iter = 1:N_ITERS
  
  data_norm = (data - model.mu);
  for k = 1:K
    Ps(:,k) = model.pis(k) * normpdf(data_norm, 0, model.sigs(k));
  end
  
  tau = bsxfun(@rdivide, Ps, max(eps,sum(Ps,2)));%Ps ./ repmat(max(eps,sum(Ps,2)), 1, size(Ps,2));
  sum_tau = sum(tau,1);

%   if HALF_GAUSSIAN == 0
%     params = struct('field', 'mu', 'scale', 'linear', 'queue', queue, 'x_thresh', 10^-3);
%     [model, trace] = minimize_binary(model, 'lossfun_GSM_mu', params, data);
%     fprintf('%d: %f\n', iter, -min(trace(:,2)));
%   else
    fprintf('%d: %f\n', iter, sum(log(sum(Ps,2))));
%   end
    
%   mus = (data' * tau) ./ max(eps,sum_tau);
% 
%   if HALF_GAUSSIAN
%     model.mu = 0;
%   else
%     model.mu = sum(mus .* model.pis);
%   end
  
  model.pis = sum_tau / size(tau,1);

end


n_bins = 20000;


if HALF_GAUSSIAN == 1
  
  n_bins = round(n_bins / 2);
  
  bin_range = [0, max(abs(data))];
  bin_width = (bin_range(2) - bin_range(1))/(n_bins-1);
  
  bins = [0 : bin_width : bin_range(2)]';
  LL_bin = GSM_pdf(model, bins, 0);
  LL_bin = LL_bin + log(2);
  
  bin_width2 = (bin_range(2) - bin_range(1))/(length(data)/40);
  bins2 = bin_range(1):bin_width2:bin_range(2);
  n = double(hist(data, bins2));
  n = n ./ (bin_width2*sum(n));
  n2 = nan(size(n));
  n2(n>0) = log(n(n>0));
  plot(bins2,n2, 'r-', 'linewidth', 1); hold on;
  plot(bins,LL_bin, 'b-', 'linewidth', 1); hold off;
  drawnow;
  
  LL_norm = LL_bin - log(2) - GSM_pdf(model, model.mu, 0);

  
else
  
  width = prctile(abs(data - model.mu),100);
  bin_range = [model.mu - width, model.mu + width];

  bin_width = (bin_range(2) - bin_range(1))/(n_bins-1);
  bins = [bin_range(1):bin_width:bin_range(2)]';


  [LL_bin] = GSM_pdf(model, bins, 0);
  N = hist(data, bins);
  N = N ./ (sum(N) * bin_width);
  valid = N>0;
  N(valid) = log(N(valid));
  N(~valid) = nan;

  figure(1001); clf;
  plot(bins, N, 'r-', 'linewidth', 1); hold on;
  plot(bins, LL_bin, 'b-', 'LineWidth', 1); hold off;
  axis square
  hold off;
  drawnow;
  
  LL_norm = LL_bin - GSM_pdf(model, model.mu, 0);

  
end

model.lut.bin_range = bin_range;
model.lut.bin_width = bin_width;
model.lut.n_bins = n_bins;
model.lut.F_LL = LL_bin;
model.lut.F_cost = -LL_norm;
model.lut.N_train = uint32(hist(data, bins));
