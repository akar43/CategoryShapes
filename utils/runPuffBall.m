function runPuffBall(classes,tId)
    globals
    for i=1:length(classes)
        puffBallDir = fullfile(cachedir,classes{i},'puffBallMeshesGt');
        disp(puffBallDir);
        mkdir(puffBallDir);
        fnames = []; fnamesFull = [];
        class = classes{i};
        jobDirs = getJobDirs(classes{i},tId,'statesDirTest');
        for j=1:length(jobDirs)
            fnames = [fnames getFileNamesFromDirectory(fullfile(cachedir,class,jobDirs{j}),'types',{'.mat'})];
            fnamesFull = [fnamesFull getFileNamesFromDirectory(fullfile(cachedir,class,jobDirs{j}),'types',{'.mat'},'mode','path')];
        end
        p =  TimedProgressBar( length(fnames), round(length(fnames)/4), ...
        'Puffball: Remaining ', ', Completed ', 'Puffball Time: ' );
        parfor j=1:length(fnames)
            if(exist(fullfile(puffBallDir,fnames{j}),'file'))
                continue;
            end
            state = load(fnamesFull{j}); state=state.state;
            [faces,vertices] = puffball(state.mask);            
            savefunc(fullfile(puffBallDir,fnames{j}),struct('faces',faces,'vertices',vertices));
            p.progress();
        end
        p.stop();
    end
end

function savefunc(fname,fv)
    save(fname,'fv');
end
    