function selectedframes = frameselector(allframes)
% frameselector.m. This is an utilty program designed to allow the user to pick a subset of frames from a larger sets
% of frames. This program can be used to manually select the frames that are to be used to make a reference image.
%
% Usage: selectedframes = frameselector(allframes)
% allframes             - The larger set of frames. The data type can be a 3 dimesional numerical array, a cell array of
%                            frames or a string that contains the path that points to a video.
%
% selectedframes     - The frames that were selected by the user. The data type returned is the same the input array.
%                             If a string was supplied then a vector of frame numbers is returned.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

if (nargin < 1) || isempty(allframes)
    disp('Nothing to select from, frameselector requires atleast one input argument')
    error('Type ''help frameselector'' for help');
else
    frametype = [0 0 0];
    if ischar(allframes) && exist(allframes,'file')
        frametype(1) = 1;
    end

    if isnumeric(allframes)
        if length(size(allframes)) < 3
            disp('You have provided only a 2D numeric matrix')
            error('Type ''help frameselector'' for help');
        else
            frametype(2) = 1;
        end
    end

    if iscell(allframes)
        if length(allframes) < 2
            disp('The cell array provided is too small')
            error('Type ''help frameselector'' for help');
        else
            frametype(3) = 1;
        end
    end
end

if ~any(allframes)
    disp('Input argument does not correspond to any data type that the program can use')
    error('Type ''help frameselector'' for help');
end

frametypeindicator = find(frametype == 1);

switch frametypeindicator
    case 1
        videoinfo = VideoReader(allframes);
        numberofframes = round(videoinfo.FrameRate*videoinfo.Duration);
        framenumbers = [1:numberofframes]';
        firstframe = double(readFrame(videoinfo));
    case 2
        allframesize = size(allframes);
        numberofframes = allframesize(3);
        firstframe = allframes(:,:,1);
    case 3
        numberofframes = length(allframes);
        firstframe = allframes{1};
end

toexit = 0;
framecounter = 1;
datafromfig = cell(2,1);
indicestoselect = [];

mymap = repmat([0:255]' / 256,1,3);
framefig = figure;
set(framefig,'Name','Frame Selector','KeyPressFcn',@userresponse,...
    'UserData',datafromfig);
image(firstframe);
colormap(mymap);
axis off;
title('Press (A)ccept/(R)efect/(E)xit')
truesize;

while ~toexit
    switch frametypeindicator
        case 1            
            videoObj = VideoReader(allframes);
            videoObj.CurrentTime = (framecounter-1)*(1/videoObj.FrameRate);
            currentframe = double(readFrame(videoObj));
        case 2
            currentframe = firstframe(:,:,framecounter);
        case 3
            currentframe = firstframe{framecounter};
    end

    figure(framefig)
    image(currentframe);
    colormap(mymap);
    axis off;
    title('Press (A)ccept/(R)eject/(E)xit')
    truesize;
    figdata = get(framefig,'UserData');

    if figdata{1}
        keypressed = figdata{2};
        figdata = {[0],''};
        set(framefig,'UserData',figdata)
    else
        keypressed = 'g';
    end

    switch keypressed
        case 'a'
            indicestoselect = [indicestoselect;framecounter];
            framecounter = framecounter + 1;
        case 'r'
            framecounter = framecounter + 1;
        case 'e'
            toexit = 1;
        otherwise
            continue
    end

    if framecounter > numberofframes
        disp('You have reached the end!');
        toexit = 1;
    end
end

close(framefig);

switch frametypeindicator
    case 1
        selectedframes = framenumbers(indicestoselect);
    case 2
        selectedframes = allframes(:,:,indicestoselect);
    case 3
        selectedframes = allframes{indicestoselect};
end


%--------------------------------------------------------------------------
function userresponse(src,eventdata)
keypressed = lower(eventdata.Character);
outputdata = {[1];keypressed};
set(src,'UserData',outputdata);
%--------------------------------------------------------------------------