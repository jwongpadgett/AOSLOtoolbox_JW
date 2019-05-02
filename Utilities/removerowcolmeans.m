function frameswithnomean = removerowcolmeans(videoname,smoothfactor,directionflag,verbose)

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

if (nargin < 2) || isempty(smoothfactor)
    name = 'Input for removerowcolmeans.m';
    numlines = 1;
    prompt = {'Smooth Factor'};
    defaultanswer = {'1.5'};

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        disp('You have not provided the smooth factor, using default value of 1.5');
        smoothfactor = 1.5;
    else
        smoothfactor = str2double(userresponse{1});
    end
end

if (nargin < 3) || isempty(directionflag);
    directionflag = 0;
end

if (nargin < 4) || isempty(verbose);
    verbose = 0;
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    videoframerate = round(videoinfo.FrameRate);
    numbervideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;
    mycolormap = repmat([0:255]' / 256,1,3);
    moviestruct = repmat(struct('cdata',zeros(frameheight,framewidth),'colormap',mycolormap),numbervideoframes,1);
    frameswithnomean = strcat(videoname(1:end - 4),'_indmeanrem.avi');
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);
    frameswithnomean = zeros(frameheight,framewidth,numbervideoframes);
end

if numbervideoframes > 1
    waitbarflag = 1;
    meanprog =waitbar(0,'Removing Row and Column Means');
    oldposition = get(meanprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex (oldposition(4) + 20) ...
        oldposition(3) oldposition(4)];
    set(meanprog,'Position',newposition);
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

%     colmean = repmat(mean(currentframe,2),1,framewidth);
%     rowmean = repmat(mean(currentframe,1),frameheight,1);
    
    switch directionflag
        case 0
            averageframe = (repmat(mean(currentframe,2),1,framewidth) + repmat(mean(currentframe,1),frameheight,1))  / 2;
        case 1
            averageframe = repmat(mean(currentframe,2),1,framewidth);
        case 2
            averageframe = repmat(mean(currentframe,1),frameheight,1);
    end
    
    averageframe = smoothimage(averageframe,smoothfactor);
    averageframerange = max(averageframe(:)) - min(averageframe(:));
    averageframe = floor(scale(averageframe) * (averageframerange - 1)) + 1;
    averageframe = averageframe - mean(averageframe(:));
    
    if verbose
        if framecounter == 1
            colormaptouse = repmat([0:255]' / 256,1,3);
            figurehandle = figure;
            imagehandle = image(scale(averageframe) * 255);
            axishandle = gca;
            titlehandle = title(['Current Frame: ',num2str(framecounter),' of ',num2str(numbervideoframes),' Frames.']);
            colormap(colormaptouse);
            axis off;
            truesize;

            set(imagehandle,'EraseMode','none')
        else
            figure(figurehandle);
            set(imagehandle,'CData',scale(averageframe) * 255);
            set(titlehandle,'String',['Current Frame ',num2str(framecounter),' of ',num2str(numbervideoframes),' Frames.']);
        end
    end

    meanofframe = mean(currentframe(:));
    rmsofframe = std(currentframe(:));
    newframe2add = (currentframe - meanofframe) - averageframe;
    newframe2add = ((newframe2add - mean(newframe2add(:))) / std(newframe2add(:)) * rmsofframe) +  meanofframe;
    newframe2add = uint8(min(max(newframe2add,1),255));
%     newframe2add = uint8(min(max(floor((scale_nomean(newframe2add) * (meanofframe - 1)) + meanofframe),1),255));

    moviestruct(framecounter).cdata = newframe2add;

    if waitbarflag
        prog = framecounter / numbervideoframes;
        waitbar(prog,meanprog);
    end
end

if waitbarflag
    close(meanprog);
end

movie2avi(moviestruct,frameswithnomean,'Compression','None','FPS',videoframerate);


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help getblinkframes'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function newmatrix = scale_nomean(oldmatrix)

newmatrix = oldmatrix - mean(oldmatrix(:));
newmatrix = newmatrix / max(abs(min(newmatrix(:))),max(newmatrix(:)));
%--------------------------------------------------------------------------