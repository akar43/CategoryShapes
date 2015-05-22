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


function [loss, d_loss_Fpyr] = lossfun_hist3(Fpyr, X_splat, lambda_smooth, robust_cost, pyr_meta)

F = pyr_meta.AcT * Fpyr;

P = exp(-F);
Z = sum(P(:));
logZ = log(Z);
d_logZ = -P ./ max(eps,sum(P(:)));
loss_data = sum(sum(F .* X_splat.N)) + logZ;

loss = loss_data;
d_loss_F = X_splat.N + d_logZ;

f = [1; -2; 1];

Jxx = convn(F, f, 'valid');

mult = lambda_smooth/numel(F);

J = Jxx.^2;

if robust_cost
  
  sqrt_J = sqrt(J + 0.00001);
  loss_smooth = mult * sum(sqrt_J(:));
  loss = loss + loss_smooth;
  
  d_Jxx = convn(Jxx./sqrt_J, f(end:-1:1), 'full');
  
else
  
  loss_smooth = mult * 0.5*sum(J(:));
  loss = loss + loss_smooth;
  
  d_Jxx = convn(Jxx, f(end:-1:1), 'full');
  
end

d_loss_F = d_loss_F + mult * d_Jxx;

d_loss_Fpyr = pyr_meta.Ac * d_loss_F;


global last_display
if isempty(last_display) || (etime(clock, last_display) > .1)
  last_display = clock;
  plot(F); drawnow;
end
