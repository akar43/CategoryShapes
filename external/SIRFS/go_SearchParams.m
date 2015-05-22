

% Some simple code for sloppily tuning parameters. Here it's being used to train a SIFS model

clear all;

EVAL_STRING_BASE = 'params.SHAPE_FROM_SHADING = 1; params.NATURAL_ILLUMINATION = 1; params.USE_COLOR_IMAGES = 1; params.DO_DISPLAY = 0;  params.EVAL_NAMES = MIT_TRAIN; ';

params.multipliers.sfs.power = { 1.000000 };
params.multipliers.sfs.mult = { 28.284300 };
params.multipliers.sfs.epsilon = { 0.000244 };

params.multipliers.height.smooth = { 1.414200 };
params.multipliers.height.slant = { 1.414200 };
params.multipliers.height.contour_mult = { 2.828400 };
params.multipliers.height.contour_power = { 0.500000 };

params.multipliers.light.gaussian = { 4.000000 };

MULT_BASE = sqrt(2);

VARIABLE_NAMES = {'params.multipliers.sfs.power', 'params.multipliers.sfs.mult', 'params.multipliers.sfs.epsilon', 'params.multipliers.height.smooth', 'params.multipliers.height.slant', 'params.multipliers.height.contour_mult', 'params.multipliers.height.contour_power', 'params.multipliers.light.gaussian'};

EVAL_STRING = EVAL_STRING_BASE;
for i_variable = 1:length(VARIABLE_NAMES)
  EVAL_STRING = [EVAL_STRING, [VARIABLE_NAMES{i_variable}, ' = { ', num2str(eval([VARIABLE_NAMES{i_variable}, '{1}'])), ' }; ']];
end

results = go_MIT(EVAL_STRING);

err_init = exp(mean(log(cellfun(@(x) x.err.avg, results))));

err_best = err_init;
params_best = params;

N_ITERS = 10;

err_trace = [nan, nan, err_init];
search_iter = 1;
while search_iter < (length(VARIABLE_NAMES) * 10)
  
  params = params_best;
  
  i_variable = floor(mod((search_iter-1)/2, length(VARIABLE_NAMES)) + 1);
  log_mult = mod(search_iter, 2)*2-1;%2*(floor(mod(search_iter-1, length(VARIABLE_NAMES)*2) / length(VARIABLE_NAMES))) - 1;
  mult = MULT_BASE.^log_mult;
  val = mult * eval([VARIABLE_NAMES{i_variable}, '{1}']);
  eval([VARIABLE_NAMES{i_variable}, ' = { ', num2str(val), ' }; '])
  
  EVAL_STRING = EVAL_STRING_BASE;
  for i = 1:length(VARIABLE_NAMES)
    EVAL_STRING = [EVAL_STRING, [VARIABLE_NAMES{i}, ' = { ', num2str(eval([VARIABLE_NAMES{i}, '{1}'])), ' }; ']];
  end
  
  results = go_MIT(EVAL_STRING);
  
  err = exp(mean(log(cellfun(@(x) x.err.avg, results))));
  
  err_trace(end+1,:) = [i_variable, val, err]
  
  if err < err_best
    err_best = err;
    params_best = params;
    if log_mult > 0
      search_iter = search_iter + 1;
    end
  end
  
  search_iter = search_iter + 1;
  
end


params = params_best;

for i = 1:length(VARIABLE_NAMES)
  fprintf('%s = { %f };\n', VARIABLE_NAMES{i}, eval([VARIABLE_NAMES{i}, '{1}']));
end


