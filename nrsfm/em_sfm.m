function [P3, S_bar, V, RO, Tr, Z, sigma_sq, phi, Q, mu0, sigma0, c] =...
    em_sfm(P, MD, K, mask, imsize, bbox, tol, max_em_iter, rhandedCoords, rotP3d)

%  Non-Rigid Structure From Motion with Gaussian/LDS Deformation Model
%  Copyright (c) by Lorenzo Torresani, Stanford University
%
%  Based on the following paper:
%
%  Lorenzo Torresani, Aaron Hertzmann and Christoph Bregler,
%     Learning Non-Rigid 3D Shape from 2D Motion, NIPS 16, 2003
%  http://cs.stanford.edu/~ltorresa/projects/learning-nr-shape/
%
%  Please refer to this publication if you use this program for
%  research or for technical applications.
%
%
%  INPUT:
%
%  P           - (2*T) x J tracking matrix:          P([t t+T],:) contains the 2D projections of the J points at time t
%  MD          - T x J missing data binary matrix:   MD(t, j)=1 if no valid data is available for point j at time t, 0 otherwise
%  K           - number of deformation basis
%  use_lds     - set to 1 to model deformations using a linear dynamical system; set to 0 otherwise
%  tol         - termination tolerance (proportional change in likelihood)
%  max_em_iter - maximum number of EM iterations
%  mask        - mask.poly_x (Tx1 cell array of x coordinates of mask) and
%                mask.poly_y (Tx1 cell array of y coordinates of mask)
%  imsize      - Tx2 array with height and width of images
%  bbox        - Bboxes of instances in image (Nx4)
%  params.normdim - Normalization dimension for object bounding boxes
%
%  OUTPUT:
%
%  P3          - (3*T) x J 3D-motion matrix:                    ( P3([t t+T t+2*T],:) contains the 3D coordinates of the J points at time t )
%  S_bar       - shape average:            3 x J matrix
%  V           - deformation shapes:       (3*K) x J matrix     ( V((n-1)*3+[1:3],:) contains the n-th deformation basis )
%  RO          - rotation:                 cell array           ( RO{t} gives the rotation matrix at time t )
%  Tr          - translation:              T x 2 matrix
%  Z           - deformation weights:      T x K matrix
%  sigma_sq    - variance of the noise in feature position
%  phi         - LDS transition matrix
%  Q           - LDS state noise matrix
%  mu0         - initial state mean
%  sigma0      - initial state variance
%  c - scale coefficients                   T X 1 matrix

%% Parsing passed parameters
params = get_params();

%% Checking Dimensions
if mod(size(P,1), 1) ~= 0,
   fprintf('Error: size(P) must be (2*T)xJ\n');
   return;
end

if (size(P,1)/2 ~= size(MD,1)) || (size(P,2) ~= size(MD,2))
   fprintf('Error: Size incompatibility between P and MD\n');
   return;
end

if mod(K, 1) ~= 0,
   fprintf('Error: K must be an integer value\n');
   return;
end
%% Initialization for Tr, S_bar, R, c

[T, J] = size(MD);

P_hat = P; % if any of the points are missing, P_hat will be updated during the M-step

% uses rank 3 factorization to get a first initialization for rotation and S_bar
[R_init, Trvect, S_bar] = rigidfac(P_hat, MD); % P_hat = R_init*S_bar + Trvect

% initialize c also here !!
c = ones(T,1);
%if scaling
    for t = 1:T
       c(t) = mean([norm(R_init(t,:)),norm(R_init(t+T,:))]); % just an estimate
    end
%end

Tr(:,1) = Trvect(1:T);
Tr(:,2) = Trvect(T+1:2*T);

R = zeros(2*T, 3);

%% enforces rotation constraints for initilizations
for t = 1:T,
   Ru = R_init(t,:);
   Rv = R_init(T+t,:);
   Rz = cross(Ru,Rv); if det([Ru;Rv;Rz])<0, Rz = -Rz; end;
   RO_approx = apprRot([Ru;Rv;Rz]);
   RO{t} = RO_approx;
   R(t,:) = RO_approx(1,:);
   R(t+T,:) = RO_approx(2,:);
end

%% Initializations for deformation shapes and weights
% given the initial estimates of rotation, translation and shape average, it initializes
% deformation shapes and weights through LSQ minimization of the reprojection error

[V, Z] = init_SB(P_hat, Tr, R, c , S_bar, K); %handled c inside this function

% initializes sigma_sq
E_zz_init = cov(Z);
E_zz_init = repmat(E_zz_init, T, 1);
sigma_sq = mstep_update_noisevar(P_hat, S_bar, V, Z', E_zz_init, RO, Tr, c); %handled c inside this function

phi = [];
mu0 = [];
sigma0 = [];
Q = [];


%% EM iterations

loglik = 0;
annealing_const = 60;
max_anneal_iter = round(max_em_iter/4);

pBar =  TimedProgressBar( max_em_iter, 30, ...
    'Training NRSfM ', ', completed ', 'Training NRSfM concluded in ' );
for em_iter=1:max_em_iter,
    %mean(c)
    %std(c)
    %mean(mean(abs(S_bar)))
    %% compute the hidden variables distributions
    [E_z, E_zz] = estep_compute_Z_distr(P_hat, S_bar, V, R, c, Tr, sigma_sq);     % (Eq 17-18) %handled c inside this function
    Z = E_z';

    %% updates shape basis
    [S_bar, V] = mstep_update_shapebasis(P_hat, E_z, E_zz, R, c, Tr);   % (Eq 21)

    %% fill in missing points
    if sum(MD(:))>0,
        P_hat = mstep_update_missingdata(P_hat, MD, S_bar, V, E_z, RO, c, Tr, mask, imsize, bbox, params.nrsfm.norm_dim,(em_iter>max_em_iter/2));    % Occlusion reasoning after half iterations over
    end

    %% updates rotation
    [RO, R] = mstep_update_rotation(P_hat, S_bar, V, E_z, E_zz, RO, c, Tr);       % (Eq 24)

    %RO = rotP3d;
    %for t = 1:T
    %    R(t,:) = RO{t}(1,:);
    %    R(t+T,:) = RO{t}(2,:);
    %end

    %% update C here
    %if scaling
        c = mstep_update_c(P_hat, S_bar, V, E_z, E_zz, RO, Tr); % Eq 48 (PAMI paper)
        frac = mean(c);
        c = c/frac;
        S_bar = frac*S_bar;
        V = frac*V;
    %end

    %% updates translation
    Tr = mstep_update_transl(P_hat, S_bar, V, E_z, RO, c);                        % (Eq 23)

    %% updates noise variance
    sigma_sq = mstep_update_noisevar(P_hat, S_bar, V, E_z, E_zz, RO, Tr, c);      % (Eq 22)
    if em_iter < max_anneal_iter,
        sigma_sq = sigma_sq * (1 + annealing_const*(1 - em_iter/max_anneal_iter));
    end

    %visualize_3D_point(S_bar,params.part_names,wireframe_car(),h);figure(h);clf;
    %% computes log likelihood
    oldloglik = loglik;
    loglik = compute_log_lik(P_hat, S_bar, V, E_z, E_zz, RO, c, Tr, sigma_sq);

%     if(mod(em_iter,40)==0)
%         fprintf('Iteration %d/%d: Error %f\n', em_iter, max_em_iter, -loglik/(size(P_hat,1)/2));
%     end

    if (em_iter <= 2),
     loglikbase = loglik;
    elseif (loglik < oldloglik)
     %fprintf('Violation');
     %keyboard;
    elseif 0 && ((loglik-loglikbase)<(1 + tol)*(oldloglik-loglikbase)),
     fprintf('\n');
     break;
    end
    pBar.progress();
end
pBar.stop();
%% Check for right handed coordinate flips
vec1 = S_bar(:, rhandedCoords(1,2)) - S_bar(:, rhandedCoords(1,1));
vec2 = S_bar(:, rhandedCoords(2,2)) - S_bar(:, rhandedCoords(2,1));
vec3 = cross(vec1,vec2);
v = S_bar(:, rhandedCoords(3,2)) - S_bar(:, rhandedCoords(3,1));

badCt = 0;
for t = 1:T
   z_t = Z(t,:);
   S = S_bar;
   for kk = 1:K,
      S = S+z_t(kk)*V((kk-1)*3+[1:3],:);
   end
   S = c(t,1)*RO{t}*S;
   Zs = S(3,:);
   badZ = mean(Zs(MD(t,:)));
   goodZ = mean(Zs(~MD(t,:)));
   if(goodZ > badZ)
       badCt = badCt+1;
   end
end
thresh = badCt/T;

isFlipped = 0;
if(thresh > 0.5 || (thresh >0.2 && dot(vec3,v)<0))
    refZ = diag([1 1 -1]);
    rotZ = diag([-1 -1 1]);
    isFlipped = 1;
    S_bar = -S_bar;
    V = -V;
    for i=1:length(RO)
        RO{i} = rotZ*RO{i};
    end
end

%% Changing to PASCAL 3D
fprintf('Converting to PASCAL 3D co-ordinate frame\n');
if(~isempty(rotP3d))
    tformRot = averageRotationTransform(RO,rotP3d);
else
    fprintf('PASCAL 3D rotations not found. Might be a problem with evaluation\n');
    tformRot = averageRotationTransform(RO,RO);
end

%tformRot = eye(3);
S_bar = tformRot'*S_bar;
for t = 1:T
    RO{t}  = RO{t}*tformRot;
end
for kk = 1:K
  V((kk-1)*3+[1:3],:) = tformRot'*V((kk-1)*3+[1:3],:);
end

%% compute the final answer
P3 = zeros(3*T, J);
for t = 1:T,
   z_t = Z(t,:);
   S = S_bar;
   for kk = 1:K,
      S = S+z_t(kk)*V((kk-1)*3+[1:3],:);
   end;
   S = c(t,1)*RO{t}*S; %% changed code here !

   P3([t t+T t+2*T], :) = S + [Tr(t, [1 2]) -mean(S(3,:))]'*ones(1,J);
end
