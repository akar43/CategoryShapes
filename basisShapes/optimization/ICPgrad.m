function shapeGrad = ICPgrad(S,P)

%tree = kdtree_build(S);
tree = vl_kdtreebuild(S');
shapeGrad = zeros(size(S));
if(size(P,1)>0)
    %[ids,~] = kdtree_nearest_neighbor(tree,P);
    [ids,~] = vl_kdtreequery(tree,S',P');
    for i=1:length(ids)
        shapeGrad(ids(i),:) = shapeGrad(ids(i),:) + P(i)-S(ids(i),:);
    end
end

end
