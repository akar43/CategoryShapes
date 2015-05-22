function [R, Tr] = rigidfac_known_shape(P, MD,S_hat)

Pnew = P;
[T, J] = size(Pnew); T = T/2;

if sum(MD(:)) > 0, % if there is missing data, then it uses an iterative solution to get a rough initialization for the missing points
   [i,j] = find(MD==1);
   ind = sub2ind(size(P), [i; i+T], [j; j]);
   numIter = 10;
else
   numIter = 1;
   ind = [];
end
for iter=1:numIter
   Tr = Pnew*ones(J,1)/J;
   Pnew_c = Pnew - Tr*ones(1,J);
   Rhat = Pnew_c/S_hat;
   P_approx = Rhat*S_hat + Tr*ones(1,J);
   Pnew(ind) = P_approx(ind);
end

% Option 1
R = Rhat;
% Option2
%G = findG(Rhat);
%R = Rhat*G;
%S = inv(G)*S_hat;
% NOTE: Now return S

end
