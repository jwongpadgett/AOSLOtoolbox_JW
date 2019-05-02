function [newvideoname varargout] = sectrimsqueeze(oldvideoname,trimborders,dewarpgrid_x,...
    dewarpgrid_y,verbosity)

currentdir = pwd;

if nargin < 5 || isempty(verbosity)
    verbosity = 0;
end

if nargin < 1 || isempty(oldvideoname)
    [fname pname] = uigetfile('*.avi','Please a choose video file to pre-process');
    if fname == 0
        disp('Need a video');
        return;
    else
        oldvideoname = strcat(pname,fname);
        cd(pname);
    end
end

if (nargin >= 1) && ~ischar(oldvideoname)
    processfullvideo = 0;
    makenewvideo = 0;
    if length(size(oldvideoname)) > 3
        disp('Provide a video name or a 3 dimensional array of frames');
        error('type ''help sectrimsqueeze'' for usage');
    end
    framewidth = size(oldvideoname,2);
    frameheight = size(oldvideoname,1);
    numbervideoframes = size(oldvideoname,3);
else
    processfullvideo = 1;
    makenewvideo = 1;
    fileinfo = VideoReader(oldvideoname); % Get important info of the avifile
    framerate = round(fileinfo.FrameRate); % The framerate of the video
    numbervideoframes = round(fileinfo.FrameRate*fileinfo.Duration);
    framewidth = fileinfo.Width;
    frameheight = fileinfo.Height;
    videotype = fileinfo.Type;
    newvideoname = strcat(oldvideoname(1:end - 4),'_dwt.avi');
end


if (nargin < 4) || isempty(dewarpgrid_y)
    [fname pname] = uigetfile('*.mat','Please choose the Y dewarp grid for the video');
    if fname == 0
        warning('No Scan Error Correction in the Vertical Direction');
        dewarpy = 0;
    else
        dewarpgrid_y = strcat(pname,fname);
        load(dewarpgrid_y);
        dewarpy = 1;
        cd(pname);
    end
else
    if ischar(dewarpgrid_y)
        load(dewarpgrid_y);
        dewarpy = 1;
    else
        dewarpy = 0;
    end
end


if nargin < 3 || isempty(dewarpgrid_x)
    [fname pname] = uigetfile('*.mat','Please choose the X dewarp grid for the videos');
    if fname == 0
        warning('No Scan Error Correction in the Horizontal Direction');
        dewarpx = 0;
    else
        dewarpgrid_x = strcat(pname,fname);
        load(dewarpgrid_x);
        dewarpx = 1;
        cd(pname);
    end
else
    if ischar(dewarpgrid_x)
        load(dewarpgrid_x);
        dewarpx = 1;
    else
        dewarpx = 0;
    end
end


if processfullvideo == 1
    firstframe = double(readFrame(fileinfo));
    if strcmp(videotype,'truecolor') || (length(size(firstframe)) >= 3)
        firstframe = firstframe(:,:,1);
    end
    fileinfo.CurrentTime = 0;
else
    firstframe = oldvideoname(:,:,1);
end
    
if nargin < 2 || isempty(trimborders)
    if dewarpx == 1
        firstframe = firstframe * sparse(fv_x);
    end
    if dewarpy == 1
        firstframe = rot90(firstframe' * sparse(fv_y));
    end
    [firstframe_cropped,trimborders] = cropimage(firstframe,1,0);
end


trimborders(1) = max(trimborders(1),1);
trimborders(2) = min(trimborders(2),framewidth);

trimborders(3) = max(trimborders(3),1);
trimborders(4) = min(trimborders(4),frameheight);

if rem((trimborders(4) - trimborders(3) + 1),2) == 0
    trimborders(4) = trimborders(4) - 1;
end
firstframe_cropped = firstframe(trimborders(3):trimborders(4),trimborders(1):trimborders(2));

if verbosity
    framefigure = figure;
    image(firstframe_cropped);
    colormap(gray(256));
    axis off;
end

mymap = repmat([0:255]' / 255,1,3);

if makenewvideo == 1
    newvideo = VideoWriter(newvideoname, 'Grayscale AVI');
    newvideo.FrameRate = framerate;
    open(newvideo);
else
    newheight = trimborders(4) - trimborders(3) + 1;
    newwidth = trimborders(2) - trimborders(1) + 1;
    newvideoname = zeros(newheight,newwidth,numbervideoframes);
end

movieprog = waitbar(0,'Pre-Processing Video');
oldwaitbarposition = get(movieprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,(oldwaitbarposition(4) + 20),...
    oldwaitbarposition(3),oldwaitbarposition(4)];
set(movieprog,'Position',newwaitbarposition);

for framecounter = 1:numbervideoframes
    if processfullvideo == 0
        frametoadd = oldvideoname(:,:,framecounter);
    else
        frametoadd = double(readFrame(fileinfo));
        if strcmp(videotype,'truecolor') || (length(size(frametoadd)) >= 3)
            frametoadd = frametoadd(:,:,1);
        end
    end
    
    if dewarpx == 1
        frametoadd = frametoadd * sparse(fv_x);
    end
    if dewarpy == 1
        frametoadd = rot90(frametoadd' * sparse(fv_y));
    end
    frametoadd = frametoadd(trimborders(3):trimborders(4),trimborders(1):trimborders(2));
    if verbosity
        figure(framefigure);
        image(frametoadd);
        colormap(gray(256));
        axis off;
    end

    if makenewvideo == 1
        writeVideo(newvideo,uint8(frametoadd));
    else
        newvideoname(:,:,framecounter) = frametoadd;
    end
    
    prog = framecounter / numbervideoframes;
    waitbar(prog, movieprog);
end

close(movieprog);

if makenewvideo == 1
    close(newvideo);
end

if verbosity
    close(framefigure);
end

if nargout >= 2
    varargout{1} = trimborders;
end
cd(currentdir);