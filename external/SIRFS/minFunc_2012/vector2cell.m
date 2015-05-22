function [c] = vector2cell( v, template)

  count = 0;  
  c = cell(template.sz);
  
  for i = 1:prod(template.sz)
    sz = template.shapes{i};
    if isstruct(sz)
      c{i} = vector2cell(v((count+1):end), sz);
      count = count + length(cell2vector(c{i}));
    else
      n = prod(sz);

      if isempty(v)
        c{i} = reshape(zeros(n,1), sz);
      else
        c{i} = reshape(v(count + [1:n]), sz);
      end
      count = count + n;
    end
  end
  
end

