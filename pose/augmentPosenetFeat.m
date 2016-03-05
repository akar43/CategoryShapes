function [data] = augmentPosenetFeat(data,class)
%AUGMENTPOSENETFEAT Summary of this function goes here
%   Detailed explanation goes here

globals;
feat = load(fullfile(cachedir,'poseFeat',class)); feat = feat.feat;
%feat = generatePosePred(pascalClassIndex(class));
%feat = generatePoseFeatures('vggJointVps','vggJointVps',224,pascalClassIndex(class),1,data);

for i=1:length(data)
    if(~data(i).flip)
        data(i).poseFeat = feat(i,:);
    else
        data(i).poseFeat = [];
    end
end

end