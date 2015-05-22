function deleteOptional(fname)
    if(exist(fname,'file'))
        delete(fname);
    elseif(exist(fname,'dir'))
        rmdir(fname);
    else
        return;
    end     
end