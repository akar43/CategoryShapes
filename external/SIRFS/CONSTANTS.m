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



MIT_LABORATORY_FOLDER = 'data/MIT-Berkeley-Laboratory/';
MIT_NATURAL_FOLDER = 'data/MIT-Berkeley-Natural/';

assert(all(ismember(MIT_TEST, MIT_ALL)))
assert(all(ismember(MIT_TRAIN, MIT_ALL)))
assert(all(ismember(MIT_ALL, union(MIT_TEST, MIT_TRAIN))))
assert(isempty(intersect(MIT_TRAIN, MIT_TEST)))


params.Z_MEDIAN_HALFWIDTH = 2;
params.A_MEDIAN_HALFWIDTH = 2;

params.A_SMOOTH_EPSILON = {10^-4};
params.Z_SMOOTH_EPSILON = {10^-4};

params.OUTPUT_FILENAME = [];

params.SOLVE_LIGHT = 1;
params.SOLVE_SHAPE = 1;

params.NATURAL_ILLUMINATION = 1;
params.USE_COLOR_IMAGES = 1;

params.WHITEN_LIGHT = 1;
params.MAX_PYR_DEPTH = inf;

params.USE_INIT_Z = false;

params.RESIZE_INPUT = 1;

params.PRIOR_MODEL_STRING = 'prior.mat';

params.DUMP_OUTPUT = '';
params.DUMP_FINAL = false;

params.DEBUG_GRADIENT = 0;
params.USE_NUMERICAL = 0;
params.DO_DISPLAY = 1;
params.DISPLAY_NFUN = 1;
params.DISPLAY_PERIOD = 15;

params.LBFGS_NCORR = 10;
params.N_ITERS_OPTIMIZE = 2000;
params.F_STREAK = 5;
params.F_PERCENT = .005;
params.PROG_TOL = 10^-9;
params.OPT_TOL = 10^-5;

params.MAX_N_EVAL = inf;
params.N_EVAL_SKIP = 0;

params.DO_CHEAT = 0;

params.SHAPE_FROM_SHADING = 0;

params.GLOBAL_VARS = {'Z_last_global', 'Ls_white_global', 'global_Ls_dependency', 'global_Ls_weights', 'global_in_line_search', 'global_L_active_idx', 'global_greedy_head', 'global_loss_best', 'global_P', 'global_light_fid', 'last_display', 'num_display', 'display_figure', 'global_Z_last', 'global_L_best', 'global_L', 'global_state', 'global_errors', 'num_display', 'last_Zprior', 'global_losses', 'global_losses_history'};

params.PYR_FILTER = [1;3;3;1]/sqrt(8);
params.PYR_EDGES = 'repeat';

