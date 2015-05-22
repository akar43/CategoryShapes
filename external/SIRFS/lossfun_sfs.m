function [loss_S, d_loss_S] = lossfun_sfs(S, data, params)
  
valid = data.true.mask & all(~isnan(data.true.log_shading),3);
valid3 = repmat(valid, [1,1,size(S,3)]);
Sv = reshape(S(valid3), [], size(S,3));
% Iv = reshape(data.true.log_im(repmat(valid, [1,1,size(S,3)])), [], size(S,3));
Iv = reshape(data.true.log_shading(repmat(valid, [1,1,size(S,3)])), [], size(S,3));

mult = params.multipliers.sfs.mult{1} / nnz(valid);
ep = params.multipliers.sfs.epsilon{1};
gamma = params.multipliers.sfs.power{1};

d = Sv - Iv;
mag_sq = sum(d.^2,2) + ep.^2;
mag = mag_sq.^(gamma/2);

loss_S = mult * sum(mag);
d_loss_Sv = bsxfun(@times, d, mult*gamma*mag_sq.^(gamma/2-1));

d_loss_S = zeros(size(S));
d_loss_S(valid3) = d_loss_Sv;
