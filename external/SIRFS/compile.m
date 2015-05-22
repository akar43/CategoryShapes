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



curdir = pwd;

cd minFunc_2012/mex/
try
mex lbfgsAddC.c
mex lbfgsC.c
mex lbfgsProdC.c
mex mcholC.c
catch
  fprintf('minFunc compile failed\n');
end
cd(curdir)

try
  mex getK_fast.c
catch
  fprintf('getK_fast compile failed\n');
end

try
  mex splat3_fast.c
catch
  fprintf('splat3_fast compile failed\n');
end

try
  mex splat3_backprop_fast.c
catch
  fprintf('splat3_backprop_fast compile failed\n');
end

try
  mex interp1_fixed_sum_fast.c;
catch
  fprintf('interp1_fixed_sum_fast compile failed\n');
end

try
  mex renderSH_helper_mex.c
catch
  fprintf('renderSH_helper_mex compile failed\n');
end
