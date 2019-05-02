function blinkframes = getblinkframes_manual(videoname,methodtouse,verbose)

% Get the name of the video file or the 3-D array of frames
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
        if length(size(videoname)) ~= 3
            disp('Provide a video name or a 3 dimensional array of frames');
            error('Type ''help getblinkframes'' for usage');
        end
    end
end

if (nargin < 2) || isempty(methodtouse)
    methodbutton = questdlg('What Method do you want to use','Method Question','Mean','Std Deviation','Both','Mean');
    methodtouse = lower(methodbutton(1));
else
    methodtouse = lower(methodtouse(1));
end

if nargin < 3 || isempty(verbose)
    verbose = 1;
end

if ischar(methodtouse)
    switch methodtouse
        case 'm'
            thresholdtoget = 1;
        case 's'
            thresholdtoget = 2;
        case 'b'
            thresholdtoget = 3;
    end
else
    methodtouse = max(min(methodtouse,3),1);
    thresholdtoget = methodtouse;
end

if processfullvideo
    videoinfo = VideoReader(videoname); % Get important info of the avifile
    numbervideoframes = videoinfo.FraemRate*videoinfo.Duration; % The number of frames in the video
    videotype = videoinfo.VideoFormat;
    
    if strcmp(videotype,'truecolor') || (length(size(double(readFrame(videoinfo)))) == 3)
        disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
else
    numbervideoframes = size(videoname,3);
end

framemeans = zeros(numbervideoframes,1);
framestds = zeros(numbervideoframes,1);

blinkprog = waitbar(0,'Getting Frame Statistics');
oldposition = get(blinkprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(blinkprog,'Position',newposition);

for framecounter = 1:numbervideoframes
    if processfullvideo
        videoinfo = VideoReader(videoname);
        tempframe = double(readFrame(videoinfo));
        
        if istruecolor
            tempframe = tempframe(:,:,1);
        end
    else
        tempframe = videoname(:,:,framecounter);
    end

    framemeans(framecounter) = mean(tempframe(:));
    framestds(framecounter) = std(tempframe(:));

    prog = framecounter / numbervideoframes;
    waitbar(prog,blinkprog);

end
close(blinkprog);

blinkthreshold = [];
initialblinkframes_mean = [];
initialblinkframes_std = [];

thresholdfigure = figure;

if (thresholdtoget == 1) || (thresholdtoget == 3)
    figure(thresholdfigure);
    plot([1:numbervideoframes]',framemeans);
    if processfullvideo
        title(avifilename,'Interpreter','None');
    end
    [x y] = ginput(1);

    blinkthreshold = [blinkthreshold;round(y)];
    initialblinkframes_mean = find(framemeans <= round(y)) + 1;
end

if (thresholdtoget == 2) || (thresholdtoget == 3)
    figure(thresholdfigure);
    plot([1:numbervideoframes]',framestds);
    if processfullvideo
        title(avifilename,'Interpreter','None');
    end
    [x y] = ginput(1);

    blinkthreshold = [blinkthreshold;round(y)];

    initialblinkframes_std = find(framestds <= round(y));
end

close(thresholdfigure);

initialblinkframes = union(initialblinkframes_mean(:),initialblinkframes_std(:));
blinkframes = repmat(initialblinkframes(:),1,5) +...
    repmat([-2:2],length(initialblinkframes),1);
blinkframes = unique(min(max(blinkframes(:),1),numbervideoframes));

framesafterblinks = unique(min(setdiff(blinkframes + 1,blinkframes),numbervideoframes));

if processfullvideo
    videoname_check = avifilename;

    matfilename = strcat(videoname(1:end-4),'_blinkframes.mat');
    save(matfilename,'videoname_check','blinkframes','framesafterblinks',...
        'blinkthreshold','framemeans','framestds','methodtouse');
end

if verbose
    figure;
    if (thresholdtoget < 3)
        if thresholdtoget == 1
            plot([1:numbervideoframes]',framemeans,'b')
            hold on;
            plot(blinkframes',framemeans(blinkframes),'r*');
            title('Frame Mean Pixel Values');
            hold off;
        else
            plot([1:numbervideoframes]',framestds,'b')
            hold on;
            plot(blinkframes',framestds(blinkframes),'r*');
            title('Std. Deviations of Pixel Values');
            hold off;
        end
    else
        subplot(2,1,1)
        plot([1:numbervideoframes]',framemeans,'b')
        hold on;
        plot(blinkframes',framemeans(blinkframes),'r*');
        title('Frame Mean Pixel Values');
        hold off;
        subplot(2,1,2)
        plot([1:numbervideoframes]',framestds,'b')
        hold on;
        plot(blinkframes',framestds(blinkframes),'r*');
        title('Std. Deviations of Pixel Values');
        hold off;
    end
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help getblinkframes'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------