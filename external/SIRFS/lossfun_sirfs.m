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


function [loss, d_loss, state_return] = lossfun_sirfs(state, data, params)

if params.SOLVE_SHAPE
  
  if isfield(data, 'pyramid_Zmeta')
    %   Z = reshape(data.pyramid_Zmeta.AcT * state.Zpyr, data.pyramid_Zmeta.pind(1,:));
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


if params.SOLVE_LIGHT

  L_white = state.L_white;
  
  if params.WHITEN_LIGHT
    L = bsxfun(@plus, data.prior.light.whiten_params.inverse * L_white, data.prior.light.whiten_params.mean(:));
  else
    L = L_white;
  end
  
  L = reshape(L, 9, []);

else
  
  L = data.true.light;
  
end

if params.SOLVE_SHAPE

  [loss_Z, d_loss_Z] = priorZ(Z, data, params, N, dN_Z);
  
else
  
  loss_Z = 0;
  
end



S = {};
dS_N = {};
dS_L = {};

N_vec = reshape(N, [], 3);
for c = 1:size(L,2)
  [S{c}, dS_N{c}, dS_L{c}] = renderSH_helper(N_vec, L(:,c));
end
  
for c = 1:size(L,2)
    
  S{c} = reshape(S{c}, size(Z));
  dS_N{c} = reshape(dS_N{c}, [size(Z), 3]);
  
  dS_Z{c}.F1 = dN_Z.F1_1 .* dS_N{c}(:,:,1) + dN_Z.F1_2 .* dS_N{c}(:,:,2) + dN_Z.F1_3 .* dS_N{c}(:,:,3);
  dS_Z{c}.F2 = dN_Z.F2_1 .* dS_N{c}(:,:,1) + dN_Z.F2_2 .* dS_N{c}(:,:,2) + dN_Z.F2_3 .* dS_N{c}(:,:,3);
  
end
S = cat(3, S{:});

A = data.true.log_im - S;


if params.SHAPE_FROM_SHADING
  
  [loss_A, d_loss_S] = lossfun_sfs(S, data, params);
    
else
  
  [loss_A, d_loss_A] = priorA(A, data, params);
  d_loss_S = -d_loss_A;
  
end


if params.SOLVE_SHAPE
  
  d_loss_D1 = 0;
  d_loss_D2 = 0;
  for c = 1:size(d_loss_S,3)
    d_loss_D1 = d_loss_D1 + d_loss_S(:,:,c) .* dS_Z{c}.F1;
    d_loss_D2 = d_loss_D2 + d_loss_S(:,:,c) .* dS_Z{c}.F2;
  end
  
  d_loss_ZA = conv3d( d_loss_D1, dN_Z.f1) + conv3d( d_loss_D2, dN_Z.f2);
  d_loss_Z = d_loss_Z + d_loss_ZA;

  if isfield(data, 'pyramid_Zmeta')
    %   d_loss.Zpyr = data.pyramid_Zmeta.Ac * d_loss_Z(:);
    d_loss.Zpyr = buildGpyr_matrix(d_loss_Z, data.pyramid_Zmeta);
  else
    d_loss.Zpyr = d_loss_Z;
  end
  
end

if params.SOLVE_LIGHT % first half
  
  [loss_L, d_loss_L] = priorL(L, data, params);
  
  for c = 1:size(d_loss_S,3)
    d_loss_L(:,c) = d_loss_L(:,c) + dS_L{c}' * reshape(d_loss_S(:,:,c), [], 1);
  end
    
  if params.WHITEN_LIGHT
    d_loss_L_white = data.prior.light.whiten_params.inverse * d_loss_L(:);
  else
    d_loss_L_white = d_loss_L(:);
  end
  
  d_loss.L_white = d_loss_L_white;
else
  
  loss_L = 0;
  
end


loss = loss_A + loss_Z + loss_L;


n1 = fieldnames(state);  n1 = cat(2, n1{:});
n2 = fieldnames(d_loss); n2 = cat(2, n2{:});
assert(all(n1 == n2))


state_return.height = Z;
state_return.light = L;
state_return.normal = N;
state_return.shading = exp(S);
if ~params.SHAPE_FROM_SHADING
  state_return.reflectance = exp(A);
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
      
      S = {};
      for c = 1:size(L,2)
        S{c} = reshape(renderSH_helper(N_vec, L(:,c)), size(Z));
      end
      S = cat(3, S{:});
      
      A = data.true.log_im - S;
      
      invalid = repmat(~data.valid, [1,1,size(data.true.log_im,3)]);
      Z(~data.valid) = nan;
      S(invalid) = nan;
      A(invalid) = nan;
      
      I = data.true.im;
      
      A = exp(A);
      S = exp(S);
      
      
      %       A = max(0, min(1, A));
      %       S = max(0, min(1, S));
      
      state_bak = state;
      state = struct('normal', N, 'height', Z, 'reflectance', A, 'shading', S, 'light', L);
      clear N Z A S L
      
      
      if isfield(data.true, 'height')
        
        if params.SHAPE_FROM_SHADING
          [err, junk] = getError_SFS(state, data.true);

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
          
          Lv = max(0, min(1, Lv));
          
          Lv_true = visSH_color(data.true.light, [size(state.height,1), 150]);
          
          Lv_true(isnan(Lv_true)) = 0;
          Lv_true = max(0, min(1, Lv_true));
          
          data.true.shading(invalid) = 0;
          Lv(isnan(Lv)) = 0;
          state.shading(invalid) = 0;
                    
          Z = state.height;
          shift = mean(Z(~isnan(data.true.height)) - data.true.height(~isnan(data.true.height)));
          Z = Z - shift;
          Zv = [visualizeDEM(Z); visualizeDEM(data.true.height)];
          Zv(repmat(all(Zv == 1,3), [1,1,3])) = 0;
          Nv = visualizeNormals_color(state.normal);
          Ntv = visualizeNormals_color(data.true.normal);
          
          Ntv(isnan(data.true.normal)) = 0;
          Nv(isnan(data.true.normal)) = 0;
                    
          if size(state.shading,3) == 1
            state.shading = repmat(state.shading, [1,1,3]);
            
            data.true.shading = repmat(data.true.shading, [1,1,3]);
            
            Lv = repmat(Lv, [1,1,3]);
            Lv_true = repmat(Lv_true, [1,1,3]);
            
          end
          
          V = min(1, [Zv, [Nv; Ntv], [state.shading; data.true.shading], [Lv; Lv_true]]);
        
          
        else

          [err, junk] = getError(state, data.true);
          
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
          
          
          Lv_true = visSH_color(data.true.light, [size(state.height,1), 150]);
          
          Lv_true(isnan(Lv_true)) = 0;
          Lv_true = max(0, min(1, Lv_true));
          
          I(invalid) = 0;
          data.true.shading(invalid) = 0;
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
            data.true.shading = repmat(data.true.shading, [1,1,3]);
            
            Lv = repmat(Lv, [1,1,3]);
            Lv_true = repmat(Lv_true, [1,1,3]);
            
            I_pad = repmat(I_pad, [1,1,3]);
          end
          
          V = min(1, [I_pad, Zv, [Nv; Ntv], [state.reflectance; data.true.reflectance], [state.shading; data.true.shading], [Lv; Lv_true]]);
          
        end
        
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
      
      figure(1);
      imagesc(V);
      axis image off;
      set(gca, 'PlotBoxAspectRatio', [1 1 1])
      set(gca, 'Position', [0 0 1 1]);
      set(gcf, 'Position', [1, 1000, 1600, 1600/size(V,2)*size(V,1)])
      
      if isfield(data.true, 'height')
        %     figure(3)
        %     a = flattenPyr(Apyr);
        %     imagesc(min(1,exp(a))); imtight;
        %     set(gcf, 'Position', [1, 1, 1600, 1600/size(V,2)*size(V,1)])
        %     drawnow;
        
        global global_errors;
        global_errors{end+1} = err;
        light_errs = cellfun(@(x) x.light, global_errors);
        %           curvature_errs = cellfun(@(x) x.curvature, global_errors);
        normal_errs = cellfun(@(x) x.normal, global_errors);
        %     survey_errs = cellfun(@(x) x.survey, global_errors);
        shading_errs = cellfun(@(x) x.shading, global_errors);
        
        if ~params.SHAPE_FROM_SHADING
          reflectance_errs = cellfun(@(x) x.reflectance, global_errors);
          grosse_errs = cellfun(@(x) x.grosse, global_errors);
        end
        
        avg_errs = cellfun(@(x) x.avg, global_errors);
        
        
        figure(2);
        plot(light_errs ./ max(eps,light_errs(1)), 'Color', [0.5, 0.5, 0.5]); hold on;
        %           plot(curvature_errs ./ max(eps,curvature_errs(1)), 'Color', [0.5, 0.5, 0.5]); hold on;
        plot(normal_errs ./ max(eps,normal_errs (1)), 'k-');
        
        if ~params.SHAPE_FROM_SHADING        
          plot(grosse_errs ./ max(eps,grosse_errs(1)), 'b-');
          plot(reflectance_errs ./ max(eps,reflectance_errs(1)), 'r-');
        end
        
        plot(shading_errs ./ max(eps,shading_errs(1)), 'g-');
        
        plot(avg_errs ./ max(eps,avg_errs(1)), 'm-');
        
        axis square
        set(gca, 'YLim', [.009, 2])
        set(gca, 'YScale', 'log');
        title(['gray = LightMSE, black = NMAE, b = Grosse, r = AMSE, g = SMSE, m = avg'])
        %           title(['gray = KMSE, black = NMSE, b = Grosse, r = AMSE, g = SMSE, m = avg'])
        grid on;
        hold off;
      end
      
      drawnow;
      
      %           state_bak.contour_weights
      
    end
    
  end
end


