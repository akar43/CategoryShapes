function gradWeight = getGradWtFromClusters(viewClusters,i)
    thisCluster = find(cellfun(@(x)(sum(x==i)),viewClusters));
    meanElems = mean(cellfun(@length,viewClusters));
    gradWeight = meanElems/length(viewClusters{thisCluster}); 
end