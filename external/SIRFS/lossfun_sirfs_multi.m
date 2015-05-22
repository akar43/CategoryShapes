% Copyright ©2013. The Regents of the University of California (Regents).
% All Rights Reserved. Permission to use, copy, modify, and distribute
% this software and its documentation for educational, research, and
% not-for-profit purposes, without fee and without a signed licensing
% agreement, is hereby granted, provided that the above copyright notice,
% this paragraph and the following two paragraphs appear in all copies,
% modifications, and distributions. Contact The Office of Technology
% Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA
% 94720-1620, (510) 643-7201, for commercial licensing opportunities.
%
% Created by Jonathan T Barron and Jitendra Malik, Electrical Engineering
% and Computer Science, University of California, Berkeley.
%
% IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
% SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
% ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
% REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
% PROVIDED HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


function [loss, d_loss, state_return] = lossfun_sirfs_multi(state, data, params)

if params.SOLVE_SHAPE
  
  if isfield(data, 'pyramid_Zmeta')
    Z = reconLpyr_matrix(state.Zpyr, data.pyramid_Zmeta);
  else
    Z = state.Zpyr;
  end
  
  [N, dN_Z] = getNormals_conv(Z);

else
  
  Z = data.given.height;
  N = data.given.normal;
  dN_Z = data.given.d_normal_Z;

  
end


Ls_white = state.Ls_white;

Ls = {};

for im_i = 1:length(data.true.ims)
  
  L_white = Ls_white{im_i};
  if params.WHITEN_LIGHT
    L = bsxfun(@plus, data.prior.light.whiten_params.inverse * L_white, data.prior.light.whiten_params.mean(:));
  else
    L = L_white;
  end
  
  L = reshape(L, 9, []);
  Ls{im_i} = L;
end


[loss_Z, d_loss_Z] = priorZ(Z, data, params, N, dN_Z);


Ss = {};
dSs_N = {};
dSs_L = {};
loss_As = [];
d_loss_Ss = {};
for im_i = 1:length(data.true.log_ims)
  
  Ss{im_i} = {};
  dSs_N{im_i} = {};
  dSs_L{im_i} = {};
  
  N_vec = reshape(N, [], 3);
  for c = 1:size(L,2)
    [Ss{im_i}{c}, dSs_N{im_i}{c}, dSs_L{im_i}{c}] = renderSH_helper(N_vec, Ls{im_i}(:,c));
  end
  
  for c = 1:size(L,2)
    
    Ss{im_i}{c} = reshape(Ss{im_i}{c}, size(Z));
    dSs_N{im_i}{c} = reshape(dSs_N{im_i}{c}, [size(Z), 3]);
    
    dSs_Z{im_i}{c}.F1 = dN_Z.F1_1 .* dSs_N{im_i}{c}(:,:,1) + dN_Z.F1_2 .* dSs_N{im_i}{c}(:,:,2) + dN_Z.F1_3 .* dSs_N{im_i}{c}(:,:,3);
    dSs_Z{im_i}{c}.F2 = dN_Z.F2_1 .* dSs_N{im_i}{c}(:,:,1) + dN_Z.F2_2 .* dSs_N{im_i}{c}(:,:,2) + dN_Z.F2_3 .* dSs_N{im_i}{c}(:,:,3);
    
  end
  Ss{im_i} = cat(3, Ss{im_i}{:});

  As{im_i} = data.true.log_ims{im_i} - Ss{im_i};
  

  if params.SHAPE_FROM_SHADING
    
    [loss_A, d_loss_S] = lossfun_sfs(Ss{im_i}, data, params);
    loss_As(im_i) = loss_A;
    d_loss_Ss{im_i} = d_loss_S;
    
  else
    
    [loss_A, d_loss_A] = priorA(As{im_i}, data, params);
    d_loss_Ss{im_i} = -d_loss_A;
    loss_As(im_i) = loss_A;
    
  end
  
  % Compute the average, not the sum, of the reflectance losses, to keep things balanced
  loss_As(im_i) = loss_As(im_i) / length(data.true.log_ims);
  d_loss_Ss{im_i} = d_loss_Ss{im_i} / length(data.true.log_ims);
  
end



% It might make sense to make all the reflectances similar to each other?
% [V, dV] = variance_L1(cat(4, As{:}), 4, 0.01);
% valid_V = ~isnan(V);
% V(~valid_V) = 0;
% dV(repmat(~valid_V, [1,1,1,length(As)])) = 0;
% 
% MULT_A_SAME = params.multipliers.reflectance.consistent{1};
% loss_A_same = MULT_A_SAME * sum(V(:));
% for im_i = 1:length(As)
%   d_loss_Ss{im_i} = d_loss_Ss{im_i} - MULT_A_SAME * dV(:,:,:,im_i);
% end


for im_i = 1:length(data.true.ims)
  
  d_loss_D1 = 0;
  d_loss_D2 = 0;
  for c = 1:size(d_loss_Ss{im_i},3)
    d_loss_D1 = d_loss_D1 + d_loss_Ss{im_i}(:,:,c) .* dSs_Z{im_i}{c}.F1;
    d_loss_D2 = d_loss_D2 + d_loss_Ss{im_i}(:,:,c) .* dSs_Z{im_i}{c}.F2;
  end
  
  d_loss_ZA = conv3d( d_loss_D1, dN_Z.f1) + conv3d( d_loss_D2, dN_Z.f2);
  d_loss_Z = d_loss_Z + d_loss_ZA;
end


if isfield(data, 'pyramid_Zmeta')
  %   d_loss.Zpyr = data.pyramid_Zmeta.Ac * d_loss_Z(:);
  d_loss.Zpyr = buildGpyr_matrix(d_loss_Z, data.pyramid_Zmeta);
else
  d_loss.Zpyr = d_loss_Z;
end
  


loss_Ls = [];
d_loss_Ls = {};
d_loss.Ls_white = {};
for im_i = 1:length(data.true.ims)
  
  L = Ls{im_i};
  [loss_Li, d_loss_Li] = priorL(L, data, params);
  % Compute the average, not the sum, of the illumination losses, to keep things balanced
  loss_Ls(im_i) = loss_Li / length(data.true.ims);
  d_loss_Ls{im_i} = d_loss_Li / length(data.true.ims);
  
  for c = 1:size(d_loss_Ss{im_i},3)
    d_loss_Ls{im_i}(:,c) = d_loss_Ls{im_i}(:,c) + dSs_L{im_i}{c}' * reshape(d_loss_Ss{im_i}(:,:,c), [], 1);
  end
  
  if params.WHITEN_LIGHT
    d_loss.Ls_white{im_i} = data.prior.light.whiten_params.inverse * d_loss_Ls{im_i}(:);
  else
    d_loss.Ls_white{im_i} = d_loss_Ls{im_i}(:);
  end
  
end


loss = sum(loss_As) + loss_Z + sum(loss_Ls);% + loss_A_same;


n1 = fieldnames(state);  n1 = cat(2, n1{:});
n2 = fieldnames(d_loss); n2 = cat(2, n2{:});
assert(all(n1 == n2))


if nargout >= 3
  state_return.height = Z;
  state_return.lights = Ls;
  state_return.normal = N;
  
  state_return.shadings = {};
  state_return.reflectances = {};
  for im_i = 1:length(data.true.ims)
    state_return.shadings{im_i} = exp(Ss{im_i});
    state_return.reflectances{im_i} = exp(As{im_i});
  end
end


global global_loss_best
if isempty(global_loss_best)
  global_loss_best = inf;
end

global global_loss_best_video
if isempty(global_loss_best_video)
  global_loss_best_video = inf;
end

if (loss <= global_loss_best)
  global_loss_best = loss;
  
  
  if params.DO_DISPLAY
    
    global last_display
    if isempty(last_display) || (etime(clock, last_display) > params.DISPLAY_PERIOD)
      last_display = clock;
      
      im_i = 1;
      
      L = Ls{im_i};
      
      S = {};
      for c = 1:size(L,2)
        S{c} = reshape(renderSH_helper(N_vec, L(:,c)), size(Z));
      end
      S = cat(3, S{:});
      
      A = data.true.log_ims{im_i} - S;
      
      invalid = repmat(~data.valid, [1,1,size(data.true.log_ims{im_i},3)]);
      Z(~data.valid) = nan;
      S(invalid) = nan;
      A(invalid) = nan;
      
      I = data.true.ims{im_i};
      
      A = exp(A);
      S = exp(S);
      
      %       A = max(0, min(1, A));
      %       S = max(0, min(1, S));
      
      state_bak = state;
      state = struct('normal', N, 'height', Z, 'reflectance', A, 'shading', S, 'light', L);
      clear N Z A S
      
      
      if isfield(data.true, 'height')
        
        s = size(state.height,1);
        
        Lv = visSH_color(state.light, [s, 150]);
        Lv(isnan(Lv)) = 0;
        
        if size(Lv,1) > s
          Lv = max(0, min(1, imresize(Lv, [s, 150])));
        else
          pad1 = floor((s - size(Lv,1))/2);
          pad2 = ceil((s - size(Lv,1))/2);
          Lv = padarray(padarray(Lv, [pad2], 0, 'post'), [pad1], 0, 'pre');
        end
        
        %           m = max(Lv(:));
        %           Lv = Lv ./ m;
        %           state.shading = state.shading ./ m;
        %           state.reflectance = state.reflectance .* m;
        Lv = max(0, min(1, Lv));
        
        
        I(invalid) = 0;
        Lv(isnan(Lv)) = 0;
        state.reflectance(invalid) = 0;
        state.shading(invalid) = 0;
        
        %           mat1 = mod([1:size(I,1)], 16) <= 8;
        %           mat2 = mod([1:size(I,2)], 16) <= 8;
        %           checker = bsxfun(@xor, mat2, mat1');
        %           I_bg = repmat(1-checker*0.2, [1,1,3]);
        %           I(invalid) = I_bg(invalid);
        
        Z = state.height;
        shift = mean(Z(~isnan(data.true.height)) - data.true.height(~isnan(data.true.height)));
        Z = Z - shift;
        %           Zv = visualizeDEM([Z; data.true.height]);
        Zv = [visualizeDEM(Z); visualizeDEM(data.true.height)];
        %           Zv = [visualizeDEM(state.height); visualizeDEM(data.true.height)];
        %           Zv = visualizeDEM([state.height; data.true.height]);
        Zv(repmat(all(Zv == 1,3), [1,1,3])) = 0;
        Nv = visualizeNormals_color(state.normal);
        Ntv = visualizeNormals_color(data.true.normal);
        
        Ntv(isnan(data.true.normal)) = 0;
        Nv(isnan(data.true.normal)) = 0;
        
        I_pad = padarray(padarray(I, floor(size(I,1)/2), 0, 'pre'), ceil(size(I,1)/2), 0, 'post'); % hah, ipad.
        
        if size(state.reflectance,3) == 1
          state.reflectance = repmat(state.reflectance, [1,1,3]);
          state.shading = repmat(state.shading, [1,1,3]);
          
          data.true.reflectance = repmat(data.true.reflectance, [1,1,3]);
          
          Lv = repmat(Lv, [1,1,3]);
          Lv_true = repmat(Lv_true, [1,1,3]);
          
          I_pad = repmat(I_pad, [1,1,3]);
        end
        
        V = min(1, [I_pad, Zv, [Nv; Ntv], [state.reflectance; data.true.reflectance], [state.shading; 0*state.shading], [Lv; 0*Lv]]);
        
      else
        
        Lv = visSH_color(state.light, [size(state.height,1), 150]);
        
        Lv(isnan(Lv)) = 0;
        Lv = max(0, min(1, Lv));
        
        I(invalid) = 0;
        Lv(isnan(Lv)) = 0;
        state.reflectance(invalid) = 0;
        state.shading(invalid) = 0;
        
        state.reflectance = state.reflectance ./ max(state.reflectance(:));
        state.shading = state.shading ./ max(state.shading(:));
        %           Lv = Lv ./ max(Lv(:));
        
        if size(invalid,3) == 1
          invalid3 = repmat(invalid, [1,1,3]);
        else
          invalid3 = invalid;
        end
        
        Zv = visualizeDEM([state.height]);
        Zv(invalid3) = 0;
        Nv = visualizeNormals_color(state.normal);
        Nv(invalid3) = 0;
        
        if size(I,3)==1
          I = repmat(I, [1,1,3]);
        end
        
        if size(state.reflectance,3)==1
          A = repmat(state.reflectance, [1,1,3]);
        else
          A = state.reflectance;
        end
        
        if size(state.shading,3)==1
          S = repmat(state.shading, [1,1,3]);
        else
          S = state.shading;
        end
        
        if size(Lv,3)==1
          Lv = repmat(Lv, [1,1,3]);
        end
        
        V = min(1, [I, Zv, Nv, A, S, Lv]);
        
      end
      
      imagesc(V); imtight;
      drawnow;
      
    end
    
  end
end


