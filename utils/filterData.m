function [data] = filterData(data,fnames,removeFlip)
%FILTERDATA Summary of this function goes here
%   Detailed explanation goes here

data = data(ismember({data(:).voc_image_id},fnames));
if(nargin > 2 && removeFlip)
    data = data(~[data(:).flip]);
end

end