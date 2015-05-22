function [v, template] = struct2vector( s )
  
  if isnumeric(s)
    
    v = s(:);
    template = size(s);
    
  elseif iscell(s)
    
    [v, template] = cell2vector(s);
    
  else
    
    fields = fieldnames(s)';
    vs = {};
    shapes = {};
    for fi = 1:length(fields)
      x = getfield(s, fields{fi});
      if iscell(x)
        [vs{fi}, shapes{fi}] = cell2vector(x);
      elseif isstruct(x)
        [vs{fi}, shapes{fi}] = struct2vector(x);
      else
        vs{fi} = x(:);
        shapes{fi} = size(x);
      end
    end

    v = cat(1,vs{:});

    template.fields = fields;
    template.shapes = shapes;
    
  end
end
