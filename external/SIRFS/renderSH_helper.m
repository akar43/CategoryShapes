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


function [E, dS_dN, dS_dL] = renderSH_helper(N, L)

try
  
  if nargout >= 3
    [E, dS_dN, dS_dL] = renderSH_helper_mex(N, L);
  elseif nargout >= 2
    [E, dS_dN] = renderSH_helper_mex(N, L);
  else
    [E] = renderSH_helper_mex(N, L);
  end
  
catch ME
  fprintf('ERR in renderSH_helper: %s\n', ME.message);
  
  if nargout >= 3
    [E, dS_dN, dS_dL] = renderSH_helper_mat(N, L);
  elseif nargout >= 2
    [E, dS_dN] = renderSH_helper_mat(N, L);
  else
    [E] = renderSH_helper_mat(N, L);
  end
  
end
