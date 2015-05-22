function P_hat = mstep_update_missingdata(P, MD, S_bar, V, E_z, RO, c, Tr, mask, imsize, bbox, normdim,occlusion)
% P_hat = mstep_update_missingdata(P, MD, S_bar, V, E_z, RO, Tr)

% Fills in missing data using Eq 25

%% lambda is fraction with with missing points move towards silhouette
params = get_params();
lambda = params.nrsfm.occ_lambda;
%lambda = 0;

%% Running without occlusion reasoning

if(nargin<13)
    occlusion = true;
end

if(~occlusion || lambda ==0)
    P_hat = mstep_update_missingdata_old(P,MD,S_bar,V,E_z,RO,c,Tr);
    return;
end

[K, T] = size(E_z);
%J = size(S_bar, 2);

ind = find(sum(MD,2)>0);

%P_hat = P;
P_hatx = P(1:end/2,:);
P_haty = P(end/2+1:end,:);
%for t = 1:T
parfor t = 1:T
    if(sum(MD(t,:))>0)
    %if(0)
    %t = ind(kk);
        imsize_this = imsize(t,:);
        if(isstruct(mask))
            immask = roipoly(zeros(imsize_this(1),imsize_this(2)),mask.poly_x{t},mask.poly_y{t});
        else
            if(iscell(mask))
                immask = mask{t};
            else
                immask = mask;
            end
        end
        imbbox = bbox(t,:);
        %immask = poly2mask(mask.poly_x{t},mask.poly_y{t},imsize_this(1),imsize_this(2));
        missingpoints_t = find(MD(t, :));
        missing_infused = zeros(2, length(missingpoints_t));
        for s=1:length(missingpoints_t),
          j = missingpoints_t(s);

          H_j = [S_bar(:,j) reshape(V(:,j), 3, K)]; % H_j is 3x(K+1)

          S_tj = H_j*[1; E_z(:,t)]; % S_tj is 3x1

          %%%%%%%%%%%%%%%% Changed code here %%%%%%%%%%%%%%%%%%%%%%%
          %newf_t = c(t,1)*RO{t}(1:2,:) * S_tj + Tr(t,:)';
          newf_t = c(t,1)*RO{t}(1:2,:) * S_tj + Tr(t,:)';
          missing_infused(:,s)=newf_t;
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        %if(newf_t(1)<1 || newf_t(1)>imsize_this(2) || newf_t(2)<1 || newf_t(2)>imsize_this(1))
        newf_t=missing_infused;
        % Silhouette occlusion reasoning
        newft_image = kp_box2im(newf_t,imbbox, normdim);
        padding = round(max([max(0,1-min(newft_image(1,:))),max(0,max(newft_image(1,:))-imsize_this(2)),...
          max(0,1-min(newft_image(2,:))),max(0,max(newft_image(2,:))-imsize_this(1))]));
        pad_im = padarray(immask,[padding padding]);
        [~,IDX] = bwdist(pad_im);
        silnbr = zeros(2,length(missingpoints_t));
        for ii = 1:length(missingpoints_t)
          sil_nbridx = IDX(round(newft_image(2,ii))+padding,round(newft_image(1,ii))+padding);
          [silnbr(2,ii),silnbr(1,ii)] = ind2sub(size(pad_im),sil_nbridx);
        end
        silnbr = double(silnbr)-padding;
        newf_t_box = kp_im2box(silnbr,imbbox,normdim);
        tmp = P([t t+T],:);
        tmp(:,missingpoints_t) = (1-lambda)*newf_t + lambda*newf_t_box; %changed code here !!
        P_hatx(t,:)=tmp(1,:);
        P_haty(t,:)=tmp(2,:);
        %P_hat([t t+T], missingpoints_t) = newf_t_box;
        %P_hat([t t+T], j) = 0.1*newf_t_box+0.9*newf_t;
    end

    %% Visualization
    %points2_now = kp_box2im([P_hatx(t,:);P_haty(t,:)],imbbox,normdim);
    %missing_inds = find(MD(t,:));
    %imshow(immask);hold on;
    %plot(points2_now(1,:),points2_now(2,:),'.r','MarkerSize',10);
    %plot(points2_now(1,missing_inds),points2_now(2,missing_inds),'.g','MarkerSize',10);
    %hold off
    %pause();

end
P_hat = [P_hatx;P_haty];
%     for ii=1:size(P_hat,2)
%       points2_now(ii,:) = kp_box2im(P_hat([t,t+T],ii),bbox,normdim);
%     end
%     missing_inds = find(MD(t,:));
%     imshow(immask);hold on;
%     plot(points2_now(:,1),points2_now(:,2),'.r','MarkerSize',10);
%     plot(points2_now(missing_inds,1),points2_now(missing_inds,2),'.g','MarkerSize',10);
%     hold off
%     pause(0.1);
end



function kp_image = kp_box2im(points2, bbox, normdim)
    scdim = max(bbox(3:4));
    sc = scdim/normdim;
    kp_image = points2*sc + repmat(bbox(1:2)',1,size(points2,2));
end

function kp_box = kp_im2box(points2, bbox, normdim)
    sc = normdim/max(bbox(3:4));
    kp_box = sc*(points2-repmat(bbox(1:2)',1,size(points2,2)));
end
