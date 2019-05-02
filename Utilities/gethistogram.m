function [allhistograms,averagehistogram,bincenters] = gethistogram(videoname,verbose)
% gethistogram.m. This is a utility program designed to obtain the
% histogram of all the frames passed to the program. The user can pass
% either a string that points to a valid video file or a 3 dimensional
% matrix of 2 dimensional frame data.
%
% Usage: [allhistograms,averagehistogram,bincenters] =
%                                   gethistogram([videoname,verbose]);
% videoname             - This input argument either is a 3 dimensional set
%                         of 2 dimensional frame data or a string that
%                         is the path of a valid video file. If neither is
%                         provided the program queries the user to select a
%                         video file.
% verbose               - If set to 1 the program plots the histograms of
%                         the frames. If set to 0 then the program provides
%                         no feedback. Default is 0.
%
% allhistograms         - The histogram of the individual frames. This is a
%                         3 dimensional matrix. The first layer is the
%                         raw frequency histogram data, while the second
%                         layer is the percentage frequency data.
% averagehistogram      - The average histogram from all the frames. It is
%                         also a 2 layer 3 dimensional matrix.
% bincenters            - The centers of the bins that were used to bin the
%                         histograms.
%
%
% Program Creator: Girish Kumar


if (nargin < 1) || isempty(videoname)
    [videoname,avifilename,avipath] = getvideoname();
    processfullvideo = 1;
else
    if ischar(videoname)
        processfullvideo = 1;
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [videoname,avifilename,avipath] = getvideoname();
        end
    else
        processfullvideo = 0;
    end
end

if (nargin < 2) || isempty(verbose)
    verbose = 1;
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    numframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;

    if strcmp(videotype,'truecolor')
        disp('Video being analysed is a truecolor video, this program can scale only 8 bit videos!!');
        warning('Using only the first layer of the video during scaling');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
else
    numframes = size(videoname,3);
end

bincenters = [5:10:260]';
numbins = length(bincenters);

allhistograms = zeros(numbins,numframes,2);

histprog = waitbar(0,'Getting Frame Histograms');
for framecounter = 1:numframes
    if processfullvideo        
        videoinfo = VideoReader(videoname);
        currentframe = double(readFrame(videoinfo));
        if istruecolor
            currentframe = currentframe(:,:,1);
        end
    else
        currentframe = videoname(:,:,framecounter);
    end
    
    framehist = hist(currentframe(:),bincenters);
    allhistograms(:,framecounter,1) =  framehist(:);
    allhistograms(:,framecounter,2) = framehist(:) / prod(size((currentframe))); %#ok<PSIZE>
    
    prog = framecounter / numframes;
    waitbar(prog,histprog);
end

close(histprog);

averagehistogram = mean(allhistograms,2);

filenametosave = strcat(videoname(1:end - 4),'_histdata.m');
save(filenametosave,'bincenters','allhistograms','averagehistogram');

if verbose
    figure;
    plot(bincenters,allhistograms(:,:,2));
    
    figure
    plot(bincenters,averagehistogram(:,:,2));
    hold on;
    plot(bincenters,averagehistogram(:,:,2),'*');
    hold off;
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help gaussbandfilter'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------