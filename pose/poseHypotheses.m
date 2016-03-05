function [preds,subtype] = poseHypotheses(feat,n,alpha)
%POSEHYPOTHESES Summary of this function goes here
%   Detailed explanation goes here

N = size(feat,1);N1 = 21;N2 = 21;N3 = 21;
assert(n<=8,'A maximum of 8 hypothesis supported currently');
featScale = 1;

indices{1} = 1:21;
indices{2} = 22:42;
indices{3} = 43:63;
indices{4} = 64:70;
indices{5} = 71:77;
indices{6} = 78:84;
indices{7} = 86:95; %skipping one index because subtypes started from 1 instead of 0 during training

%% Coarse and Fine feature channels
feat1 = 1./(1+exp(-feat(:,indices{1})));feat1 = bsxfun(@rdivide,feat1,sum(feat1,2));
feat2 = 1./(1+exp(-feat(:,indices{2})));feat2 = bsxfun(@rdivide,feat2,sum(feat2,2));
feat3 = 1./(1+exp(-feat(:,indices{3})));feat3 = bsxfun(@rdivide,feat3,sum(feat3,2));

repInds = ceil(indices{1}/3);

feat1c = 1./(1+exp(-featScale*feat(:,indices{4})));feat1c = feat1c(:,repInds);
feat1c = bsxfun(@rdivide,feat1c,sum(feat1c,2));

feat2c = 1./(1+exp(-featScale*feat(:,indices{5})));
feat2c = feat2c(:,repInds);feat2c = bsxfun(@rdivide,feat2c,sum(feat2c,2));

feat3c = 1./(1+exp(-featScale*feat(:,indices{6})));feat3c = feat3c(:,repInds);
feat3c = bsxfun(@rdivide,feat3c,sum(feat3c,2));

if(size(feat,2) >= max(indices{7}))
    [~,subtype] = max(feat(:,indices{7}),[],2);
else
    subtype = zeros(N,1);
end

%% Combining Coarse and Fine Features
feat1 = (1-alpha)*feat1 + alpha*feat1c;
feat2 = (1-alpha)*feat2 + alpha*feat2c;
feat3 = (1-alpha)*feat3 + alpha*feat3c;

%% n-best
[I1s,I2s,I3s,selections1,selections2,selections3] = nBestF3(feat1,feat2,feat3,n);

%% Cands
for cand = 1:n
    I1 = I1s(sub2ind([N,size(I1s,2)],[1:N]',selections1(:,cand)));
    I2 = I2s(sub2ind([N,size(I2s,2)],[1:N]',selections2(:,cand)));
    I3 = I3s(sub2ind([N,size(I3s,2)],[1:N]',selections3(:,cand)));
    preds{cand} = [(I1 - 11)*pi/10.5,(I2 - 11)*pi/10.5, (I3-0.5)*pi/10.5];
end

end

function [I1s,I2s,I3s,selections1,selections2,selections3] = nBestAll(feat1,feat2,feat3,n)
N = size(feat1,1);
N1 = size(feat1,2);N2 = size(feat2,2);N3 = size(feat3,2);
[V11,I11] = max(feat1,[],2);
[V21,I21] = max(feat2,[],2);
[V31,I31] = max(feat3,[],2);

feat1(sub2ind(size(feat1),[1:N,1:N,1:N],[I11',mod(I11'-2,N1)+1,mod(I11',N1)+1]))=0;
feat2(sub2ind(size(feat2),[1:N,1:N,1:N],[I21',mod(I21'-2,N2)+1,mod(I21',N2)+1]))=0;
feat3(sub2ind(size(feat3),[1:N,1:N,1:N],[I31',mod(I31'-2,N3)+1,mod(I31',N3)+1]))=0;

[V12,I12] = max(feat1,[],2);
[V22,I22] = max(feat2,[],2);
[V32,I32] = max(feat3,[],2);

seq{1} = [1 2 1 1 2 2 1 2 ]; %sequece of flips for ith angle in flip order
seq{2} = [1 1 2 1 2 1 2 2 ];
seq{3} = [1 1 1 2 1 2 2 2 ];

deltas = [V11-V12,V21-V22,V31-V32]; %the lower the better
vals = zeros(2,2,2);vals(1:8)=1:8;

for i=1:N
    [~,order] = sort(deltas(i,:),'ascend');
    selections1(i,:) = seq{order(1)};
    selections2(i,:) = seq{order(2)};
    selections3(i,:) = seq{order(3)};
end
I1s = [I11,I12];
I2s = [I21,I22];
I3s = [I31,I32];

end

function [I1s,I2s,I3s,selections1,selections2,selections3] = nBestF3(feat1,feat2,feat3,n)

N = size(feat1,1);
N3 = size(feat3,2);

[~,I11] = max(feat1,[],2);
[~,I21] = max(feat2,[],2);

locMax = false(size(feat3));
for j=1:N3
    locMax(:,j) = feat3(:,j) >= feat3(:,mod(j-2,N3)+1) & feat3(:,j) >= feat3(:,mod(j,N3)+1);
end
feat3(~locMax)=-Inf;

selections1 = ones(N,n);
selections2 = ones(N,n);
selections3 = ones(N,n);
simDiffs = normpdf([-10:10],0,1.5)/normpdf(0,0,1.5);

for i=1:N
    f = feat3(i,:);
    %for j=1:n
    %    [~,k] = max(f);
    %    selections3(i,j) = k;
    %    diffk = 1-circshift(simDiffs,[0,k-11]);
    %    f = f.*diffk;
    %end
    [~,orders] = sort(f,'descend');
    selections3(i,:) = orders(1:n);
end

I1s = [I11];
I2s = [I21];
I3s = ones(N,1)*[1:N3];

end

function [I1s,I2s,I3s,selections1,selections2,selections3] = nBestF3Modes(feat1,feat2,feat3,n)

N = size(feat1,1);
N3 = size(feat3,2);

[~,I11] = max(feat1,[],2);
[~,I21] = max(feat2,[],2);
[~,I31] = max(feat3,[],2);

locMax = false(size(feat3));
for j=1:N3
    locMax(:,j) = feat3(:,j) >= feat3(:,mod(j-2,N3)+1) & feat3(:,j) >= feat3(:,mod(j,N3)+1);
end
feat3(~locMax)=-Inf;

selections1 = ones(N,n);
selections2 = ones(N,n);
selections3 = ones(N,n);

selections3(:,1) = I31;
selections3(:,4) = mod(round(I31+N3/2 - 1),N3)+1;
selections3(:,2) = N3 - selections3(:,4) + 1;
selections3(:,3) = N3-I31+1;
selections3 = selections3(:,1:n);

I1s = [I11];
I2s = [I21];
I3s = ones(N,1)*[1:N3];

end
