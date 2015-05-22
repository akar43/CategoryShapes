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


function X_splat = splat3(X, bin_range_low, bin_range_high)

N_BINS = 100;

X_splat.valid = bsxfun(@gt, X, bin_range_low + 10*eps) & bsxfun(@lt, X, bin_range_high - 10*eps);

X = bsxfun(@max, bin_range_low + 10*eps, X);
X = bsxfun(@min, bin_range_high - 10*eps, X);

X_splat.span = max(bin_range_high - bin_range_low);
X_splat.n_bins = N_BINS;
X_splat.bin_width = X_splat.span / (X_splat.n_bins+1);

X_splat.bin_area = X_splat.bin_width^3;

X_splat.dims = 1+ceil((bin_range_high - bin_range_low)/X_splat.bin_width);

X_splat.bin_range_low = bin_range_low;
X_splat.bin_range_high = bin_range_high;

dX = bsxfun(@minus, X, bin_range_low) / X_splat.bin_width + 1;
before = min(floor(dX), X_splat.n_bins+1);

X_splat.f2 = dX - before;
X_splat.f1 = 1 - X_splat.f2;

d1 = uint32(X_splat.dims(1));
d2 = uint32(X_splat.dims(1)*X_splat.dims(2));

X_splat.idx122 = uint32(before * double([1; d1; d2]));
X_splat.idx121 = X_splat.idx122 - d2;

X_splat.idx222 = X_splat.idx122 + 1;
X_splat.idx221 = X_splat.idx222 - d2;

X_splat.idx112 = X_splat.idx122 - d1;
X_splat.idx111 = X_splat.idx112 - d2;

X_splat.idx212 = X_splat.idx222 - d1;
X_splat.idx211 = X_splat.idx212 - d2;

f11f12 = X_splat.f1(:,1) .* X_splat.f1(:,2);
f11f22 = X_splat.f1(:,1) .* X_splat.f2(:,2);
f21f12 = X_splat.f2(:,1) .* X_splat.f1(:,2);
f21f22 = X_splat.f2(:,1) .* X_splat.f2(:,2);

sz = [prod(X_splat.dims),1];

X_splat.N =             accumarray(X_splat.idx111, f11f12.*X_splat.f1(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx121, f11f22.*X_splat.f1(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx211, f21f12.*X_splat.f1(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx221, f21f22.*X_splat.f1(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx112, f11f12.*X_splat.f2(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx122, f11f22.*X_splat.f2(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx212, f21f12.*X_splat.f2(:,3), sz);
X_splat.N = X_splat.N + accumarray(X_splat.idx222, f21f22.*X_splat.f2(:,3), sz);
X_splat.N = reshape(X_splat.N, X_splat.dims);

% X_splat.half_width = min(X_splat.n_bins, ceil(N_SIGMAS * sigma / X_splat.bin_width));


if nargout == 0
  imagesc([mean(X_splat.N,3), squeeze(mean(X_splat.N,2)); squeeze(mean(X_splat.N,1))', nan(size(X_splat.N,3), size(X_splat.N,3))].^(1/8)); imtight; drawnow;
end





% function X_splat = splat3(X, sigma, bin_range_low, bin_range_high)
% 
% ACCURACY = 10; % Higher is better, 20 is probably overkill
% N_SIGMAS = 6; % Higher is better, >6 is probably overkill
% 
% N_BINS_MAX = 50;
% N_BINS_MIN = 10;
% 
% X_splat.valid = bsxfun(@gt, X, bin_range_low + 10*eps) & bsxfun(@lt, X, bin_range_high - 10*eps);
% 
% X = bsxfun(@max, bin_range_low + 10*eps, X);
% X = bsxfun(@min, bin_range_high - 10*eps, X);
% 
% X_splat.span = max(bin_range_high - bin_range_low);
% X_splat.n_bins = max(N_BINS_MIN, min(N_BINS_MAX, (ceil(ACCURACY * X_splat.span / sigma))));
% X_splat.bin_width = X_splat.span / (X_splat.n_bins+1);
% 
% X_splat.bin_area = X_splat.bin_width^3;
% 
% X_splat.dims = 1+ceil((bin_range_high - bin_range_low)/X_splat.bin_width);
% 
% X_splat.bin_range_low = bin_range_low;
% X_splat.bin_range_high = bin_range_high;
% 
% dX = bsxfun(@minus, X, bin_range_low) / X_splat.bin_width + 1;
% before = min(floor(dX), X_splat.n_bins+1);
% 
% X_splat.f2 = dX - before;
% X_splat.f1 = 1 - X_splat.f2;
% 
% d1 = uint32(X_splat.dims(1));
% d2 = uint32(X_splat.dims(1)*X_splat.dims(2));
% 
% X_splat.idx122 = uint32(before * double([1; d1; d2]));
% X_splat.idx121 = X_splat.idx122 - d2;
% 
% X_splat.idx222 = X_splat.idx122 + 1;
% X_splat.idx221 = X_splat.idx222 - d2;
% 
% X_splat.idx112 = X_splat.idx122 - d1;
% X_splat.idx111 = X_splat.idx112 - d2;
% 
% X_splat.idx212 = X_splat.idx222 - d1;
% X_splat.idx211 = X_splat.idx212 - d2;
% 
% f11f12 = X_splat.f1(:,1) .* X_splat.f1(:,2);
% f11f22 = X_splat.f1(:,1) .* X_splat.f2(:,2);
% f21f12 = X_splat.f2(:,1) .* X_splat.f1(:,2);
% f21f22 = X_splat.f2(:,1) .* X_splat.f2(:,2);
% 
% sz = [prod(X_splat.dims),1];
% 
% X_splat.N =             accumarray(X_splat.idx111, f11f12.*X_splat.f1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx121, f11f22.*X_splat.f1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx211, f21f12.*X_splat.f1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx221, f21f22.*X_splat.f1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx112, f11f12.*X_splat.f2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx122, f11f22.*X_splat.f2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx212, f21f12.*X_splat.f2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx222, f21f22.*X_splat.f2(:,3), sz);
% X_splat.N = reshape(X_splat.N, X_splat.dims);
% 
% X_splat.half_width = min(X_splat.n_bins, ceil(N_SIGMAS * sigma / X_splat.bin_width));
% 
% 
% if nargout == 0
%   imagesc([mean(X_splat.N,3), squeeze(mean(X_splat.N,2)); squeeze(mean(X_splat.N,1))', nan(size(X_splat.N,3), size(X_splat.N,3))].^(1/8)); imtight; drawnow;
% end






% function X_splat = splat3(X, sigma, bin_range_low, bin_range_high)
% 
% ACCURACY = 10; % Higher is better, 20 is probably overkill
% N_SIGMAS = 6; % Higher is better, >6 is probably overkill
% 
% N_BINS_MAX = 50;
% N_BINS_MIN = 10;
% 
% X_splat.bin_range_low = bin_range_low;
% X_splat.bin_range_high = bin_range_high;
% 
% X_splat.valid = bsxfun(@gt, X, bin_range_low + 10*eps) & bsxfun(@lt, X, bin_range_high - 10*eps);
% 
% X = bsxfun(@max, bin_range_low + 10*eps, X);
% X = bsxfun(@min, bin_range_high - 10*eps, X);
% 
% X_splat.span = max(bin_range_high - bin_range_low);
% X_splat.n_bins = max(N_BINS_MIN, min(N_BINS_MAX, (ceil(ACCURACY * X_splat.span / sigma))));
% X_splat.bin_width = X_splat.span / (X_splat.n_bins+1);
% 
% X_splat.bin_area = X_splat.bin_width^3;
% 
% X_splat.dims = 1+ceil((bin_range_high - bin_range_low)/X_splat.bin_width);
% 
% dX = bsxfun(@minus, X, bin_range_low) / X_splat.bin_width + 1;
% before = min(floor(dX), X_splat.n_bins+1);
% 
% % X_splat.f12 = dX(:,1) - before(:,1);
% % f22 = dX(:,2) - before(:,2);
% % X_splat.f32 = dX(:,3) - before(:,3);
% % f11 = 1-X_splat.f12;
% % f21 = 1-f22;
% % X_splat.f31 = 1-X_splat.f32;
% % 
% % f11f21 = f11.*f21;
% % f11f22 = f11.*f22;
% % X_splat.f12f21 = X_splat.f12.*f21;
% % X_splat.f12f22 = X_splat.f12.*f22;
% 
% 
% X_splat.fX2 = dX - before;
% X_splat.fX1 = 1 - X_splat.fX2;
% 
% f11f21 = X_splat.fX1(:,1) .* X_splat.fX1(:,2);
% f11f22 = X_splat.fX1(:,1) .* X_splat.fX2(:,2);
% X_splat.f12f21 = X_splat.fX2(:,1) .* X_splat.fX1(:,2);
% X_splat.f12f22 = X_splat.fX2(:,1) .* X_splat.fX2(:,2);
% 
% % idx1 = before(:,1);
% % idx2 = idx1+1;
% % 
% % after2d = before(:,2) * X_splat.dims(1);
% % 
% % idx12 = idx1 + after2d;
% % idx11 = idx12 - X_splat.dims(1);
% % idx22 = idx2 + after2d;
% % idx21 = idx22 - X_splat.dims(1);
% % 
% % after3d = before(:,3) * (X_splat.dims(1)*X_splat.dims(2));
% % 
% % X_splat.idx112 = idx11 + after3d;
% % X_splat.idx111 = X_splat.idx112 - (X_splat.dims(1)*X_splat.dims(2));
% % 
% % X_splat.idx122 = idx12 + after3d;
% % X_splat.idx121 = X_splat.idx122 - (X_splat.dims(1)*X_splat.dims(2));
% % 
% % X_splat.idx212 = idx21 + after3d;
% % X_splat.idx211 = X_splat.idx212 - (X_splat.dims(1)*X_splat.dims(2));
% % 
% % X_splat.idx222 = idx22 + after3d;
% % X_splat.idx221 = X_splat.idx222 - (X_splat.dims(1)*X_splat.dims(2));
% 
% 
% % d1 = X_splat.dims(1);
% % d2 = (X_splat.dims(1)*X_splat.dims(2));
% % 
% % X_splat.idx122 = before * [1; d1; d2];
% % X_splat.idx222 = X_splat.idx122 + 1;
% % 
% % X_splat.idx112 = X_splat.idx122 - d1;
% % X_splat.idx111 = X_splat.idx112 - d2;
% % 
% % X_splat.idx121 = X_splat.idx122 - d2;
% % 
% % X_splat.idx212 = X_splat.idx222 - d1;
% % X_splat.idx211 = X_splat.idx212 - d2;
% % 
% % X_splat.idx221 = X_splat.idx222 - d2;
% 
% d1 = uint32(X_splat.dims(1));
% d2 = uint32(X_splat.dims(1)*X_splat.dims(2));
% 
% X_splat.idx122 = uint32(before * double([1; d1; d2]));
% X_splat.idx222 = X_splat.idx122 + 1;
% 
% X_splat.idx112 = X_splat.idx122 - d1;
% X_splat.idx111 = X_splat.idx112 - d2;
% 
% X_splat.idx121 = X_splat.idx122 - d2;
% 
% X_splat.idx212 = X_splat.idx222 - d1;
% X_splat.idx211 = X_splat.idx212 - d2;
% 
% X_splat.idx221 = X_splat.idx222 - d2;
% 
% 
% sz = [prod(X_splat.dims),1];
% 
% % X_splat.N = accumarray(X_splat.idx111, f11f21.*X_splat.f31, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx121, f11f22.*X_splat.f31, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx211, X_splat.f12f21.*X_splat.f31, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx221, X_splat.f12f22.*X_splat.f31, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx112, f11f21.*X_splat.f32, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx122, f11f22.*X_splat.f32, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx212, X_splat.f12f21.*X_splat.f32, sz);
% % X_splat.N = X_splat.N + accumarray(X_splat.idx222, X_splat.f12f22.*X_splat.f32, sz);
% % X_splat.N = reshape(X_splat.N, X_splat.dims);
% 
% 
% X_splat.N =             accumarray(X_splat.idx111, f11f21.*X_splat.fX1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx121, f11f22.*X_splat.fX1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx211, X_splat.f12f21.*X_splat.fX1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx221, X_splat.f12f22.*X_splat.fX1(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx112, f11f21.*X_splat.fX2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx122, f11f22.*X_splat.fX2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx212, X_splat.f12f21.*X_splat.fX2(:,3), sz);
% X_splat.N = X_splat.N + accumarray(X_splat.idx222, X_splat.f12f22.*X_splat.fX2(:,3), sz);
% X_splat.N = reshape(X_splat.N, X_splat.dims);
% 
% X_splat.half_width = min(size(X_splat.N,1), ceil(N_SIGMAS * sigma / X_splat.bin_width));
% 
% 
% if nargout == 0
%   imagesc([mean(X_splat.N,3), squeeze(mean(X_splat.N,2)); squeeze(mean(X_splat.N,1))', nan(size(X_splat.N,3), size(X_splat.N,3))].^(1/8)); imtight; drawnow;
% end
% 
