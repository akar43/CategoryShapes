function [R] = averageRotationTransform(R1s,R2s)
%AVERAGEROTATION Summary of this function goes here
%   takes from R1s to R2s
[R1s,R2s] = removeNanRots(R1s,R2s);
R = eye(3);
N = length(R1s);
maxDiff = pi/3;

for i=1:N
    diffs{i} = R1s{i}'*R2s{i};
end
err = Inf;
iter = 0;

while(err > 1e-4 && iter < 50)
    iter = iter+1;
    delta = zeros(3,3);ct = 0;
    for i=1:N
        erri = norm(logm(R'*diffs{i}),'fro')/sqrt(2);
        if(iter < 5 || erri < maxDiff)
            delta = delta + logm(R'*diffs{i});
            ct = ct+1;
        end
    end
    delta = (delta/ct);
    err = (norm(delta,'fro')/sqrt(2));
    %disp(err);
    delta = expm(delta);
    R = R*delta;
    iter = iter + 1;
end
R = real(R);

end

function [nR1s,nR2s]=removeNanRots(R1s,R2s)
    n1 = cellfun(@(x)(any(isnan(x(:)))),R1s(:));
    n2 = cellfun(@(x)(any(isnan(x(:)))),R2s(:));
    n12 = n1 | n2;
    nR1s = R1s(~n12);
    nR2s = R2s(~n12);
end