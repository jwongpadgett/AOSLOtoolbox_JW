function alterframerate(videoname,newframerate)
% alterframerate.m. This is a utilty program that changes the base frame rate of a video. The program should
% not be used to change the frame rate of videos that will be analysed, it is more of use to alter framerates of
% videos that are used in presentations. The video that has the new frame rate will be saved in the same
% directory as the original video and will have the tag "_newfr" attached the original name prior to the file
% extension.
%
% Usage: alterframerate([videoname],[newframerate])
% videoname      - The string that is the path and name of the video whose framerate will be altered. If this
%                  argument is empty or not provided the function will query the user to choose a vaild video file.
%                  The user can pass a cell array of strings to the program, which will then batch process the framrate
%                  alteration
% newframerate  - The new frame rate that is desired. If the user does not provide this, the function will query the user.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War


% First get the video to alter
if (nargin < 1) || isempty(videoname) || ~(ischar(videoname) || iscell(videoname))
    [videoname,avifilename,avipath] = getvideoname;
else
    if ischar(videoname)
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [videoname,avifilename,avipath] = getvideoname;
        end
    else
        warning('alterframerate.m requires a string that points to a video file');
        disp('Requesting video name');
        [videoname,avifilename,avipath] = getvideoname;
    end
end

if (nargin < 2) || isempty(newframerate)
    prompt = {'Enter the required framerate'};
    name = 'Input for alterframerate function';
    numlines = 1;
    defaultanswer = {'20'};

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        disp('You need to enter a framerate');
        warning('Using default - 20 Hz');
        newframerate = 20;
    else
        newframerate = str2double(userresponse{1});
    end
end

if iscell(videoname)
    numvideostoalter = length(videoname);
else
    numvideostoalter = 1;
end

if numvideostoalter > 1
    allvidprog = waitbar(0,'Batch Progress');
    oldposition = get(allvidprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(allvidprog,'Position',newposition);
end

singlevidprog = waitbar(0,'Altering the Framerate of Video');
oldwaitbarposition = get(singlevidprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,(oldwaitbarposition(4) + 20),...
    oldwaitbarposition(3),oldwaitbarposition(4)];
set(singlevidprog,'Position',newwaitbarposition);

for videocounter = 1:numvideostoalter
    currentvideoname  = videoname{numvideostoalter};
    newvideoname = strcat(videoname(1:end - 4),'_newfrmrt.avi');
    
    % Obtain parameters of old video
    vid_obj = VideoReader(currentvideoname);
    numbervideoframes = round(vid_obj.FrameRate*vid_obj.Duration);
    
    newvideoobject = VideoWriter(newvideoname,'Grayscale AVI');
    newvideoobject.FrameRate = newframerate;
    open(newvideoobject);
    for singlevidcounter = 1:numbervideoframes
        currentframe = readFrame(vid_obj);
        writeVideo(newvideoobject, currentframe);
        
        prog = singlevidcounter / numbervideoframes;
        waitbar(prog,singlevidprog);
    end
    
    close(newvideoobject);
    
    if exist('allvidprog','var')
        prog = videocounter / numvideostoalter;
        waitbar(prog,allvidprog);
    end
end

close(singlevidprog);
if exist('allvidprog','var')
    close(allvidprog);
end


%--------------------------------------------------------------------------
function [fullvideoname,videoname,videopath] = getvideoname()

[videoname,videopath] = uigetfile('*.avi','Please enter filename of video to alter frame rate');
if videoname == 0
    disp('No video to alter,stoping program');
    error('Type ''help alterframerate'' for usage');
end
fullvideoname = strcat(videopath,videoname);
%--------------------------------------------------------------------------