function [c] = mstep_update_c(P, S_bar, V, E_z, E_zz, RO, Tr)
%MSTEP_UPDATE_C Summary of this function goes here
%   Detailed explanation goes here

%equation 48 of PAMI paper

[K, T] = size(E_z);
J = size(S_bar, 2);
c = zeros(T,1);
Pc = P - Tr(:)*ones(1,J);

parfor t=1:T
    
    zz_hat_t = [1 E_z(:,t)'; E_z(:,t) E_zz((t-1)*K+1:t*K,:)];
    z_hat_t = [1;E_z(:,t)];
    num = 0;
    den = 0;
    for j=1:J
        M_jt = [1 0 0 ; 0 1 0]*RO{t}*[S_bar(:,j) reshape(V(:,j), 3, K)];
        num = num + z_hat_t'*M_jt'*[Pc(t,j); Pc(t+T,j)];
        den = den+trace(M_jt*zz_hat_t*M_jt');
    end
    c(t,1) = num/den;
end


end

