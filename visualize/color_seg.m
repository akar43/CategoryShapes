function im1=color_seg(seg, img, color,ucm)
if(~exist('color', 'var'))
	color=[0 1 1];
end
alpha = 0.3;

img=im2double(img);

seg3 = repmat(seg,[1,1,3]);
color3 = cat(3,color(1)*ones(size(seg)),color(2)*ones(size(seg)),color(3)*ones(size(seg)));
img(~seg3) = img(~seg3)*0.7+0.3;
img(seg3) = (1-alpha)*color3(seg3) + alpha*img(seg3);
im1 = img;
return;

im1=zeros(size(img));
%img=rgb2gray(img);

im1(:,:,1)=(1-alpha)*color(1)*seg+alpha*img(:,:,1);
im1(:,:,2)=(1-alpha)*color(2)*seg+alpha*img(:,:,2);
im1(:,:,3)=(1-alpha)*color(3)*seg+alpha*img(:,:,3);
if(nargin>3)
stren=ucm.strength(3:2:end, 3:2:end);
stren=(stren<0.1);
im1=bsxfun(@times, im1, double(stren));
end