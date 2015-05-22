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


function d_loss_Z = getK_backprop_fast_mat(d_loss_K, dKZ)

getK_filters;

d_loss_K = d_loss_K ./ dKZ(:,:,1);

fs = {f1m, f2m, f11m, f22m, f12m};

d_loss_Z = 0;
for fi = 1:length(fs)
  d_loss_Z = d_loss_Z + conv2(d_loss_K .* dKZ(:,:,fi+1),  fs{fi},  'full');
end
d_loss_Z = unpad1(d_loss_Z);



% function d_loss_Z = getK_backprop(d_loss_K, dKZ)
% 
% getK_filters;
% 
% % d_loss_Kv = d_loss_K(:)' ./ dKZ(1,:);
% % d_loss_Kv = reshape(permute(bsxfun(@times, d_loss_Kv, dKZ(2:end,:)), [2,1]), [size(d_loss_K), 5]);
% % 
% % d_loss_Z = unpad1( ...
% %   conv2(d_loss_Kv(:,:,1),  f1m,  'full') + ...
% %   conv2(d_loss_Kv(:,:,2),  f2m,  'full') + ...
% %   conv2(d_loss_Kv(:,:,3), f11m, 'full') + ...
% %   conv2(d_loss_Kv(:,:,4), f22m, 'full') + ...
% %   conv2(d_loss_Kv(:,:,5), f12m, 'full') );
% 
% 
% 
% dKZ = reshape(permute(dKZ, [2,1]), [size(d_loss_K), 6]);
% 
% d_loss_K = d_loss_K ./ dKZ(:,:,1);
% 
% d_loss_Z = unpad1( ...
%   conv2(d_loss_K .* dKZ(:,:,2),  f1m,  'full') + ...
%   conv2(d_loss_K .* dKZ(:,:,3),  f2m,  'full') + ...
%   conv2(d_loss_K .* dKZ(:,:,4), f11m, 'full') + ...
%   conv2(d_loss_K .* dKZ(:,:,5), f22m, 'full') + ...
%   conv2(d_loss_K .* dKZ(:,:,6), f12m, 'full') );
% 
