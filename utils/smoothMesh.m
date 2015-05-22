function [new_coord] =  smoothMesh(tri,coord,it)
% tri is the mesh faces n*3 matrix
% coord is the mesh vertices m*3 matrix

pairs = unique([tri(:,1:2);tri(:,2:3);tri(:,[1 3])],'rows');
pairs = [pairs; pairs(:,[2 1])];
pairs = unique(pairs,'rows');

new_coord = zeros(size(coord));

if(nargin==2)
    it = 2;
end

for i =1:it
    for k =1:length(coord)
        neigh = pairs(pairs(:,1)==k,2);
        new_coord(k,:) = mean(coord(neigh,:));
    end
    coord = new_coord;
end

end
