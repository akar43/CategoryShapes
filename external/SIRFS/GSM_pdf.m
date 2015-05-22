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


function [loglike, d_loglike] = GSM_pdf(model, data, USE_LUT)

RETURN_GRADIENT = (nargout >= 2);

if nargin < 3
  USE_LUT = true;
end

K = length(model.pis);
M = size(data,2);
N = size(data,1);

assert(M == 1)

if USE_LUT && isfield(model, 'lut')
  if RETURN_GRADIENT
    try
      [loglike, d_loglike] = interp1_fixed_sum_fast(data, model.lut.bin_range(1), model.lut.bin_width, model.lut.F_LL);
    catch
      fprintf('executing interp1_fixed_sum_fast failed\n');
      [loglike, d_loglike] = interp1_fixed_sum(data, model.lut.bin_range(1), model.lut.bin_width, model.lut.F_LL);
    end
  else
    try
      [loglike] = interp1_fixed_sum_fast(data, model.lut.bin_range(1), model.lut.bin_width, model.lut.F_LL);
    catch
      fprintf('executing interp1_fixed_sum_fast failed\n');
      [loglike] = interp1_fixed_sum(data, model.lut.bin_range(1), model.lut.bin_width, model.lut.F_LL);
    end
  end
  
else

  P = 0;
  for k = 1:K
    P = P + exp(log(model.pis(k)) + lnormpdf(data, model.mu, model.sigs(k)));%model.pis(k) * normpdf(data, model.mu, model.sigs(k));
  end

  loglike = log(max(exp(-300),P));
  
end
