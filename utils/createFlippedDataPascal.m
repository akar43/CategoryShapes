function [flipData] = createFlippedDataPascal(data,kpsPerm)
%CREATEFLIPPEDDATA Summary of this function goes here
%   Detailed explanation goes here

% kps are stored as x,y
N = length(data);
globals;
for i=1:N
    im = imread(fullfile(PASCAL_DIR,[data(i).voc_image_id '.jpg']));
    imsize = size(im);
    data(i).imsize = imsize(1:2);
end

flipData = [data data];

for i=1:N
    
    imX = data(i).imsize(2);
    pascal_bbox = data(i).pascal_bbox;
    bbox = data(i).bbox;
    
    %% permute and flip kps
    kps = flipData(i).kps(kpsPerm,:);
    kps(:,1) = imX-kps(:,1) + 1; %% + 1 ??
    flipData(N+i).kps = kps;
    
    %% flip pascal_bbox [x y w h]
    flipData(N+i).pascal_bbox(1) = imX + 1 - pascal_bbox(1) - pascal_bbox(3);
    
    %% flip bbox [x y w h]
    flipData(N+i).bbox(1) = imX + 1 - bbox(1) - bbox(3);
    
    %% flip poly_x
    flipData(N+i).poly_x = imX - flipData(N+i).poly_x +1;
    
end

%% introduce flip variable
for i=1:N
    flipData(i).flip = 0;
    flipData(i+N).flip = 1;
end

end

