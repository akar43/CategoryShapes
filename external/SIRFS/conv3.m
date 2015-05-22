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


function Xc = conv3(X, f)
% pads X repeated values, then convolves by a 3x3 filter

assert(size(f,1) == 3)
assert(size(f,2) == 3)
assert(size(f,3) == 1)

% Equivalent, slower code
% Xp = pad1(X); 
% Xc = conv2(Xp, f, 'valid');

Xc = conv2(X, f, 'same');
Xc(end,:) = Xc(end,:) + conv2(X(end,:), f(1,:), 'same');
Xc(1,:)   = Xc(1,:)   + conv2(X(1,:),   f(end,:), 'same');
Xc(:,end) = Xc(:,end) + conv2(X(:,end), f(:,1), 'same');
Xc(:,1)   = Xc(:,1)   + conv2(X(:,1),   f(:,end), 'same');

Xc(1,1)     = Xc(1,1)     + X(1,1)     .* f(end,end);
Xc(1,end)   = Xc(1,end)   + X(1,end)   .* f(end,1);
Xc(end,1)   = Xc(end,1)   + X(end,1)   .* f(1,end);
Xc(end,end) = Xc(end,end) + X(end,end) .* f(1,1);
