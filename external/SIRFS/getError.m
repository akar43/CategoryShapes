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


function [err, us, Lv_us, Lv_gt] = getError(us, gt)

V = ~isnan(us.height) & ~isnan(gt.height) & ~any(isnan(us.shading),3) & ~any(isnan(gt.shading),3) & ~any(isnan(us.reflectance),3) & ~any(isnan(gt.reflectance),3) & ~any(isnan(us.normal),3) & ~any(isnan(gt.normal),3);
V(:,[1,end]) = false;
V([1,end],:) = false;

V3 = repmat(V,[1,1,size(us.shading,3)]);  

errs_grosse = nan(1, size(us.shading,3));
assert(size(us.shading,3) == size(us.reflectance,3))
for c = 1:size(us.shading,3)
  errs_grosse(c) = 0.5 * MIT_mse(us.shading(:,:,c), gt.shading(:,:,c), V) + 0.5 * MIT_mse(us.reflectance(:,:,c), gt.reflectance(:,:,c), V);
end
err.grosse = mean(errs_grosse);

alpha_shading = sum(gt.shading(V3) .* us.shading(V3), 1) ./ max(eps, sum(us.shading(V3) .* us.shading(V3)));
S = us.shading * alpha_shading;

alpha_reflectance = sum(gt.reflectance(V3) .* us.reflectance(V3), 1) ./ max(eps, sum(us.reflectance(V3) .* us.reflectance(V3)));
A = us.reflectance * alpha_reflectance;

err.shading = mean((S(V3) - gt.shading(V3)).^2);
err.reflectance = mean((A(V3) - gt.reflectance(V3)).^2);

us.shading = S;
us.reflectance = A;


d = us.normal .* gt.normal;
d = reshape(d, [], 3);
d = d(all(~isnan(d),2),:);
err.normal = mean(acos(min(1,sum(d,2))));



Lv_gt = visSH_color(gt.light, [256,256]);
Lv_us = visSH_color(us.light, [256,256]);

VL = ~isnan(Lv_gt);
alpha_light = sum(Lv_gt(VL) .* Lv_us(VL), 1) ./ max(eps, sum(Lv_us(VL) .* Lv_us(VL),1));
Lv_us = Lv_us * alpha_light;

err.light = mean((Lv_us(VL) - Lv_gt(VL)).^2);


v = ~isnan(gt.height);
x = us.height(v);
y = gt.height(v);
shift = median(x - y);
assert(~any(isnan(shift)))
x = x - shift;
err.height = mean(abs(x - y));


errs = [];
criteria = {'height', 'light', 'normal', 'reflectance', 'shading', 'grosse'};
for s = criteria
  if err.(s{1}) > 10^-10 % Assume perfect, and therefore given
    errs(end+1) = err.(s{1});
  end
end
err.avg = exp(mean(log(errs)));

