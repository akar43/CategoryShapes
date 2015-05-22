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


function [state] = do_Solve(data, params)

addpath(genpath('./minFunc_2012'));

if params.SOLVE_SHAPE
  
  if isfield(data.true, 'ims')
    sz = [size(data.true.ims{1},1), size(data.true.ims{1},2)];
  else
    sz = [size(data.true.im,1), size(data.true.im,2)];
  end
  
  Zfilt = params.PYR_FILTER(:);
  edges = params.PYR_EDGES;
  S = min(params.MAX_PYR_DEPTH, floor(log2(min(sz))));
  
  if S > 1
    [data.pyramid_Zmeta] = buildGpyr_matrix_meta(sz, S, Zfilt, edges);
    state.Zpyr = zeros(size(data.pyramid_Zmeta.Ac,1),1);
  else
    state.Zpyr = zeros(sz);
  end

end


if params.SOLVE_LIGHT
  
  L_init = reshape(data.prior.light.gaussian.mu, 9, []);
  L_init = 0*L_init(:) + randn(size(L_init(:)))*0;%.01;
  
  if isfield(data.true, 'ims')
    
    L_init_white = data.prior.light.whiten_params.map * (L_init(:) - data.prior.light.whiten_params.mean(:));
    
    state.Ls_white = {};
    for im_i = 1:length(data.true.ims)
      state.Ls_white{im_i} = L_init_white;
    end
    
    
  else
    state.L_white = data.prior.light.whiten_params.map * (L_init(:) - data.prior.light.whiten_params.mean(:));
  end
  
end
  

if params.DEBUG_GRADIENT

  if params.SOLVE_SHAPE
    state.Zpyr = randn(size(state.Zpyr));
  end

  if isfield(state, 'Ls_white')
    for im_i = 1:length(data.true.ims)
      state.Ls_white{im_i} = randn(size(state.Ls_white{im_i}));
    end
  end
  
  if isfield(state, 'L_white');
    state.L_white = randn(size(state.L_white));
  end

  [dy,dh] = checkgrad(state, params.LOSSFUN, 10^-5, data, params);

end

OPTIONS = struct('Method', 'lbfgs', 'MaxIter', params.N_ITERS_OPTIMIZE, 'Corr', params.LBFGS_NCORR, 'F_STREAK', params.F_STREAK, 'F_PERCENT', params.F_PERCENT, 'progTol', params.PROG_TOL, 'optTol', params.OPT_TOL);
state = minFunc(params.LOSSFUN, state, OPTIONS, data, params);

state_bak = state;
[loss, junk, state] = feval(eval(['@', params.LOSSFUN]), state_bak, data, params);

state.final_loss = loss;


