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


function [loss, d_loss_Fpyr] = lossfun_hist3(Fpyr, X_splat, lambda_smooth, lambda_pos, robust_cost, pyrFilt)

F = reconLpyr3_simple(Fpyr, pyrFilt);

% F = F - max(F(:));

% P = exp(-F);
% Z = X_splat.bin_area*sum(P(:));
% logZ = log(Z);
% d_logZ = -P ./ max(eps,sum(P(:)));
% count = sum(X_splat.N(:));
% loss_data = sum(sum(sum(F .* X_splat.N))) + count * logZ;

P = exp(-F);
% Z = X_splat.bin_area*sum(P(:));
Z = sum(P(:));
logZ = log(Z);
d_logZ = -P ./ max(eps,sum(P(:)));
loss_data = sum(sum(sum(F .* X_splat.N))) + logZ;

loss = loss_data;
d_loss_F = X_splat.N + d_logZ;


% b3 = [ 1, 2, 1]/2;
% l3 = [-1, 2,-1]/2;
% g3 = [ 1, 0,-1];
% 
% g2 = [ 1, -1, 0];
% b2 = [ 1,  1, 0]/2; 
% 
% fs1 = {tensor3(b3, b3, l3), tensor3(b3, l3, b3), tensor3(l3, b3, b3)};
% fs2 = {tensor3(b2, g2, g2), tensor3(g2, g2, b2), tensor3(g2, b2, g2)};
% 
% J = 0;
% Js1 = {};
% Js2 = {};
% for i = 1:3
%   Js1{i} = convn(F, fs1{i}, 'valid');
%   Js2{i} = convn(F, fs2{i}, 'valid');
%   J = J +   Js1{i}.^2;
%   J = J + 2*Js2{i}.^2;
% end
% 
% mult = lambda_smooth;
% 
% sqrt_J = sqrt(J + 0.001);
% loss = loss + mult * sum(sqrt_J(:));
% 
% for i = 1:3
%   d_loss_F = d_loss_F + mult*1*convn(Js1{i}./sqrt_J, reshape(fs1{i}(end:-1:1), [3,3,3]), 'full');
%   d_loss_F = d_loss_F + mult*2*convn(Js2{i}./sqrt_J, reshape(fs2{i}(end:-1:1), [3,3,3]), 'full');
% end




g2 = [ 1, -1];
b2 = [ 1,  1]/2; 

dx = tensor3(g2, b2, b2);
dy = tensor3(b2, g2, b2);
dz = tensor3(b2, b2, g2);

dxx = convn(dx, dx, 'full');
dyy = convn(dy, dy, 'full');
dzz = convn(dz, dz, 'full');
dxy = convn(dx, dy, 'full');
dyz = convn(dy, dz, 'full');
dxz = convn(dx, dz, 'full');

Jxx = convn(F, dxx, 'valid');
Jyy = convn(F, dyy, 'valid');
Jzz = convn(F, dzz, 'valid');
Jxy = convn(F, dxy, 'valid');
Jyz = convn(F, dyz, 'valid');
Jxz = convn(F, dxz, 'valid');

mult = lambda_smooth/numel(F);

J = Jxx.^2 + Jyy.^2 + Jzz.^2 + 2*Jxy.^2 + 2*Jxz.^2 + 2*Jyz.^2;

if robust_cost
  
  sqrt_J = sqrt(J + 0.00001);
  loss = loss + mult * sum(sqrt_J(:));
  
  d_Jxx = convn(Jxx./sqrt_J, reshape(dxx(end:-1:1), [3,3,3]), 'full');
  d_Jyy = convn(Jyy./sqrt_J, reshape(dyy(end:-1:1), [3,3,3]), 'full');
  d_Jzz = convn(Jzz./sqrt_J, reshape(dzz(end:-1:1), [3,3,3]), 'full');
  d_Jxy = convn(Jxy./sqrt_J, reshape(dxy(end:-1:1), [3,3,3]), 'full');
  d_Jyz = convn(Jyz./sqrt_J, reshape(dyz(end:-1:1), [3,3,3]), 'full');
  d_Jxz = convn(Jxz./sqrt_J, reshape(dxz(end:-1:1), [3,3,3]), 'full');

else
  
  loss = loss + mult * 0.5*sum(J(:));
  
  d_Jxx = convn(Jxx, reshape(dxx(end:-1:1), [3,3,3]), 'full');
  d_Jyy = convn(Jyy, reshape(dyy(end:-1:1), [3,3,3]), 'full');
  d_Jzz = convn(Jzz, reshape(dzz(end:-1:1), [3,3,3]), 'full');
  d_Jxy = convn(Jxy, reshape(dxy(end:-1:1), [3,3,3]), 'full');
  d_Jyz = convn(Jyz, reshape(dyz(end:-1:1), [3,3,3]), 'full');
  d_Jxz = convn(Jxz, reshape(dxz(end:-1:1), [3,3,3]), 'full');
  
end

d_loss_F = d_loss_F + mult * (d_Jxx + d_Jyy + d_Jzz + 2*d_Jxy + 2*d_Jxz + 2*d_Jyz);

% d_loss_F = convn(d_loss_F, ones(2,2,2)/8, 'same');


% f = tensor3(l3,l3,l3);
% K = convn(F, f, 'valid');
% 
% % mult = lambda_smooth;
% % % Ksoft = sqrt(K.^2 + 0.0001);
% % % loss = loss + mult * sum(Ksoft(:));
% % % d_loss_K = mult * K ./ Ksoft;
% % 
% % loss = loss + mult * 0.5*sum(K(:).^2);
% % d_loss_K = mult * K;
% 
% 
% mult = lambda_pos;
% below = K < 0;
% loss = loss + mult * 0.5 * sum(K(below).^2);
% d_loss_K = mult*(below .* K);
% 
% d_loss_F = d_loss_F + convn(d_loss_K, f, 'full');

d_loss_Fpyr = buildGpyr3_simple(d_loss_F, length(Fpyr), pyrFilt);

d_loss_Fpyr{1} = zeros(size(d_loss_Fpyr{1}));

global last_time
if (isempty(last_time) || (etime(clock, last_time) > 5))
  last_time = clock;

  P2 = P;%.^(1/8);
  N2 = X_splat.N;%.^(1/8);
  V1 = [mean(P2,3), squeeze(mean(P2,2)); squeeze(mean(P2,1))', nan(size(P2,3), size(P2,3))];
  V2 = [mean(N2,3), squeeze(mean(N2,2)); squeeze(mean(N2,1))', nan(size(N2,3), size(N2,3))];
  
  V1 = V1 - min(V1(:));
  
%   imagesc(log([V1 ./ max(V1(:)), V2 ./ max(V2(:))])); imtight; drawnow;
  figure(8); imagesc([V1 ./ max(V1(:)), V2 ./ max(V2(:))].^(1/8)); imtight;
%   figure(9);
%   [n,x] = hist(J(:), 200);
%   plot(x, log(n+1));
  drawnow;
  
  
end
