function [alpha] = initializeAlpha(S,V,fnames)
%INITIALIZEALPHA Summary of this function goes here
%   Detailed explanation goes here

K = size(V,2);
numimages = length(fnames);

alpha = (rand(K,numimages)-0.5)*0.2;

end