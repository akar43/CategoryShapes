function [y, dh_struct] = findgrad(X_struct, f, e, varargin)

[X_vec, X_template] = struct2vector(X_struct);

[y] = feval(f, X_struct, varargin{:});

dh = nan(length(X_vec),1) ;

for j = 1:length(X_vec)
  
  dx = zeros(length(X_vec),1);
  dx(j) = dx(j) + e;
  
  [y2] = feval(f, vector2struct(X_vec + dx, X_template), varargin{:});
  [y1] = feval(f, vector2struct(X_vec - dx, X_template), varargin{:});
  
  dh(j) = (y2 - y1)/(2*e);
end

dh_struct = vector2struct(dh, X_template);