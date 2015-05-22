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


function err = LMSE(X_us, X_true, X_mask)

if nargin < 3
  mask = true(size(X_us));
end

k = 20; % Window Size

X_us(~X_mask) = 0;
X_true(~X_mask) = 0;

% C_true = [im2col(X_true, [k,k], 'distinct'), im2col(X_true(:,(k/2):end), [k,k], 'distinct'), im2col(X_true((k/2):end,:), [k,k], 'distinct'), im2col(X_true((k/2):end,(k/2):end), [k,k], 'distinct')];
% C_us = [im2col(X_us, [k,k], 'distinct'), im2col(X_us(:,(k/2):end), [k,k], 'distinct'), im2col(X_us((k/2):end,:), [k,k], 'distinct'), im2col(X_us((k/2):end,(k/2):end), [k,k], 'distinct')];
% C_mask = [im2col(X_mask, [k,k], 'distinct'), im2col(X_mask(:,(k/2):end), [k,k], 'distinct'), im2col(X_mask((k/2):end,:), [k,k], 'distinct'), im2col(X_mask((k/2):end,(k/2):end), [k,k], 'distinct')];

C_true = [im2col_distinct(X_true, k), im2col_distinct(X_true(:,(k/2):end), k), im2col_distinct(X_true((k/2):end,:), k), im2col_distinct(X_true((k/2):end,(k/2):end), k)];
C_us = [im2col_distinct(X_us, k), im2col_distinct(X_us(:,(k/2):end), k), im2col_distinct(X_us((k/2):end,:), k), im2col_distinct(X_us((k/2):end,(k/2):end), k)];
C_mask = [im2col_distinct(X_mask, k), im2col_distinct(X_mask(:,(k/2):end), k), im2col_distinct(X_mask((k/2):end,:), k), im2col_distinct(X_mask((k/2):end,(k/2):end), k)];

% C_true = im2col(X_true, [k,k], 'distinct');
% C_us = im2col(X_us, [k,k], 'distinct');
% C_mask = im2col(X_mask, [k,k], 'distinct');

C_alpha = sum(C_mask .* C_true .* C_us, 1) ./ max(eps, sum(C_mask .* C_us .* C_us));
numer = sum(C_mask .* (C_true - repmat(C_alpha, size(C_true,1), 1) .* C_us).^2,1);
denom = sum(C_mask .* (C_true.^2),1);
err = sum(numer) ./ sum(denom);



% X_true_bak = X_true;
% X_us_bak = X_us;
% 
% err = 0;
% for offset_i = [0, 1];
%   for offset_j = [0, 1];
%     
%     X_true = X_true_bak;
%     X_us = X_us_bak;
% 
%     X_true = X_true((1+offset_i/2 * k):end, (1+offset_j/2 * k):end);
%     X_us = X_us((1+offset_i/2 * k):end, (1+offset_j/2 * k):end);
%     
%     new_size = floor(size(X_true)/k) * k;
% 
%     X_true = X_true(1:new_size(1), 1:new_size(2));
%     X_us = X_us(1:new_size(1), 1:new_size(2));
% 
%     C_true = im2col(X_true, [k,k], 'distinct');
%     C_us = im2col(X_us, [k,k], 'distinct');
%     C_us = im2col(X_us, [k,k], 'distinct');
% 
%     C_alpha = sum(C_true .* C_us, 1) ./ max(eps, sum(C_us.^2));
%     C_alpha = repmat(C_alpha, size(C_true,1), 1);
%     e = sum(mean((C_true - C_alpha .* C_us).^2,1),2);
%     
%     err = err + e;
% 
%   end
% end
% err = err / 4;
% 
% 
