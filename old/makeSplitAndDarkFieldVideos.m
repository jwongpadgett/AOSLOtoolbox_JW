function makeSplitAndDarkFieldVideos

    % Substract videos frame by frame
    [filename, pathname] = uigetfile('*.avi','Select PMT2 and PMT3 videos','MultiSelect', 'on');

    PMT2Obj = VideoReader([pathname filename{1}]);
    PMT2struct = struct('cdata',zeros(PMT2Obj.Height,PMT2Obj.Width,'uint8'),'colormap',[]);

    PMT3Obj = VideoReader([pathname filename{2}]);
    PMT3struct = struct('cdata',zeros(PMT3Obj.Height,PMT3Obj.Width,'uint8'),'colormap',[]);

    NumberOfFrames = PMT3Obj.duration * PMT3Obj.FrameRate;
    splitIm = zeros(PMT2Obj.Height, PMT2Obj.width, NumberOfFrames);
    darkfieldIm = zeros(PMT2Obj.Height, PMT2Obj.width, NumberOfFrames);

    for i=1:NumberOfFrames
        PMT2struct(i).cdata = readFrame(PMT2Obj);
        PMT3struct(i).cdata = readFrame(PMT3Obj);
        p2=double(PMT2struct(i).cdata);
        p3=double(PMT3struct(i).cdata);
        splitIm(:,:,i)=uint8(255.*(((p2-p3)./(p2+p3)+1)./2));
        darkfieldIm(:,:,i)=uint8((p2+p3)./2);
    end

    splitIm(isnan(splitIm))=0;

    splitfilename = strcat(pathname,filename{1}(1:end-4),'_split_video.avi');
    v = VideoWriter(splitfilename,'Indexed AVI');
    v.Colormap = gray(256);
    open(v);
    writeVideo(v,splitIm);
    close(v);

    darkfieldfilename = strcat(pathname,filename{1}(1:end-4),'_darkfield_video.avi');
    v = VideoWriter(darkfieldfilename,'Indexed AVI');
    v.Colormap = gray(256);
    open(v);
    writeVideo(v,darkfieldIm);
    close(v);
end