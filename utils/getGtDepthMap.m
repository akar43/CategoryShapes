function [] = getGtDepthMap(fnames,statesDir,annotationsDir,depthMapsDir,cadModels)
%GETGTDEPTHMAP Summary of this function goes here
%   Detailed explanation goes here

parfor i=1:length(fnames)
    warning off;
    disp(i);
    state=load(fullfile(statesDir,fnames{i}));
    state=state.state;
    dmap = zeros(size(state.mask));
    voc_id = fnames{i}(1:end-6);
    recordFile = fullfile(annotationsDir,[voc_id '.mat']);
    dmapFile = fullfile(depthMapsDir,fnames{i});
    if(~exist(dmapFile,'file'))
        if(exist(recordFile,'file'))
            record = load(recordFile);
            record = record.record;
            index = 0;
            for j=1:length(record.objects)
                bb = record.objects(j).bbox;
                bb2 = state.modelbbox;
                bb2(3:4)=bb2(3:4)+bb(1:2);
                if(sum(abs(bb-bb2))<=4)
                    index = j;
                end
            end
            if(index)
                vertex = cadModels(record.objects(index).cad_index).vertices;
                face = cadModels(record.objects(index).cad_index).faces;
                [x2d,D] = project_3d(vertex, record.objects(index));
                if(size(D,1)>0)
                    dmap = meshToDepth([round(x2d),-D],face,size(state.mask));
                end
            end
        end
        savefunc(dmapFile,dmap);
    end
end
end

function savefunc(file,dmap)
    save(file,'dmap');
end
