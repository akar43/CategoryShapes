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


function X_splat = splat1(X, bin_range_low, bin_range_high)

assert(~any(any(any(isnan(X)))))

N_BINS = 254;

X_splat.valid = bsxfun(@gt, X, bin_range_low + 10*eps) & bsxfun(@lt, X, bin_range_high - 10*eps);

X = bsxfun(@max, bin_range_low + 10*eps, X);
X = bsxfun(@min, bin_range_high - 10*eps, X);

X_splat.span = bin_range_high - bin_range_low;
X_splat.n_bins = N_BINS;
X_splat.bin_width = X_splat.span / (X_splat.n_bins+1);

X_splat.bin_area = X_splat.bin_width;

X_splat.dims = 1+ceil((bin_range_high - bin_range_low)/X_splat.bin_width);

X_splat.bin_range_low = bin_range_low;
X_splat.bin_range_high = bin_range_high;

dX = bsxfun(@minus, X, bin_range_low) / X_splat.bin_width + 1;
before = min(floor(dX), X_splat.n_bins+1);

X_splat.f2 = dX - before;
X_splat.f1 = 1 - X_splat.f2;

X_splat.idx1 = uint32(before);
X_splat.idx2 = X_splat.idx1 + 1;

X_splat.N = accumarray(X_splat.idx1, X_splat.f1, [X_splat.dims,1]) + accumarray(X_splat.idx2, X_splat.f2, [X_splat.dims,1]);

