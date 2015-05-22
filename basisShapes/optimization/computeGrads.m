function [gradKeypointS,gradKeypointV,gradKeypointAlpha,gradOcclusionS,...
    gradOcclusionV,gradOcclusionAlpha,occlusionCount,gradSilS,gradSilV,...
    gradSilAlpha,gradShapePriorS,gradShapePriorV,gradShapePriorAlpha] ...
    = computeGrads(S,V,alpha,stateFiles,lambda,shapePriorInstance,corenum,numcores,params)

numpoints = size(S,1);
K = size(V,2);
numimages = length(stateFiles);

gradOcclusionS = zeros(size(S));
gradOcclusionV = zeros(size(V));
gradOcclusionAlpha = zeros(size(alpha));
occlusionCount = zeros(numpoints,1);

gradSilS = zeros(size(S));
gradSilV = zeros(size(V));
gradSilAlpha = zeros(size(alpha));

gradKeypointS = zeros(size(S));
gradKeypointV = zeros(size(V));
gradKeypointAlpha = zeros(size(alpha));

gradShapePriorS = zeros(size(S));
gradShapePriorV = zeros(size(V));
gradShapePriorAlpha = zeros(size(alpha));

%t_occ=0;t_sil=0;t_prior=0;
%t_kp = 0;

for i=1:numimages
    if(mod(i,numcores)==(corenum-1))
        
        load(stateFiles{i});
        if(params.opt.normalizeByViews)
            gradWeight = getGradWtFromClusters(state.viewClusters,state.globalID);
            gradWeight = gradWeight^(0.5);
        else
            gradWeight = 1;
        end
        S_i = S + reshape(V*alpha(:,i),numpoints,3);

        %% Keypoint Consistency
        %tic;
        kpGrad = keypointGrad(S_i,state,params);
        kpGrad = lambda(6)*kpGrad;
        gradKeypointS = gradKeypointS + kpGrad;
        gradKeypointV = gradKeypointV + kpGrad(:)*(alpha(:,i))';
        gradKeypointAlpha(:,i) = V'*kpGrad(:);
        %t_kp = t_kp + toc;

        %% Occlusion Reasoning
        %tic;
        [occGrad,occCount] = occlusionGradOptimal(S_i,state); %we also keep track of how many constraints each point violates
        occGrad = lambda(1)*occGrad;
        occGrad = occGrad*gradWeight;
        occlusionCount = occCount + occlusionCount;
        gradOcclusionS = gradOcclusionS + occGrad; 
        gradOcclusionV = gradOcclusionV + occGrad(:)*(alpha(:,i))';
        gradOcclusionAlpha(:,i) = V'*occGrad(:);
        %t_occ = t_occ+toc;

        %% Silhouette Consistency
        %tic;
        silGrad = lambda(2)*silhouetteGrad(S_i,state,params); %we also keep track of how many constraints each point violates
        silGrad = silGrad*500; % because we divide by number of points on silhouette
        silGrad = silGrad*gradWeight;
        gradSilS = gradSilS + silGrad; 
        gradSilV = gradSilV + silGrad(:)*(alpha(:,i))';
        gradSilAlpha(:,i) = V'*silGrad(:);
        %t_sil = t_sil + toc;

        %% Shape Prior
        %tic;
        shapePriorGrad = lambda(5)*shapePriorInstance(S_i);
        gradShapePriorS = gradShapePriorS + shapePriorGrad;
        gradShapePriorV = gradShapePriorV + shapePriorGrad(:)*(alpha(:,i))'; %%Verify
        gradShapePriorAlpha(:,i) = V'*shapePriorGrad(:); %% Verify
        %t_prior = t_prior + toc;
    end
end
end
