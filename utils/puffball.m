function [tri, coord] = puffball(mask)

%Weighted skeleton, where each non-zero value corresponds to the maximum
%size of a sphere that can be centered there.
wSkel = get_SkelRadius(mask);

heightFunction = puffbalIInflation(mask,wSkel);

[tri,coord] = mesh_from_height(mask, heightFunction);


end



function [tri, coord] =  mesh_from_height(mask, rec)

[M,N] = size(mask);
[x,y] = meshgrid(1:N,1:M);

tri = delaunay(x,y);

ind_tri = mask(tri);
ind_tri = ind_tri(:,1) | ind_tri(:,2) | ind_tri(:,3);

tri = tri(ind_tri,:);
aux = unique(tri);
boundary = setdiff(aux, find(mask));

points=zeros(M*N,1);
nPoints = length(aux);
points(aux) = 1:nPoints;

tri = points(tri);
boundary = points(boundary);
x = x(aux);
y = y(aux);
z = rec(aux);

for k =1:length(boundary)
    pBound = boundary(k);
    sel = sum(tri==pBound,2)>0; 
    selPoints = setdiff(unique(tri(sel,:)),pBound);
    
    x1 = median(x(selPoints));
    y1 = median(y(selPoints));
    
    x(pBound) = x1;
    y(pBound) = y1;
    
end


points = zeros(nPoints,1);
points(boundary) = boundary;
points(points==0) = nPoints + (1:(nPoints-length(boundary)));

reflected_tri = points(tri);
tri = [tri; reflected_tri];
x = [x;x];
y = [y;y];
z = [z; -z];
x(boundary + nPoints) = [];
y(boundary + nPoints) = [];
z(boundary + nPoints) = [];

coord = [x y z];

%figure; trisurf(tri,x,y,z,'FaceColor','r');
%axis equal
%set(gca,'YDir','rev');

end




function [ h ] = puffbalIInflation( mask,wSkel )
% TAKE THE UNION (SOFT-MAX) OF MAXIMAL SPHERES %
[Y, X] = meshgrid(1:size(mask,2),1:size(mask,1));
h = ones(size(mask));

[y,x] = find(wSkel);

k = 1;

for i = 1:length(x)
    r = wSkel(y(i),x(i))^2 - (X-y(i)).^2 - (Y-x(i)).^2;
    h(r>0) = h(r>0)+exp(k*sqrt(r(r>0)));
end

h = log(h)/k;

end


function [wSkel, allRadius] = get_SkelRadius(mask)
%Weighted skeleton, where each non-zero value corresponds to the maximum
%size of a sphere that can be centered there.

% CALCULATE GRASSFIRE HEIGHT FUNCTION %
% A 3x3-tap filter to smoothly erode an anti-aliased edge

fil = [0.1218 0.4123 0.1218; 0.4123 0.9750 0.4123; ...
    0.1218 0.4123 0.1218]/1.2404;
nmask = double(mask);
allRadius = zeros(size(mask));
while ~isempty(find(nmask,1))
    allRadius = allRadius+nmask/1.67; % Each iteration erodes the edge .6 pixels
    nmaskpad = padarray(nmask,[1 1],'replicate');
    nmaskpad = conv2(nmaskpad,fil,'same')-1.4241;
    nmask = max(min(nmaskpad(2:end-1,2:end-1),1),0);
end

% LOCATE THE MEDIAL AXIS %
[dx, dy] = gradient(allRadius);
dsurf = sqrt(dx.^2+dy.^2);
% Medial axis points have a grassfire gradient measurably less than 1
radThreshold = min(max(allRadius(:)),2);
wSkel = bwmorph(dsurf<0.958&allRadius>=radThreshold,'skel',Inf).*allRadius;

end
