function [i] = pascalClassIndex(class)
%PASCALCLASSINDEX Summary of this function goes here
%   Detailed explanation goes here

classes = {'aeroplane','bicycle','bird','boat','bottle','bus','car','cat','chair','cow','diningtable','dog','horse','motorbike','person','plant','sheep','sofa','train','tvmonitor'};
i = find(ismember(classes,{class}));

end