function mkdirOptional(dirName)
% Create directory if it doesn't exist   
if(~exist(dirName,'dir'))
    mkdir(dirName);
end
end