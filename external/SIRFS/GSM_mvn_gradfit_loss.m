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


function [loss, d_loss] = GSM_mvn_gradfit_loss(state, data, params)

model = [];
model.pis = exp(state.log_pis*20);
model.pis = model.pis ./ sum(model.pis);
model.Sigma = vec2PSD(state.Sigma_vec);
model.Sigma = model.Sigma / (det(model.Sigma).^(1/size(model.Sigma,1)));
% model.Sigma = data.Sigma_imap * model.Sigma;

model.vars = data.vars;
if isfield(state, 'mu')
  model.mu = state.mu;
end

plot(state.log_pis); drawnow;

loss = -sum(GSM_mvn_pdf(model, data.X));
d_loss = 0;

% try
%   P = 0;
%   for j = 1:length(model.vars)
%     P = P + exp(log(model.pis(j)) + lmvnpdf(data.X, zeros(1, size(data.X,2)), model.Sigma / model.vars(j)));
%   end
%   loss = -sum(log(P));
% catch
%   loss = inf;
% end


% d_loss.log_pis = zeros(size(state.log_pis));
% d_loss.Sigma_vec = zeros(size(state.Sigma_vec));


