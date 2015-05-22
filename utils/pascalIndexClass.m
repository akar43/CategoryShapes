function [class] = pascalIndexClass(c)
%PASCALINDEXCLASS Summary of this function goes here
%   Detailed explanation goes here


classes = {'aeroplane','bicycle','bird','boat','bottle','bus','car','cat','chair','cow','diningtable','dog','horse','motorbike','person','plant','sheep','sofa','train','tvmonitor'};
if(c<1 || c>length(classes))
    class = 'none';
else
    class = classes{c};
end

end

