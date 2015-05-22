function [R, Tr, S] = rigidfac(P, MD)
% [R, Tr, S] = rigidfac(P, MD)
% Used for getting an initial R, Translation, S
% Computes rank 3 factorization: P = R*S + Tr
% This factorization holds even for the cases when we have c_t. No need to
% change stuff here

%% Initial stuff
Pnew = P;
[T, J] = size(Pnew);
T = T/2;

%% Missing Data Handling
if sum(MD(:)) > 0, % if there is missing data, then it uses an iterative solution to get a rough initialization for the missing points
   [i,j] = find(MD==1);
   ind = sub2ind(size(P), [i; i+T], [j; j]);
   numIter = 10;
else
   numIter = 1;
   ind = [];
end

%% Rank 3 factorization
r = 3;
for iter=1:numIter,
   Tr = Pnew*ones(J,1)/J; %mean of points
   Pnew_c = Pnew - Tr*ones(1,J); %centred P_new
   %find(Pnew_c(:,2)==0)
   [a,b,c] = svd(Pnew_c,0);
   smallb = b(1:r,1:r);
   sqrtb = sqrt(smallb);
   Rhat = a(:,1:r) * sqrtb;
   Shat = sqrtb * c(:,1:r)';
   P_approx = Rhat*Shat + Tr*ones(1,J);
   Pnew(ind) = P_approx(ind);
end

%% Final answers (the modifications with G should not matter much)
G = findG(Rhat);
R = Rhat*G;
S = G\Shat;

end
