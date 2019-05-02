function scaledframes = scaleframes(videoname,percenttouse,anchorflag)
% scaleframes.m. This is a utility program that can be used to scale values within a matrix/video to span values from 0 to 1.
% scaledframes.m subtracts a value and then divides the resultant values by the range between the maximum and minimum
% values in the original matrix. The user can also range over which the scaling occurs, by setting a value from the matrix as the maximum,
% all value above that value will be set as 1 after scaling. Similarly a minimum value can also be set.
%
% Usage: newmatrix = scale(videoname,minvalue,maxvalue)
%
% videoname     - The original video/matrix. A required input argument. If not provided by the user, the program queries the user
%                       to provide a video.
% percenttouse - The percentage of pixel luminances to use. If not provided the program uses the entire range of pixel luminances.
%                      Set to value lower than 1 if the pixel luminances within the input image are skewed
% anchorflag     - A flag that decides which pixel luminances to use when percenttouse is less than 1. if set to 1 then the program
%                      uses the lower percentage of pixel luminances, if set to 2 the middle percentage, if set to 3 the upper percentage.
%
% scaledframes - The name of the output video or a matrix of images scaled between 0 and 1.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War


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

if (nargin < 2) || isempty(percenttouse)
    percenttouse = 1;
end

if (nargin < 3) || isempty(anchorflag)
    anchorflag = 2;
end

if processfullvideo
    videoinfo = VideoReader(videoname); % Get important info of the avifile
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    numbervideoframes = videoinfo.FraemRate*videoinfo.Duration; % The number of frames in the video
    framerate = round(videoinfo.FrameRate);
    videotype = videoinfo.VideoFormat;
    
    firstframe = double(readFrame(videoinfo));
    if length(size(firstframe)) >= 3
        videotype = 'truecolor';
    end
    videoinfo.CurrentTime = 0;
    if strcmp(videotype,'truecolor'))
        disp('Video being analysed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
    
    mymap = repmat([0:255]' / 256,1,3);
    scaledvideoname = strcat(videoname(1:end - 4),'_scaled.avi');
    scaledvideoobject = VideoWriter(scaledvideoname,'Indexed AVI');
    scaledvideoobject.FrameRate = framerate;
    scaledvideoobject.Colormap = mymap;
    open(scaledvideoobject);
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);
    scaledframes = zeros(frameheight,framewidth,numbervideoframes);
end

percenttouse = max(min(percenttouse,1),0.01);
anchorflag = max(min(anchorflag,3),1);


if numbervideoframes > 1
    waitbarflag = 1;
    scaleprog = waitbar(0,'Scaling Frames');
    oldposition = get(scaleprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(scaleprog,'Position',newposition);
else
    waitbarflag = 0;
end
for framecounter = 1:numbervideoframes
    if processfullvideo
        oldmatrix = double(readFrame(videoinfo));
        if istruecolor
            oldmatrix = oldmatrix(:,:,1);
        end
    else
        oldmatrix = videoname(:,:,framecounter);
    end

    if percenttouse < 1
        numbofelements = numel(oldmatrix);
        if framecounter == 1
            switch anchorflag
                case 1
                    minindex = 1;
                    maxindex = round(numbofelements * percenttouse);
                case 2
                    medianindex = round(numbofelements / 2);
                    minindex = round(numbofelements * ((1 - percenttouse) / 2));
                    maxindex = round(numbofelements * (1 - ((1 - percenttouse) / 2)));
                case 3
                    minindex = round(numbofelements * (1 - percenttouse));
                    maxindex = numbofelements;
            end
            minindex = max(minindex,1);
            maxindex = min(maxindex,numbofelements);
        end

        sortedvalues = sort(oldmatrix(:),'ascend');

        minvalue = sortedvalues(minindex);
        maxvalue = sortedvalues(maxindex);
    else
        minvalue = min(oldmatrix(:));
        maxvalue = max(oldmatrix(:));
    end

    rangeofvalues = maxvalue - minvalue;
    newmatrix = (oldmatrix - minvalue) / rangeofvalues;
    newmatrix = min(max(newmatrix,0),1);

    if processfullvideo
        writeVideo(scaledvideoobject, im2frame(uint8(floor(scale(newmatrix) * 255) + 1),mymap));
    else
        scaledframes(:,:,framecounter) = newmatrix;
    end

    if waitbarflag
        prog = framecounter / numbervideoframes;
        waitbar(prog,scaleprog);
    end
end

if waitbarflag
    close(scaleprog);
end

if processfullvideo
    close(scaledvideoobject);
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No data to scale,stoping program');
    error('Type ''help scaleframes'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------