function [fnamesNoFlip] = removeFlipNames( fnamesAll )
%REMOVEFLIPNAMES Summary of this function goes here
%   Detailed explanation goes here

fnamesNoFlip = {};
for i=1:length(fnamesAll)
    s = fnamesAll{i};
    if(~strcmp(s(1:4),'flip'))
        fnamesNoFlip{end+1} = s;
    end
end


end

