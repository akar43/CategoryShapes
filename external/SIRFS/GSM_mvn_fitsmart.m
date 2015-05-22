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


function model = GSM_mvn_fitsmart(X, K, FIT_MU)

if nargin < 3
  FIT_MU = 0;
end

data = [];
data.X = X;

params = [];
params.USE_NUMERICAL = 1;
params.F_STREAK = 5;
params.F_PERCENT = 0.01;

state = [];

% [Xw, whiten_params] = whiten(X, 0);
% data.X = Xw;

C = (X' * X) / size(X,1);
% [V,D] = eig(C);
%     
% iD = diag(sqrt(1./(diag(D))));
% map = V * iD * V';
d = size(X,2);
map = C \ eye(d,d);
% map = map / (det(map).^(1/size(map,1)));

data.Sigma_map = map;
data.Sigma_imap= inv(map);

% Xw = X * map;
%     
% whiten_params.mean = [0,0,0];
% whiten_params.map = map;
% whiten_params.inverse = inverse;
% whiten_params.V = V;
% whiten_params.iD = iD;
% whiten_params.C = C;
% whiten_params.iC = inv(C);
% 
% 
% if FIT_MU
%   state.mu = mean(X,1);
%   state.Sigma_vec = PSD2vec(cov(Xw));
% else
%   state.Sigma_vec = PSD2vec((Xw'*Xw) / size(Xw,1));
% end
% 
% addpath(genpath('./minFunc_2012'));
% N_ITERS = 5000;
% OPTIONS = struct('Method', 'lbfgs', 'MaxIter', N_ITERS, 'MaxFunEvals', N_ITERS*3, 'Corr', 500, 'F_STREAK', 5, 'F_PERCENT', 0.001, 'numDiff', 1, 'useComplex', 0);
% state = minFunc('GSM_mvn_gradfit_loss', state, OPTIONS, data, params);
% 
% if FIT_MU
%   model.mu = state.mu;
% end
% model.pis = exp(state.log_pis*20);
% model.pis = model.pis ./ sum(model.pis);
% model.Sigma = vec2PSD(state.Sigma_vec);
% model.Sigma = whiten_undo(model.Sigma, whiten_params);
% model.vars = data.vars;


if FIT_MU
  state.mu = mean(X,1);
  C = cov(X);
else
  C = (X'*X) / size(X,1);
end

% keyboard
% C = data.Sigma_map * C;
C = C / (det(C).^(1/size(C,1)));
state.Sigma_vec = PSD2vec(C);

% keyboard
Xi = X * inv(C);
mahal_dist = 0.5 * sum(Xi .* X,2);
  
range = [max(0.00001, prctile(mahal_dist, 0.01)), max(mahal_dist)];
log_range = [log2(range(1)/8), log2(8*range(2))];
vars = 2.^(log_range(1) : ((log_range(2)-log_range(1))/(K-1)) : log_range(2))
% keyboard
% vars = 10000.^((-(K-1)/2 : (K-1)/2) / ((K-1)/2));
data.vars = vars;

pis = ones(size(vars)) / numel(vars);
state.log_pis = zeros(size(pis));


addpath(genpath('./minFunc_2012'));
N_ITERS = 5000;
OPTIONS = struct('Method', 'lbfgs', 'MaxIter', N_ITERS, 'MaxFunEvals', N_ITERS*3, 'Corr', 500, 'F_STREAK', 5, 'F_PERCENT', 0.001, 'numDiff', 1, 'useComplex', 0);
state = minFunc('GSM_mvn_gradfit_loss', state, OPTIONS, data, params);

if FIT_MU
  model.mu = state.mu;
end
model.pis = exp(state.log_pis*20);
model.pis = model.pis ./ sum(model.pis);
model.Sigma = vec2PSD(state.Sigma_vec);
model.Sigma = model.Sigma / (det(model.Sigma).^(1/size(model.Sigma,1)));
% model.Sigma = data.Sigma_imap * model.Sigma;
model.vars = data.vars;



model.Sigma_inv = inv(model.Sigma);
model.Sigma_R = cholcov(model.Sigma,0);
model.logmults = [];

[U, S, V] = svd(model.Sigma_inv);
model.Sigma_whiten = U * sqrt(S) * V';

log_len = log((2*pi).^(size(X,2)/2));
for k = 1:K
  R = model.Sigma_R * sqrt(model.vars(k));
  model.logmults(k) = log(model.pis(k)) - log_len - sum(log(diag(R)));
end


n_bins = 100000;

X_icov = X * model.Sigma_inv;
mahal_dist = 0.5 * sum(X_icov .* X,2);

bin_range = [0, max(mahal_dist)];
bin_width = (bin_range(2) - bin_range(1))/(n_bins-1);
bins = [bin_range(1):bin_width:bin_range(2)]';

P = 0;
p_div = 0;

for k = 1:K
  p = exp(model.logmults(k) + bins./-model.vars(k));
  P = P + p;
  p_div = p_div + p./-model.vars(k);
end

LL_bin = log(P);

model.lut.bin_range = bin_range;
model.lut.bin_width = bin_width;
model.lut.n_bins = n_bins;
model.lut.F = LL_bin;

if FIT_MU
  model.LL_zero = GSM_mvn_pdf(model, model.mu, 1);
else
  model.LL_zero = GSM_mvn_pdf(model, zeros(1, size(data.X,2)), 1);
end

bins = model.lut.bin_range(1) : model.lut.bin_width : model.lut.bin_range(2);


% sqrt_mahal_dist = sqrt(mahal_dist);
% n_hist_bins = size(X,1)/10;
% be = sqrt(bins(end));
% hist_bins = 0:(be/n_hist_bins):be;
% N = hist(sqrt_mahal_dist, hist_bins);
% N = N ./ sum(N);
% 
% logN = nan(size(N));
% logN(N > 0) = log(N(N>0))

figure(1002); clf;
plot(sqrt(bins), LL_bin); hold on;
% plot(hist_bins, logN, 'r-');
xlabel('Mahalanobis Distance');
ylabel('Log-Likelihood');
axis square

