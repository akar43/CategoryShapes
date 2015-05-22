function validNames = getJobDirs(class,id,files)
    globals
    clsdir = fullfile(cachedir,class);
    tmp = dir(clsdir);
    validNames = {};
    for i=1:length(tmp)
        if(~isempty(regexp(tmp(i).name,sprintf('%s\\d%s$',files,id),'once')))
            validNames = [validNames;tmp(i).name];
        end
        if(~isempty(regexp(tmp(i).name,sprintf('%s\\d%s.mat$',files,id),'once')))
            validNames = [validNames;tmp(i).name];
        end
    end
end
