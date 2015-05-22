function [test_out] = normalize_test(test,model)
%NORMALIZE_TEST Summary of this function goes here
%   Detailed explanation goes here

test_out  = test;
common_parts = model.part_names(ismember(model.part_names,test.labels)); 

for i=1:length(common_parts)
    trmap(i) = find(ismember(model.part_names,common_parts{i}));
    temap(i) = find(ismember(test.labels,common_parts{i}));
end

N = size(test.points,1);
K = length(model.part_names);

test_out.points = nan(N,K);
test_out.points(:,trmap) = test.points(:,temap);
test_out.labels = model.part_names;

end


