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


function A = conv2mat(sz, Fm)

F = reshape(Fm(end:-1:1), size(Fm));

[i0, j0] = find(true(sz));
idx0 = sub2ind(sz, i0, j0);

idxs = {};
fs = {};
for oi = 1:size(F,1)
  for oj = 1:size(F,2)
    
    f = F(oi,oj);
    if f == 0
      continue;
    end
    
    i = i0 + (oi-1);
    j = j0 + (oj-1);
    
    keep = (i <= sz(1)) & (j <= sz(2));
    idx = sub2ind(sz, i(keep), j(keep));
    idxs{end+1} = nan(size(idx0));
    idxs{end}(keep) = idx;
    fs{end+1} = f;
%     m = length(idx);
%     sparse(1:m, idx0, 1, m, n) - sparse(1:m, idx_curve(:,1), 1, m, n) - sparse(1:m, idx_curve(:,3), 1, m, n)
%     [idx0(keep), idx, F(oi,oj)
  end
end
idxs = cat(2,idxs{:});
idxs = idxs(all(~isnan(idxs),2),:);

n = prod(sz);
m = size(idxs,1);
A = sparse(0);
for j = 1:size(idxs,2)
  A = A + sparse(1:m, idxs(:,j), fs{j}, m, n);
end


end