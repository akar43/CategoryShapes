function [depthIm] = meshToDepth(S,tri,imsize)
%MESHTODEPTH orthographic projections to get depth
%   Detailed explanation goes here

%write_off('temp.off',S,tri);
%[depthIm] = off2im('temp.off');
%delete('temp.off');
%return;

depthIm = Inf(imsize);
visIndexTri = zeros(size(tri,1),1);
for i=1:size(tri,1)
    %if(i==55329 && mod(i,1)==0)
    %    disp([int2str(i) '/' int2str(size(tri,1))]);
    %end
    depthIm = min(depthIm,triangleIntersection(S(tri(i,1:3),:),imsize));
end
end

function depthIm = triangleIntersection(pts,imsize)

depthIm = Inf(imsize);
% bbox - [y x y x]
bbox = [max(round(min(pts(:,1))),1) max(round(min(pts(:,2))),1) min(round(max(pts(:,1))),imsize(2)) min(round(max(pts(:,2))),imsize(1))];

faceMatrix = [pts(1,1)-pts(3,1) pts(2,1)-pts(3,1); pts(1,2)-pts(3,2) pts(2,2)-pts(3,2)];
% facematrix = [dx1 dx2; dy1 dy2];
%faceMatrix = inv(faceMatrix);
boxsize = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
Y = bbox(4)-bbox(2) + 1; % should X and Y have a value this + 1 ?
X = bbox(3)-bbox(1) + 1;
if(Y <= 0 || X <= 0)
    return
end
box_pts(1,:) = ceil((1:boxsize)/Y)-1;
box_pts(2,:) = mod((1:boxsize),Y);
b = box_pts - repmat([pts(3,1)-bbox(1);pts(3,2)-bbox(2)],1,boxsize); % b = [dxs;dys;]
warning off
lambdas = faceMatrix\b;
warning on
lambdas(3,:) = 1 - lambdas(2,:)-lambdas(1,:);
outside = (min(lambdas,[],1))<0;
Zs = sum(repmat(pts(:,3),1,boxsize).*lambdas,1);
Zs(outside) = Inf;
depthIm(sub2ind(imsize,box_pts(2,:)+bbox(2),box_pts(1,:)+bbox(1))) = Zs;

end
