function scaledframes = scalemeanrms(videoname,verbose)
% gotta add functionality to get user input on the range of data to use.
if (nargin < 1) || isempty(videoname)
    [videoname,avifilename,avipath] = getvideoname;
    processfullvideo = 1;
else
    if ischar(videoname)
        processfullvideo = 1;
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [videoname,avifilename,avipath] = getvideoname;
        else
            maxslashindex = 0;
            for charcounter = 1:length(videoname)
                testvariable = strcmp(videoname(charcounter),'\');
                if testvariable
                    maxslashindex = charcounter;
                end
            end
            avifilename = videoname(maxslashindex + 1:end);
        end
    else
        processfullvideo = 0;
    end
end

if (nargin < 2) || isempty(verbose)
    verbose = 0;
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    numbervideoframes = videoinfo.FraemRate*videoinfo.Duration;
    videotype = videoinfo.Type;
    framerate = round(videoinfo.FrameRate);

    firstframe = double(readFrame(videoinfo));
    if length(size(firstframe)) >= 3
        videotype = 'truecolor';
    end
    clear firstframe;
    videoinfo.CurrentTime = 0;

    mymap = repmat([0:255]' / 255,1,3);
    scaledframes = strcat(videoname(1:end - 4),'_rscaled.avi');
    scaledvideoobject = VideoWriter(scaledframes,'Indexed AVI');
    scaledvideoobject.FrameRate = framerate;
    scaledvideoobject.Colormap = mymap;
    open(scaledvideoobject);
else
    istruecolor = 0;
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);

    scaledframes = zeros(frameheight,framewidth,numbervideoframes);
end

if numbervideoframes > 1
    waitbarflag = 1;
    processprog = waitbar(0,'Scaling Images');
    oldposition = get(processprog,'Position');

    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(processprog,'Position',newposition);
else
    waitbarflag = 0;
end

for framecounter = 1:numbervideoframes
    if processfullvideo
        currentframe = double(readFrame(videoinfo));
        if strcmp(videotype,'truecolor') || (numel(size(currentframe)) == 3)
            currentframe = currentframe(:,:,1);
        end
    else
        currentframe = videoname(:,:,framecounter);
    end

    sortedframedata = sort(currentframe(:));
    numofpixelsinframe = framewidth * frameheight;
    firstelementtouse = sortedframedata(round(0.015 * numofpixelsinframe));
    lastelementtouse = sortedframedata(round(0.985 * numofpixelsinframe));

    currentframe = max(min(currentframe,lastelementtouse),firstelementtouse);

    meanofframe = mean(currentframe(:));
    rmsofframe = std(currentframe(:));

    scaledframe = currentframe - meanofframe;
    scaledframe = (scaledframe/ rmsofframe);
    scalefactortouse = max(abs(min(scaledframe(:))),max(scaledframe(:)));
    rmstouse = 126 / scalefactortouse;
    scaledframe = scaledframe * rmstouse;
    scaledframe = (scaledframe - mean(scaledframe(:))) + 128;
    if processfullvideo
        writeVideo(scaledvideoobject, min(max(scaledframe,1),255));
    else
        scaledframes(:,:,framecounter) = scaledframe;
    end

    if waitbarflag
        prog = framecounter / numbervideoframes;
        waitbar(prog,processprog);
    end
end

if waitbarflag
    close(processprog);
end

if processfullvideo
    close(scaledvideoobject);
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No data to scale,stoping program');
    error('Type ''help scalemeanrms'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------