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


function [out, N, E] = visSH(L, sz, DO_FLIP)

if nargin < 2
  sz = [256,256];
end

min_sz = min(sz);
j = ([1:sz(1)]-min_sz/2 - (sz(1)-min_sz)/2)*(2/min_sz);
i = ([1:sz(2)]-min_sz/2 - (sz(2)-min_sz)/2)*(2/min_sz);
[Y,X] = meshgrid(i,j);
Z = sqrt(max(0, 1-(X.^2 + Y.^2)));
valid = Z ~= 0;

if nargin >= 3 && DO_FLIP
  Z = -Z;
end

N = [X(valid), Y(valid), Z(valid)];
E = renderSH_helper(N, L);

% E = E - min(E(:));
% E = E ./ max(E(:));

% keyboard
% V = [0,0,1];
% R = repmat(2*(N*V'), [1,3]) .* N - repmat(V, size(N,1), 1);
% Es = renderSH_helper(R, L, NO_SHADOW)/2;

% m = max(E(:));
% E = E ./ m;
% E = E.^20;
% E = E * m;
% E = E + E.^50;

vis = nan(size(Z));
vis(valid) = E;% + Es.^30;

if nargout == 0
  imagesc(vis);
  imtight; colormap('gray');
else
  out = vis;
end


