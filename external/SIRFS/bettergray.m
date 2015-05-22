function output = bettergray

cmap = repmat([0:255]'/255, [1,3]);

if nargout == 0
  colormap(cmap)
else
  output = cmap;
end
