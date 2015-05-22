function score =dmapMetricRel(dmap1,gtdmap,mask)
    
    dmap1(isinf(dmap1)) = nan;
    gtdmap(isinf(gtdmap)) = nan;
    mask = logical(mask);
    x = dmap1(mask);
    y = gtdmap(mask);
    nanMask = ~isnan(y); % Keep points present in gt depth    
    x = x(nanMask); y = y(nanMask);
    x(isnan(x)) = median(x(~isnan(x)));    
    b = median(x-y);    
    score = abs(x-y-b)./y;
    score = mean(score);    
end
