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


function [X, dX] = PSD2vec(Sigma)

L = chol(Sigma);
% L = cholcov(Sigma);

L_diag_log = log(diag(L));
% L(tril(true(size(L)))) = nan;
% L_triu = L(~isnan(L));
L_triu = L(triu(true(size(L)),1));

X = [L_diag_log; L_triu];

if nargout >= 2
  
  dX = {};
  step = 10^-5;
  for ii = find(triu(ones(size(Sigma))))'
    
    j = ceil(ii / size(Sigma,1));
    i = ii - (j-1) * size(Sigma,1);
%     [i2,j2] = ind2sub(size(Sigma), ii);
%     assert( (i2 == i) && (j2 == j) )
    
    Sigma2 = Sigma;
    Sigma2(i,j) = Sigma(i,j) + step;
    Sigma2(j,i) = Sigma2(i,j);
    X2 = PSD2vec(Sigma2);
    dX{ii} = (X2 - X) / step;
    
    jj = (i-1)*size(Sigma,1) + j;
%     jj2 = sub2ind(size(Sigma), j, i);
%     assert(jj == jj2)
    
    dX{jj} = dX{ii};
  end
  dX = cat(2,dX{:});
  
  assert(size(dX,1) == size(X,1))
  assert(size(dX,2) == numel(Sigma))
  
end