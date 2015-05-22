function [f,g] = autoGrad(x,funObj,varargin)
% [f,g] = autoGrad(x,useComplex,funObj,varargin)
%
% Numerically compute gradient of objective function from function values

p = length(x);
mu = 1e-150;

f = funObj(x,varargin{:});
mu = 2*sqrt(1e-12)*(1+norm(x))/norm(p);
for j = 1:p
  e_j = zeros(p,1);
  e_j(j) = 1;
  diff(j,1) = funObj(x + mu*e_j,varargin{:});
end
g = (diff-f)/mu;

if 0 % DEBUG CODE
    [fReal gReal] = funObj(x,varargin{:});
    [fReal f]
    [gReal g]
    pause;
end