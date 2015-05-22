% Depth correlation
function score =dmapMetricCorr(dmap1,gtdmap,mask)
    
    dmap1(isinf(dmap1)) = nan;
    gtdmap(isinf(gtdmap)) = nan;
    mask = logical(mask);
    x = dmap1(mask);
    y = gtdmap(mask);
    nanMask = ~isnan(y); % Keep points present in gt depth    
    x = x(nanMask); y = y(nanMask);
    x(isnan(x)) = median(x(~isnan(x)));
    x = x-median(x);y = y-median(y);
    score = sum(x.*y)/(norm(x)*norm(y));
end
