function [dataPreds] = computePosePredictions(data)
%COMPUTEPOSEPREDICTIONS Summary of this function goes here
%   Detailed explanation goes here

feat = vertcat(data(:).poseFeat);
assert(size(feat,1)==numel(data),'Only non-flipped instances allowed');

[preds,subtype] = poseHypotheses(feat,4,0);

rotX = diag([1 -1 -1]);
refX = diag([-1 1 1]);

for i=1:length(data)
    data(i).subtypePred = subtype(i);
    for c = 1:4
        euler = preds{c}(i,:);
        R1 = angle2dcm(euler(1), euler(2)-pi/2, -euler(3),'ZXZ');
        data(i).rotationPred{c} = rotX*R1';
    end
end

dataPreds = data;

end

