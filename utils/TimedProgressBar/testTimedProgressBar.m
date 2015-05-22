targetWorkCount = 100;
barWidth= int32( targetWorkCount/3 );
p =  TimedProgressBar( targetWorkCount, barWidth, ...
    'Computing, wait for ', ', completed ', 'Concluded in ' );
parfor i=1:targetWorkCount      % could be just a for cycle
    pause(rand);                % Replace with real code
    p.progress;                 % Also percent = p.progress;
end
p.stop;                         % Also percent = p.stop;
