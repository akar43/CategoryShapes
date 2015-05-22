function [v, template] = cell2vector( c )

  vs = {};
  template.sz = size(c);
  template.shapes = {};
  for i = 1:numel(c)
    x = c{i};
    if iscell(x)
      [vs{i}, template.shapes{i}] = cell2vector(x);
    else
      template.shapes{i} = size(x);
      vs{i} = x(:);
    end
  end
  
  v = cat(1,vs{:});
  
end

