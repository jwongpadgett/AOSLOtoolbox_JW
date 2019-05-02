function varargout = deinterlacevideo(oldvideoname,orderflag,splitflag)
% deinterlacevideo.m. This is a utility program that takes a interlaced video and splits each frame into its component frames.
%
% Usage: newvideoname = deinterlacevideo(oldvideoname,[orderflag])
% oldvideoname      - The string that points to a interlaced video. If this argument is empty or not provided the program queries
%                           the user to provide the path and name of the video.
% orderflag            - A flag that sets the order that the interlaced set of frames gets placed back in the new video. If set to 0
%                           then frame data from odd lines are placed before the even frame data from even lines. If set to 1 then the
%                           opposite is done. Default is 0.
% splitflag             - This flag determines if the video is split into two component videos or is maintained as a single video. If set to
%                           1 then the program output two different videos - one from the odd lines and one from the even lines otherwise
%                           a single video is the output. Default is 0.
%
% newvideoname    - The string that contains the full pathname of the de-interlaced video .
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

rand('state',sum(100 * clock));

if (nargin < 2) || isempty(orderflag)
    orderflag = 0;
end

if (nargin < 3) || isempty(splitflag)
    splitflag = 0;
end

if (nargin < 1) || isempty(oldvideoname)
    [oldvideoname,videofilename,videopath] = getvideoname;
else
    if ischar(oldvideoname)
        if ~exist(oldvideoname,'file')
            warning('Video name does not point to a valid file');
            [oldvideoname,videofilename,videopath] = getvideoname;
        end
    else
        warning('deinterlacevideo.m requires a string that points to a video file');
        disp('Requesting video name');
        [oldvideoname,videofilename,videopath] = getvideoname;
    end
end

vid_obj = VideoReader(videoname);
framewidth = vid_obj.Width;
frameheight = vid_obj.Height;
videotype = videoinfo.ImageType;
framerate = round(videoinfo.FrameRate);
numframes = round(vid_obj.FrameRate*vid_obj.Duration);

if strcmp(videotype,'TrueColor')
    disp('Video being analysed is a truecolor video, this program can de-interlace only 8 bit videos!!');
    warning('Using only the first layer of the video during conversion');
    istruecolor = 1;
else
    istruecolor = 0;
end

oddlineindices = [1:2:frameheight];
evenlineindices = [2:2:frameheight];

if length(oddlineindices) ~= length(evenlineindices)
    if length(oddlineindices) > length(evenlineindices)
        framesizeflag = 1;
    else
        framesizeflag = 2;
    end
else
    framesizeflag = 0;
end

mymap = repmat([0:255]'/ 256,1,3);
if splitflag
    newvideoname_odd = strcat(oldvideoname(1:end - 4),'_oddlines.avi');
    newvideoname_even = strcat(oldvideoname(1:end - 4),'_evenlines.avi');
    
    newvideoobject_odd = VideoWriter(newvideoname_odd, 'Indexed AVI');
    newvideoobject_even = VideoWriter(newvideoname_even, 'Indexed AVI');
    newvideoobject_odd.FrameRate = round(framerate * 2);
    newvideoobject_even.FrameRate = round(framerate * 2);
    newvideoobject_odd.Colormap = mymap;
    newvideoobject_even.Colormap = mymap;
    open(newvideoobject_odd);
    open(newvideoobject_even);
else
    newvideoname = strcat(oldvideoname(1:end - 4),'_deinterlaced.avi');
    newvideoobject = VideoWriter(newvideoname, 'Indexed AVI');
    newvideoobject.FrameRate = round(framerate * 2);
    newvideoobject.Colormap = mymap;
    open(newvideoobject);
end


deinterlaceprog = waitbar(0,'De-interlacing the video');
oldposition = get(deinterlaceprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(deinterlaceprog,'Position',newposition);

oldvidObj = VideoReader(oldvideoname);
for framecounter = 1:numframes
    currentframe = double(readFrame(oldvidObj));

    if istruecolor || (length(size(currentframe)) >= 3)
        currentframe = currentframe(:,:,1);
    end

    oddlineframe = currentframe(oddlineindices,:);
    evenlineframe = currentframe(evenlineindices,:);

    if framesizeflag
        fullwidth = framewidth;
        fullheight = max(size(oddlineframe,1),size(evenlineframe,1));
        
        randindices = floor(rand(fullheight * fullwidth,1) * (numel(currentframe) - 1)) + 1;
        randpixelvalues = currentframe(randindices);
        
        randframe = reshape(randpixelvalues,fullheight,fullwidth);

        switch framesizeflag
            case 1
                tempframe = randframe;
                tempframe(2:end,:) = evenlineframe;
                evenlineframe = tempframe;
            case 2
                tempframe = randframe;
                tempframe(1:size(oddlineframe,1),:) = oddlineframe;
                oddlineframe = tempframe;
        end
    end

    if splitflag        
        writeVideo(newvideoobject_odd, uint8(oddlineframe));
        writeVideo(newvideoobject_even, uint8(evenlineframe));
    else
        if orderflag
            firstframetoadd = evenlineframe;
            secondframetoadd = oddlineframe;
        else
            firstframetoadd = oddlineframe;
            secondframetoadd = evenlineframe;
        end
        writeVideo(newvideoobject, firstframetoadd);
        writeVideo(newvideoobject, secondframetoadd);
    end

    prog = framecounter / numframes;
    waitbar(prog,deinterlaceprog);
end

close(deinterlaceprog);

if splitflag
    close(newvideoobject_odd);
    close(newvideoobject_even);
else
    close(newvideoobject);
end

if nargout > 0
    if splitflag
        varargout{1} = newvideoname_odd;
        varargout{2} = newvideoname_even;
    else
        varargout{1} = newvideoname;
    end
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()


[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to deinterlace');
if videofilename == 0
    disp('No video to deinterlace,stoping program');
    error('Type ''help deinterlacevideo'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------