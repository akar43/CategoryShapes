function [S2d] = transform2d(S,R,c,tr)
%TRANSFORM2D Summary of this function goes here
%   Detailed explanation goes here

S2d = c*R*S';
S2d = S2d(1:2,:);
S2d(1,:) = S2d(1,:)+tr(1);
S2d(2,:) = S2d(2,:)+tr(2);
S2d = S2d';
end

