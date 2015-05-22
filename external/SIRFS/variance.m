function [V, dV] = variance(X, dim)
% Computes the variance of X in dimension dim, and its gradient

mu = mean(X, dim);
V = mean(bsxfun(@minus, X, mu).^2, dim);

n = size(X, dim);
dV = bsxfun(@plus, (2/n - 4/n) * mu, 2/n*X);
