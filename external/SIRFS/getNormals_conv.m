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


function [N, dN_Z, n1, n2] = getNormals_conv(Z)

getNormals_filters

n1 = conv3(Z, f1m);
n2 = conv3(Z, f2m);
% n1 = conv2(Z, f1m, 'same');
% n2 = conv2(Z, f2m, 'same');
N3 = 1./sqrt(n1.^2 + n2.^2 + 1);

N1 = n1 .* N3;
N2 = n2 .* N3;

N = cat(3, N1, N2, N3);

if nargout >= 2
  
  N123 = -(N1.*N2.*N3);
  N3sq = N3.^2;

  dN_Z.F1_1 = (1 - N1.*N1).*N3;
  dN_Z.F1_2 = N123;
  dN_Z.F1_3 = -N1.*N3sq;
  
  dN_Z.F2_1 = N123;
  dN_Z.F2_2 = (1 - N2.*N2).*N3;
  dN_Z.F2_3 = -N2.*N3sq;

  dN_Z.f1 = f1;
  dN_Z.f2 = f2;
  
end

