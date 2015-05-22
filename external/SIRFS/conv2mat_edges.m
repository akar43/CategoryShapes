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


function A = conv2mat(sz, Fm, edges, skips)

if nargin < 4
  skips = [1, 1];
end

assert(all(sz == round(sz)))

F = reshape(Fm(end:-1:1), size(Fm));

[i0, j0] = ndgrid(1:skips(1):sz(1), 1:skips(2):sz(2));
% [i0, j0] = ndgrid(skips(1):skips(1):sz(1), skips(2):skips(2):sz(2));
i0 = i0(:);
j0 = j0(:);

% [i0, j0] = find(true(sz));
idx0 = sub2ind(sz, i0, j0);

idxs = {};
fs = {};
hw1 = (size(F,1)-1)/2;
hw2 = (size(F,2)-1)/2;
for oi = ceil(-hw1):ceil(hw1)
  for oj = ceil(-hw2):ceil(hw2)
    
    f = F(oi+floor(hw1)+1,oj+floor(hw2)+1);
    if f == 0
      continue;
    end
    
    i = i0 + (oi);
    j = j0 + (oj);
        
    if strcmp(edges, 'zero') || strcmp(edges, 'zero-norm')
      
      keep = (i >= 1) & (j >= 1) & (i <= sz(1)) & (j <= sz(2));
      idx = zeros(size(idx0));
      idx(keep) = sub2ind(sz, i(keep), j(keep));
      
    elseif strcmp(edges, 'repeat')
      
      i = min(max(i, 1), sz(1));
      j = min(max(j, 1), sz(2));
      idx = sub2ind(sz, i, j);
      
    elseif strcmp(edges, 'reflect1')
      
      i(i < 1) = 2 - i(i < 1);
      j(j < 1) = 2 - j(j < 1);
      
      i(i > sz(1)) = 2*sz(1) - i(i > sz(1));
      j(j > sz(2)) = 2*sz(2) - j(j > sz(2));
      
      idx = sub2ind(sz, i, j);
      
    elseif strcmp(edges, 'circular')
      
      i(i < 1) = sz(1) + i(i < 1);
      j(j < 1) = sz(2) + j(j < 1);
      
      i(i > sz(1)) = i(i > sz(1)) - sz(1);
      j(j > sz(2)) = j(j > sz(2)) - sz(2);
      
      idx = sub2ind(sz, i, j);
      
    else
      fprintf('Unknown Edge Type!\n');
      assert(1==0);
    end
    
    
    idxs{end+1} = idx;      
    
    fs{end+1} = f;
%     m = length(idx);
%     sparse(1:m, idx0, 1, m, n) - sparse(1:m, idx_curve(:,1), 1, m, n) - sparse(1:m, idx_curve(:,3), 1, m, n)
%     [idx0(keep), idx, F(oi,oj)
  end
end
idxs = cat(2,idxs{:});
% idxs = idxs(all(~isnan(idxs),2),:);

n = prod(sz);
m = size(idxs,1);
A = sparse(0);
for d = 1:size(idxs,2)
  j = idxs(:,d);
  i = [1:m]';
  A = A + sparse(i(j ~= 0), j(j ~= 0), fs{d}, m, n);
end

if strcmp(edges, 'zero-norm')
  m = sum(Fm) ./ sum(A,2);
  A = sparse(1:length(m), 1:length(m), m) * A;
end

% [Ai, Aj, Av] = find(A);
% [i,j] = ind2sub(sz, Ai);
% keep_i = ~mod(i, 2);
% keep_j = ~mod(j, 2);
% keep = keep_i & keep_j;
% Ai = sub2ind(sz ./ skips, i(keep)/skips(1), j(keep)/skips(2));
% A = sparse(Ai, Aj(keep), Av(keep));
% 
