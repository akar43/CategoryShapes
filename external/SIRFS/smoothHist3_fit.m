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


function [F, LL] = smoothHist3_fit(RGB, bin_low, bin_high, lambda_smooth, robust_cost)

X_splat = splat3(RGB, bin_low, bin_high);
X_splat.N = X_splat.N ./ sum(X_splat.N(:));

pyrFilt = [1;4;6;4;1]/8;

W = zeros(size(X_splat.N));
Wpyr = buildGpyr3_simple(W, 6, pyrFilt);

lambda_pos = 0;%1000000;

% checkgrad(Wpyr, 'lossfun_hist3', 10^-5, X_splat, lambda_smooth, lambda_pos, pyrFilt);

N_ITERS = 5000;
OPTIONS = struct('Method', 'lbfgs', 'MaxFunEvals', 10*N_ITERS, 'MaxIter', N_ITERS, 'Corr', 50, 'F_STREAK', 5, 'F_PERCENT', 0.001);
for ii = 1:2
  Wpyr = minFunc('lossfun_hist3', Wpyr, OPTIONS, X_splat, lambda_smooth, lambda_pos, robust_cost, pyrFilt);
end

W = reconLpyr3_simple(Wpyr, pyrFilt);

% W = convn(padarray(W, [1,1,1], 'replicate'), ones(2,2,2)/8);
% W = W(2:end-1, 2:end-1, 2:end-1);

P = exp(-W);
Z = X_splat.bin_area*sum(P(:));
P = P ./ Z;
F = -log(P);
LL = -F;

% F = F - min(F(:));

