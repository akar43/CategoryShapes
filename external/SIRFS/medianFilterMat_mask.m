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


function A = medianFilterMat(invalid, half_width)

sz = size(invalid);

% width = 2*half_width + 1;
% A = {};
% 
% fs = {};
% for i = -half_width:half_width
%   for j = -half_width:half_width%-half_width:half_width
%     if ((i == 0) && (j == 0))
%       continue
%     end
%     f = zeros(width,width);
%     f(i+half_width+1, j+half_width+1) = -1;
%     f(half_width+1, half_width+1) = 1;
% 
%     f = f(find(any(f,2), 1, 'first') : find(any(f,2), 1, 'last'), find(any(f,1), 1, 'first') : find(any(f,1), 1, 'last'));
%     
%     A{end+1} = conv2mat(sz, f);
%     
%   end
% end
% 
% A = cat(1,A{:});
% 



width = 2*half_width + 1;
fs = {};
for i = -half_width:half_width
  for j = -half_width:half_width%-half_width:half_width
    if ((i == 0) && (j == 0))
      continue
    end
    f = zeros(width,width);
    f(i+half_width+1, j+half_width+1) = -1;
    f(half_width+1, half_width+1) = 1;

%     f = f / 2;
    
    f = f(find(any(f,2), 1, 'first') : find(any(f,2), 1, 'last'), find(any(f,1), 1, 'first') : find(any(f,1), 1, 'last'));
    fs{end+1} = f;
    
  end
end

do_remove = false(length(fs),1);
for i = 1:length(fs)
  for j = (i+1):length(fs)
    C = conv2(abs(fs{i}), abs(fs{j}), 'valid');
    if any(C>=2)
      do_remove(j) = 1;
    end
  end
end

fs = fs(~do_remove);

A = {};
for i = 1:length(fs)
  A{i} = conv2mat(sz, fs{i});
  f = double(fs{i} ~= 0);
  R = reshape(conv2(double(invalid), f, 'valid'), [], 1);
  keep = R == 0;
  A{i} = A{i}(keep,:);
  
%   [x1, y1] = find(f > 0);
%   [x2, y2] = find(f < 0);
%   [x,y] = bresenham([x1, x2], [y1, y2]);
%   fl = full(sparse(y,x, ones(size(x)), size(f,1), size(f,2)));
%   R = reshape(conv2(double(invalid), fl, 'valid'), [], 1);
%   
%   W = (R==0);
%   
%   A{i} = sparse(1:length(W), 1:length(W), W, length(W), length(W)) * A{i};
%   A{i} = A{i}(any(A{i},2),:);
  
end

A = cat(1,A{:});
