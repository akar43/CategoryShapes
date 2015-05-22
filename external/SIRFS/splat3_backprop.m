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


function d_loss_X = splat3_backprop(d_loss_N, X_splat)

d_loss_N = d_loss_N/X_splat.bin_width;

dV111 = d_loss_N(X_splat.idx111);
dV121 = d_loss_N(X_splat.idx121);
dV211 = d_loss_N(X_splat.idx211);
dV221 = d_loss_N(X_splat.idx221);
dV112 = d_loss_N(X_splat.idx112);
dV122 = d_loss_N(X_splat.idx122);
dV212 = d_loss_N(X_splat.idx212);
dV222 = d_loss_N(X_splat.idx222);

d_loss_X = ...
   [   X_splat.f1(:,2).*(X_splat.f1(:,3).*(dV211-dV111) + X_splat.f2(:,3).*(dV212-dV112)) ...
     + X_splat.f2(:,2).*(X_splat.f1(:,3).*(dV221-dV121) + X_splat.f2(:,3).*(dV222-dV122)), ...
       X_splat.f1(:,1).*(X_splat.f1(:,3).*(dV121-dV111) + X_splat.f2(:,3).*(dV122-dV112)) ...
     + X_splat.f2(:,1).*(X_splat.f1(:,3).*(dV221-dV211) + X_splat.f2(:,3).*(dV222-dV212)), ...
       X_splat.f1(:,1).*(X_splat.f1(:,2).*(dV112-dV111) + X_splat.f2(:,2).*(dV122-dV121)) ...
     + X_splat.f2(:,1).*(X_splat.f1(:,2).*(dV212-dV211) + X_splat.f2(:,2).*(dV222-dV221))];

% d_loss_X2 = ...
%    [   X_splat.f1(:,2).*(X_splat.f1(:,3).*(dV211-dV111) + X_splat.f2(:,3).*(dV212-dV112)) ...
%      + X_splat.f2(:,2).*(X_splat.f1(:,3).*(dV221-dV121) + X_splat.f2(:,3).*(dV222-dV122)), ...
%        X_splat.f1(:,1).*(X_splat.f1(:,3).*(dV121-dV111) + X_splat.f2(:,3).*(dV122-dV112)) ...
%      + X_splat.f2(:,1).*(X_splat.f1(:,3).*(dV221-dV211) + X_splat.f2(:,3).*(dV222-dV212)), ...
%        X_splat.f11f12 .* (dV112-dV111) + X_splat.f11f22 .* (dV122-dV121) ...
%      + X_splat.f21f12 .* (dV212-dV211) + X_splat.f21f22 .* (dV222-dV221)];



d_loss_X(~X_splat.valid) = 0;

