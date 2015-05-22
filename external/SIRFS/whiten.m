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



function [X_white, params] = whiten(X, DO_CENTER, V_PAD)
%     [X_white, params] = whiten(X, DO_CENTER)
%
%     X = (X_white * params.inverse) + repmat(params.mean, size(X_white,1),1)
%     X_white = (X - repmat(params.mean, size(X,1),1)) * params.map
    
    if nargin < 2
      DO_CENTER = 1;
    end
    
    if nargin < 3
      V_PAD = .1;
    end

    N_cov = 100000;
    
    X = double(X);
      m = mean(X);
    if ~DO_CENTER
      m = 0*m;
    end
    X_zeroed = X - ones(size(X,1),1)*m;

    s = rand('twister');
    X_sub = X_zeroed(rand(size(X_zeroed,1),1) <= N_cov/size(X_zeroed,1),:);
    C = (X_sub' * X_sub) / size(X_sub,1);
%     C = cov(X_zeroed(rand(size(X_zeroed,1),1) <= N_cov/size(X_zeroed,1),:));
    rand('twister', s);
    
%     while true
%       [V,D] = eig(C);
%       valid = all(D>=0, 1);% & ~any(imag(D),1);
%       if(all(valid))
%         break
%       end
%       fprintf('WHITEN: warning, poorly behaved covariance, correcting...\n');
%       D(~valid,~valid) = -10*D(~valid,~valid);
%       C = V * D * inv(V);
%       C = (C + C')/2;
%     end

    [V,D] = eig(C);
    
    iD = diag(sqrt(1./(diag(D) + V_PAD)));
    map = V * iD * V';

    inverse = inv(map);

    X_white = X_zeroed * map;
    
    params.mean = m;
    params.map = map;
    params.inverse = inverse;
    params.V = V;
    params.iD = iD;
    params.D = D;
    params.C = C;
    params.iC = inv(C);
    
    mag = sqrt(mean(X_white(:).^2));
    params.map = params.map / mag;
    params.inverse = params.inverse * mag;
    X_white = X_white ./ mag;
   
end