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


function [meta] = buildGpyr_matrix_meta(sz, depth, filt, edges, skip)

if nargin < 5
  skip = 2;
end

meta.pind = {sz};
for d = 2:depth
  meta.pind{d} = ceil(meta.pind{d-1}/skip);
end
meta.pind = cat(1, meta.pind{:});

for d = 2:depth
  
  sz = meta.pind(d-1,:);
  sz_down = meta.pind(d,:);
  sz_half = [sz(1), sz_down(2)];
  
  A1 = conv2mat_edges(sz, filt', edges, [1,skip]);
  A2 = conv2mat_edges(sz_half, filt, edges, [skip,1]);
%   A1 = conv2mat_edges(sz, filt', edges, [1,2]);
%   A2 = conv2mat_edges(sz_half, filt, edges, [2,1]);
  A = A2 * A1;
  
  meta.A{d-1} = A;
  meta.AT{d-1} = A';
  
end

Ac = {speye(prod(meta.pind(1,:)), prod(meta.pind(1,:)))};
for s = 1:length(meta.A)
  Ac{s+1} = meta.A{s} * Ac{s};
end
meta.Ac = cat(1,Ac{:});
meta.AcT = meta.Ac';
  