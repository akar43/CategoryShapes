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


function [D, min_idx]=distMat(P1, P2, thresh, interval, conserve_memory)
% squared Euclidian distances between vectors

% P1 = double(P1);
% P2 = double(P2);
% 
% X1=repmat(sum(P1.^2,2),[1 size(P2,1)]);
% X2=repmat(sum(P2.^2,2),[1 size(P1,1)]);
% R=P1*P2';
% D=X1+X2'-2*R;
% return

if nargin >= 3 && ~isempty(thresh)
  do_thresh = 1;
else
  do_thresh = 0;
end

if do_thresh
  D = false(size(P1,1), size(P2,1));
else
  D = zeros(size(P1,1), size(P2,1), class(P1));
end

if nargin < 4
  interval = 500;
end

if nargin < 5
  conserve_memory = 0;
end

persistent X1 X2 R;
if ~conserve_memory
  R=2*P1*P2';
end

last_len = -1;
t_start = cputime;
t_last = t_start;
for i = 1 : interval : size(P1,1)
    rows = i-1 + [1:interval];
    rows = rows(rows <= size(P1,1));

    X1=repmat(sum(P1(rows,:).^2,2),[1 size(P2,1)]);
    if size(X1,1) ~= last_len
        X2=repmat(sum(P2.^2,2),[1 size(X1,1)])';
    end
    last_len = size(X1,1);
    
    if ~conserve_memory
      if do_thresh
        D(rows,:) = (X1+X2-R(rows,:)) <= thresh;
      else
        D(rows,:) = (X1+X2-R(rows,:));
      end
    else
      if do_thresh
        D(rows,:) = (X1+X2-2*P1(rows,:)*P2') <= thresh;
      else
        D(rows,:) = (X1+X2-2*P1(rows,:)*P2');
      end
    end
    
    t = cputime;
    
    if i > 1 && (t - t_last) > 20
      t_last = t;
      fprintf('DISTMAT: %0.2f%% done, %0.1f minutes left\r', i/size(P1,1)*100, (1/60)*(t - t_start)/i*(size(P1,1)-i));
    end
    
end

if nargout >= 2
  D_min = min(D,[],1);
  [i,j] = find(D == repmat(D_min, size(D,1), 1));
  [uu, ui] = unique(j, 'first');
  min_idx = i(ui);
end


end


