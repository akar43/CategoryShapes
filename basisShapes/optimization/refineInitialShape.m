function [ currShape ] = refineInitialShape(S,fnames)
%REFINEINITSHAPE Summary of this function goes here
%   Detailed explanation goes here
disp('Initializing shape');

%% Parameters
maxiter=10;
maxviolations = 0.02;

%% initializations
numimages = length(fnames);
N = size(S,1);
minScale = zeros(N,1);
maxScale = ones(N,1);

%% Iteration
for iter=1:maxiter
    scale = (minScale+maxScale)/2;
    currShape = repmat(scale,1,3).*S;
    occlusionCount = zeros(N,1);
    for i = 1:numimages
        %if (mod(i,100)==0)
        %    disp([int2str(i) '/' int2str(length(fnames))])
        %end
        load(fnames{i});
        occCount = volumeIntersection(currShape,state);
        occlusionCount = occCount + occlusionCount;
    end
    violations = double(occlusionCount > (maxviolations*numimages));
    minScale = minScale.*violations + scale.*(1-violations);
    maxScale = scale.*violations + maxScale.*(1-violations);
    
end

%% Final shape
scale = (minScale+maxScale)/2;
currShape = repmat(scale,1,3).*S;
end

