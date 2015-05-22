function [V, dV] = variance_L1(X, dim, ep)
% Computes the L1 "variance" of X in dimension dim, and its gradient

if nargin <= 3
  ep = 0;
end

mu = mean(X, dim);
X_diff = bsxfun(@minus, X, mu);
X_diff = max(0, abs(X_diff) - ep) .* sign(X_diff);
V = mean(abs(X_diff), dim);

n = size(X, dim);
sign_X_diff = sign(X_diff);
dV = bsxfun(@minus, sign_X_diff, sum(sign_X_diff, dim)/n)/n;
