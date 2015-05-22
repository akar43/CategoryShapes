function [P3, RO, Tr, Z, c, P3_debug, RO_debug, Tr_debug, Z_debug, c_debug] = ...
        em_sfm_known_shape(P, MD, S_bar,V,sigma_sq, mask, imsize, bbox, tol, max_em_iter)
%  INPUT:
%
%  P           - (2*T) x J tracking matrix:          P([t t+T],:) contains the 2D projections of the J points at time t
%  MD          - T x J missing data binary matrix:   MD(t, j)=1 if no valid data is available for point j at time t, 0 otherwise
%  K           - number of deformation basis
%  use_lds     - set to 1 to model deformations using a linear dynamical system; set to 0 otherwise
%  tol         - termination tolerance (proportional change in likelihood)
%  max_em_iter - maximum number of EM iterations
%  debugInterval - iteration interval after which you want to see output (optional if you want degub output)
%
%  OUTPUT:
%
%  P3          - (3*T) x J 3D-motion matrix:                    ( P3([t t+T
%  RO          - rotation:                 cell array           ( RO{t} gives the rotation matrix at time t )
%  Tr          - translation:              T x 2 matrix
%  Z           - deformation weights:      T x K matrix
%  c           - scaling factor:           T X 1 matrix

    %% Parsing parameters
    params = get_params();
    debug = params.nrsfm.debug;
    debugInterval = params.nrsfm.debugInterval;

    %% Initializing debug values
    P3_debug = {}; RO_debug = {}; Tr_debug = {}; Z_debug = {}; c_debug = {};
    interval = 0;

    K = size(V,1)/3;
    [T, J] = size(MD);
    P_hat = P; % if any of the points are missing, P_hat will be updated during the M-step
    [R_init, Trvect] = rigidfac_known_shape(P_hat, MD,S_bar);
    %[R_init, Trvect, S_bar] = rigidfac_known_shape2(P_hat, MD,S_bar);

    %compute c here
    c = ones(T,1);
   % if scaling
        for t = 1:T
            c(t) = mean([norm(R_init(t,:)),norm(R_init(t+T,:))]); % just an estimate
        end
   % end

    Tr(:,1) = Trvect(1:T);
    Tr(:,2) = Trvect(T+1:2*T);

    R = zeros(2*T, 3);
    % enforces rotation constraints
    for t = 1:T,
        Ru = R_init(t,:);
        Rv = R_init(T+t,:);
        Rz = cross(Ru,Rv); if det([Ru;Rv;Rz])<0, Rz = -Rz; end;
        RO_approx = apprRot([Ru;Rv;Rz]);
        RO{t} = RO_approx;
        R(t,:) = RO_approx(1,:);
        R(t+T,:) = RO_approx(2,:);
    end

    if debug

       interval = interval+1;
       P3 = zeros(3*T, J);
       for t = 1:T,
            Rf = [R(t,:); R(t+T,:)];
            S = S_bar;
            S = c(t,1)*RO{t}*S;
            P3([t t+T t+2*T], :) = S + [Tr(t, [1 2]) -mean(S(3,:))]'*ones(1,J);
       end
       P3_debug{interval} = P3;
       RO_debug{interval} = RO;
       Tr_debug{interval} = Tr;
       Z_debug{interval} = [];
       c_debug{interval} = c;
    end

    loglik = 0;
    for em_iter=1:max_em_iter
        %% computes the hidden variables distributions
        [E_z, E_zz] = estep_compute_Z_distr(P_hat, S_bar, V, R, c, Tr, sigma_sq);     % (Eq 17-18)

        Z = E_z';

        %% fills in missing points
        if sum(MD(:))>0
            P_hat = mstep_update_missingdata(P_hat, MD, S_bar, V, E_z, RO, c, Tr, mask, imsize, bbox, params.nrsfm.norm_dim);     % (Eq 25)
        end

        %% updates rotation
        [RO, R] = mstep_update_rotation(P_hat, S_bar, V, E_z, E_zz, RO, c, Tr);       % (Eq 24)

    %    if scaling
            c = mstep_update_c(P_hat, S_bar, V, E_z, E_zz, RO, Tr); % Eq 48 (PAMI paper)
            %frac = mean(c);
            %c = c/frac;
            %S_bar = frac*S_bar;
            %V = frac*V;
            %fprintf('Mean c: %d\n',mean(c));
    %    end

        %% updates translation
        Tr = mstep_update_transl(P_hat, S_bar, V, E_z, RO, c);                        % (Eq 23)

        %why not update noise variance here like in the em_sfm code?
        % computes log likelihood
        oldloglik = loglik;
        loglik = compute_log_lik(P_hat, S_bar, V, E_z, E_zz, RO, c, Tr, sigma_sq);
%         if(mod(em_iter,200)==0)
%             fprintf('Iteration %d/%d: Error %f\n', em_iter, max_em_iter, -loglik);
%         end
        % save debug information
        if debug
            if(mod(em_iter+2, debugInterval) == 0)
               interval = interval+1;
               P3 = zeros(3*T, J);
               for t = 1:T,
                    z_t = Z(t,:);
                    Rf = [R(t,:); R(t+T,:)];
                    S = S_bar;
                    for kk = 1:K,
                        S = S+z_t(kk)*V((kk-1)*3+[1:3],:);
                    end;
                    S = c(t,1)*RO{t}*S;
                    P3([t t+T t+2*T], :) = S + [Tr(t, [1 2]) -mean(S(3,:))]'*ones(1,J);
               end
               P3_debug{interval} = P3;
               RO_debug{interval} = RO;
               Tr_debug{interval} = Tr;
               Z_debug{interval} = Z;
               c_debug{interval} = c;
            end
        end

        if (em_iter <= 2),
            loglikbase = loglik;
        %elseif (loglik < oldloglik)
            %fprintf('Violation\n');
            %keyboard;
        elseif (loglik-loglikbase)<(1 + tol)*(oldloglik-loglikbase)
            %fprintf('\n');
            break;
        end

    end
    %compute final answer
    P3 = zeros(3*T, J);
    for t = 1:T,
        z_t = Z(t,:);
        Rf = [R(t,:); R(t+T,:)];
        S = S_bar;
        for kk = 1:K,
            S = S+z_t(kk)*V((kk-1)*3+[1:3],:);
        end;
        S = c(t,1)*RO{t}*S; %% changed code here !
        P3([t t+T t+2*T], :) = S + [Tr(t, [1 2]) -mean(S(3,:))]'*ones(1,J);
    end

    if(debug)
        interval = interval+1;
        P3_debug{interval} = P3;
        RO_debug{interval} = RO;
        Tr_debug{interval} = Tr;
        Z_debug{interval} = Z;
        c_debug{interval} = c;
    end

end
