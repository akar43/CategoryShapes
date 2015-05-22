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




function [K, dKZ, Zmag, K1, K2, K3] = getK(Z, tap)

getK_filters

if nargin < 2
  tap = GETK_TAP;
end

assert( (tap == 3) || (tap == 5) )

if tap == 5
  Z = conv3(Z, ([1;2;1] * [1,2,1])/12);
end

Zp = pad1(Z);

Zx = conv2(Zp, f1, 'valid');
Zy = conv2(Zp, f2, 'valid');
Zyy = conv2(Zp, f22, 'valid');
Zxx = conv2(Zp, f11, 'valid');
Zxy = conv2(Zp, f12, 'valid');

ZxSq = Zx.^2;
ZySq = Zy.^2;
ZxSq_p = 1 + ZxSq;
ZySq_p = 1 + ZySq;
ZxZy = -2*Zx.*Zy;
ZmagSq = ZxSq_p + ZySq;
Zmag = sqrt(ZmagSq);

denom = max(eps, 2*ZmagSq.*Zmag);
numer = ZxSq_p.*Zyy + ZxZy.*Zxy + ZySq_p.*Zxx;

K = numer ./ denom;

if nargout >= 4
  K1 = (ZxSq_p.*Zyy) ./ denom;
  K2 = (ZySq_p.*Zxx) ./ denom;
  K3 = (ZxZy.*Zxy) ./ denom;
end

if nargout >= 2

  dKZ.denom = denom;
  
  B = 3*(numer./ZmagSq);
  dKZ.f1 = 2*(Zx.*Zyy - Zy.*Zxy) - (Zx.*B);
  dKZ.f2 = 2*(Zy.*Zxx - Zx.*Zxy) - (Zy.*B);
  
  dKZ.f11 = ZySq_p;
  dKZ.f22 = ZxSq_p;
  dKZ.f12 = ZxZy;

end

