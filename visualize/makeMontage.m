function [Im, ImAll] = makeMontage(Is, W, H, sc)
% Given a set of images in Is, sort them by the aspect ratio, and then
% ppaste them into a series of images...
  for i = 1:length(Is),
    h(i) = size(Is{i},1);
    w(i) = size(Is{i},2);
    Is{i} = imresize(Is{i}, sc);
  end
  asp = h./w;

  [~, ind] = sort(h, 'ascend');
  %ind = ind(round(2*end/3):end);
  %ind = ind(end-25:end);
  h = h(ind); w = w(ind); asp = asp(ind);
  Is = Is(ind);
  clear ind

  i = 1;
  k = 0;
  while i <= length(h),
    k = k+1;
    j = i;
    broke = false;
    while j <= length(h),
      mh(k) = mean(h(i:j));
      wk = sum(w(i:j).*(mh(k)./h(i:j)));
      if(wk > W)
        %ind{k} = i:j;
        %broke = true;
        break;
      end
      j = j + 1;
    end
    if(j > length(h))
      j = length(h);
    end
    ind{k} = i:j;
    i = j+1;
  end

  for i = 1:k,
    %% Take the images in ind, and make them into a montage
    Im{i} = [];
    for j = 1:length(ind{i}),
      Im{i} = [Im{i}, imresize(Is{ind{i}(j)}, [mh(i) w(ind{i}(j))*mh(i)./h(ind{i}(j))])];
    end
  end

  i = 1;
  ImAll = {};
  while i <= length(Im),
    h = 0;
    j = i;
    while j <= length(Im),
      h = h+size(Im{j}, 1);
      if(h > H)
        break;
      end
      j = j+1;
    end
    if(j > length(Im))
      j = length(Im);
    end
    ImAll{end+1} = cell2mat(re(Im(i:j)'));
    i = j+1;
  end

  Im = re(Im);

  
end

function Im = re(Im)
  %% Make a single image out of these things
  maxw = -inf;
  for i = 1:length(Im),
    maxw = max(maxw, size(Im{i},2));
  end

  for i = 1:length(Im),
    Im{i}(end,maxw,end) = 255;
  end
end