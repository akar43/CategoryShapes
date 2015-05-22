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


function [F, LL, loss_smooth] = smoothHist1_fit(X, bin_low, bin_high, lambda_smooth, robust_cost)

addpath(genpath('./minFunc_2012'));

X_splat = splat1(X, bin_low, bin_high);
X_splat.N = X_splat.N ./ sum(X_splat.N(:));

W = zeros(size(X_splat.N));

filt = [1;3;3;1]/4;
edges = 'repeat';

pyramid_meta = buildGpyr1_matrix_meta(length(W), floor(log2(length(W))-1), filt, edges);
Wpyr = zeros(size(pyramid_meta.Ac,1),1);

N_ITERS = 5000;
OPTIONS = struct('Method', 'lbfgs', 'MaxFunEvals', 10*N_ITERS, 'MaxIter', N_ITERS, 'Corr', 50, 'F_STREAK', 5, 'F_PERCENT', 0.001);
for ii = 1:5
  Wpyr = minFunc('lossfun_hist1', Wpyr, OPTIONS, X_splat, lambda_smooth, robust_cost, pyramid_meta);
end


W = pyramid_meta.AcT * Wpyr;

% W = convn(padarray(W, [1,1,1], 'replicate'), ones(2,2,2)/8);
% W = W(2:end-1, 2:end-1, 2:end-1);

P = exp(-W);
Z = X_splat.bin_area*sum(P(:));
P = P ./ Z;
F = -log(P);
LL = -F;

% F = F - min(F(:));

% visualizeDEM_3D(X_splat.bin_range_low(1) : X_splat.bin_width : X_splat.bin_range_high(1), X_splat.bin_range_low(2) : X_splat.bin_width : X_splat.bin_range_high(2), F)
