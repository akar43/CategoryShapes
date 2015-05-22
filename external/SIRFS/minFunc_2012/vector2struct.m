function [s] = vector2struct( v, template )

  if isnumeric(template)
    
    s = reshape(v, template);
    
  elseif isfield(template, 'sz') && isfield(template, 'shapes')
    
    s = vector2cell(v, template);
    
  else
    count = 0;

    s = [];
    for fi = 1:length(template.fields)
      f = template.fields{fi};
      sz = template.shapes{fi};

      if isfield(sz, 'fields')

        sub_struct = vector2struct(v(count+1:end), sz);
        c = length(struct2vector(sub_struct));
        s.(f) = sub_struct;

      elseif isstruct(sz)

        c = sum(cellfun(@(x) prod(x), sz.shapes));
        if isempty(v)
          next = zeros(c,1);
        else
          next = v(count + [1:c]);
        end
        s.(f) = vector2cell(next, sz);

      else

        c = prod(sz);
        if isempty(v)
          next = zeros(c,1);
        else
          next = v(count + [1:c]);
        end
        s.(f) = reshape(next, sz);

      end

      count = count + c;
    end
  end
end
