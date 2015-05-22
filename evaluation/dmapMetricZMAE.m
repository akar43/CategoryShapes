function score =dmapMetricZMAE(dmap1,gtdmap,mask)
    
    dmap1(isinf(dmap1)) = nan;
    gtdmap(isinf(gtdmap)) = nan;
    mask = logical(mask);
    x = dmap1(mask);
    y = gtdmap(mask);
    % Get bbox from mask
    [r,c] = find(mask);
    xmin = min(c); xmax = max(c); ymin = min(r); ymax = max(r);
    bbox = [xmin ymin xmax-xmin+1 ymax-ymin+1];
    
    nanMask = ~isnan(y); % Keep points present in gt depth    
    x = x(nanMask); y = y(nanMask);
    x(isnan(x)) = median(x(~isnan(x)));
    
    b = median(x-y);
    
    score = abs(x-y-b)/sqrt(bbox(3)^2+bbox(4)^2);
    score = mean(score);
   
end
