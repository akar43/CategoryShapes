function vis_PSIRFS(state,pad)

if(nargin<2)
    pad = 25;
end

mask3 = ~repmat(state.mask,[1,1,3]);
bbox = mask2bbox(state.mask);

Iv = state.im;
Iv(mask3) = 0;
Zv = state.height;
Zv(~state.mask) = NaN;
Zbak = Zv;
Zv = visualizeDEM(Zv);
Zv(mask3) = 0;
Nv = visualizeNormals_color(state.normal);
Nv(mask3) = 0;
Rv = state.reflectance;
Rv(mask3) = 0;
Sv = state.shading;
Sv(mask3) = 0;
Lv = visSH_color(state.light, [size(state.height,1), 150]);
Lv(isnan(Lv))=0;
Lv = max(0, min(1, Lv));

sz = [size(state.im,1);size(state.im,2)];
cropbox = bbox;
%imshow([Iv,Zv,Nv,Rv,Sv,Lv]);
% figure;
% visualizeDEM_3D(Zbak);
imshow([padarray(imcrop(Iv,cropbox),[pad pad]),padarray(imcrop(Zv,cropbox),[pad pad]),...
    padarray(imcrop(Nv,cropbox),[pad pad]),padarray(imcrop(Rv,cropbox),[pad pad]),...
    padarray(imcrop(Sv,cropbox),[pad pad])]);
end

function bbox = mask2bbox(mask)
    [r,c] = find(mask);
    xmin = min(c); xmax = max(c); ymin = min(r); ymax = max(r);
    bbox = [xmin ymin xmax ymax];bbox(3:4) = bbox(3:4)-bbox(1:2)+1; %(xywh)
end