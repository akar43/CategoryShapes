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


function B = getBorderNormals(V)

d = 5;

B = (conv2(double(~V), [0,1,0;1,1,1;0,1,0], 'same') > 0) & V;
[Bi, Bj] = find(B);
P = [Bi, Bj];

[x,y] = meshgrid(-d:d, -d:d);
gaussian = exp(-5 * (x.^2 + y.^2) / (d.^2));

P = P(all(bsxfun(@le, (P + d), size(V)) & bsxfun(@ge, (P - d), 1),2),:);

N = nan(size(P,1), 2);
for i = 1:size(P,1)
  
  patch = V(P(i,1) + [-d:d], P(i,2) + [-d:d]);
  
  [ii, jj] = find(patch);
  a = zeros(numel(patch), numel(patch));
  a(patch(:), patch(:)) = (bsxfun(@minus, ii, ii').^2 + bsxfun(@minus, jj, jj').^2) <= 2;
  
  patch = patch .* gaussian;
  [patch_i,patch_j, v] = find(patch);
  patch_i = patch_i - (d+1);
  patch_j = patch_j - (d+1);
  n = -[mean(patch_i.*v), mean(patch_j.*v)];
  n = n ./ sqrt(sum(n.^2));
  N(i,:) = n;
  
end

T = [-N(:,2), N(:,1)];


clear B;
B.idx = sub2ind(size(V), P(:,1), P(:,2));
B.position = P;
B.normal = N;
B.tangent = T;

