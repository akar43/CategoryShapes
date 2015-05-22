function [dy,dh] = checkgrad(X_struct, f, e, varargin)

% checkgrad checks the derivatives in a function, by comparing them to finite
% differences approximations. The partial derivatives and the approximation
% are printed and the norm of the diffrence divided by the norm of the sum is
% returned as an indication of accuracy.
%
% usage: checkgrad('f', X, e, P1, P2, ...)
%
% where X is the argument and e is the small perturbation used for the finite
% differences. and the P1, P2, ... are optional additional parameters which
% get passed to f. The function f should be of the type 
%
% [fX, dfX] = f(X, P1, P2, ...)
%
% where fX is the function value and dfX is a vector of partial derivatives.
%
% d - norm error
% dy - analytic   
% dh - numerical
%  
% Carl Edward Rasmussen, 2001-08-01.

[X_vec, X_template] = struct2vector(X_struct);

% [y, dy] = feval(f, vector2struct(X_vec + val*grad, X_template), varargin{:});
tic
[y, dy_struct] = feval(f, X_struct, varargin{:});
y = sum(y);
dy = struct2vector(dy_struct);
time1 = toc;

% keyboard

fig = figure;
dh = nan(length(X_vec),1) ;
t = cputime;
n_char = 0;
time_step = 5;
DIRECTION = 'forwards';
% DIRECTION = 'backwards';
% if length(X_vec) > 50000
% 
% %   SKIP = 10;
% %   START = 1;%14400;%1;
% 
%   SKIP = 2000;
%   START = 1;%14400;%1;
% 
% %   SKIP = 1000;
% %   START = 30000;%14400;%1;
% else
%   SKIP = 1;%100;
%   START = 1;%4300;%1;
% end

START = 1;
n = max(40, 30/time1) % Evalulate for ~15 seconds
SKIP = ceil(length(X_vec)/n);

% START = 20210;
% SKIP = 1;

if strcmp(DIRECTION, 'backwards');
  idx = length(X_vec):-SKIP:1;
elseif strcmp(DIRECTION, 'forwards');
  idx = START:SKIP:length(X_vec);
end

% idx = length(X_vec):-1:(length(X_vec)-8);
% DIRECTION = 'backwards';
% SKIP = 1;

for j = idx
  
  dx = zeros(length(X_vec),1);
  dx(j) = dx(j) + e;                               % perturb a single dimension
  
  [y2] = feval(f, vector2struct(X_vec + dx, X_template), varargin{:});
  [y1] = feval(f, vector2struct(X_vec - dx, X_template), varargin{:});
  
  y1 = sum(y1(:));
  y2 = sum(y2(:));
  
  dh(j) = (y2 - y1)/(2*e);

  if ((cputime - t) > time_step) || (j == idx(end))
    t = cputime;
    figure(fig)
    clf
    subplot(2,1,1);
    if strcmp(DIRECTION, 'backwards');
      plot(j:SKIP:length(dy), dy(j:SKIP:end), 'bx-'); hold on;
      plot(j:SKIP:length(dy), dh(j:SKIP:end), 'r-');
    elseif strcmp(DIRECTION, 'forwards');
      plot(START:SKIP:j, dy(START:SKIP:j), 'bx-'); hold on;
      plot(START:SKIP:j, dh(START:SKIP:j), 'r-');
    end
    legend('analytical', 'numerical');
    ylabel('gradient');
    subplot(2,1,2);
    if strcmp(DIRECTION, 'backwards');
      plot(j:SKIP:length(dy), dy(j:SKIP:end) - dh(j:SKIP:end), 'gx-');
    elseif strcmp(DIRECTION, 'forwards');
      plot(START:SKIP:j, dy(START:SKIP:j) - dh(START:SKIP:j), 'gx-');
    end
    ylabel('error')
    drawnow

    s = [num2str(100*j/length(X_vec), '%0.1f'), '%, '];
    if n_char + length(s) >= 80
      fprintf('\n')
      n_char = 0;
    end
    fprintf('%s', s);
    n_char = n_char + length(s);
    
  end
end
fprintf('\n');

% 'numerical:'
% dh(idx)'
% 
% 'analytical:'
% dy(idx)'

'delta:'
err = dy(idx)' - dh(idx)';

'mult:'
mult = dy(idx)' ./ dh(idx)';

for p = [1, 5, 20, 50, 90, 95, 99, 99.9, 99.99]
  fprintf('%g percentile err: \t%e\n', p, prctile(abs(err), p));
end


% % disp([dy dh])                                          % print the two vectors
% d = norm(dh-dy)/norm(dh+dy);       % return norm of diff divided by norm of sum
