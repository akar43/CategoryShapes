% Copyright �2013. The Regents of the University of California (Regents).
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


function out = visualizeDEM(Z, range, contrast)

% if nargin < 3
%   contrast = 0.75;
% end

N = getNormals_conv(Z);

if nargin < 2
  pad_percent = 0;
  range = prctile(Z(~isnan(Z)), [pad_percent, 100-pad_percent]);
end

Z = (Z - range(1))./max(eps,range(2) - range(1));
Z2 = min(1, max(0, Z));
Z2(isnan(Z)) = nan;
Z = Z2;
Z = mod(.75 - Z * .75, 1);
% Z = Z - min(Z(:));

S = N(:,:,3);
% S = (S - min(S(:)))./max(eps,max(S(:)) - min(S(:)));
% S = S*contrast + (1-contrast);



% keyboard

vis = max(0, min(1, hsv2rgb(cat(3, Z, ones(size(S))*.75, S))));


% [i,j] = ndgrid(1:size(Z,1), 1:size(Z,2));
% check = (mod(i, 64) >= 32) ~= (mod(j, 64) >= 32);
% gray = repmat(check/5+3/5, [1,1,3]);
% iv = repmat(isnan(N(:,:,3)), [1,1,3]);
% vis(iv) = gray(iv);

if nargout == 0
  imagesc(vis);
  imtight;
else
  out = vis;
end
