function [meshErr, dmapErr] = mainEval(class,jobID)

startup;
%% Mesh error computation
meshErr = evalMeshes(class,jobID);
fprintf('Mean mesh error: %.3f\n',nanmean(meshErr));

%% Depth map error computation
dmapErr = evalDepthMaps(class,jobID,'zmae');
fprintf('Mean depth map error: %.3f\n',nanmean(dmapErr*100));
end