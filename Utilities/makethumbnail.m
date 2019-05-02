function thumbnailvideoname = makethumbnail(videoname,thumbnailfactor_row,thumbnailfactor_col)
% makethumbnail.m. This a utility function that makes thumbnails of 2D
% image arrays.
%
% Usage: thumbnailvideoname = makethumbnail...
%                   ([videoname,thumbnailfactor_row,thumbnailfactor_col])
% videoname             - Either a string that contains the full path of a
%                         video or a 3D matrix that contains frame image
%                         data. If this argument is empty or is not
%                         provided the program queries the user to provide
%                         the path of a video.
% thumbnailfactor_row   - The factor by which the rows in the image/s are
%                         shrunk.
% thumbnailfactor_col   - The factor by which the columns in the image/s
%                         are shrunk.
%
% thumbnailvideoname    - Either the name of the video whose frames are
%                         shrunk or a 3D matrix of shrunk frame images.
%
%
% Program Creator: Girish Kumar. This program however is based on
% downsample.m which was written by Scott B. Stevenson. That file however
% has a name conflict with another MATLAB file.


if (nargin < 1) || isempty(videoname)
    [videoname,avifilename,avipath] = getvideoname;
    processfullvideo = 1;
else
    if ischar(videoname)
        processfullvideo = 1;
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [videoname,avifilename,avipath] = getvideoname;
        end
    else
        processfullvideo = 0;
        if nargout < 1
            disp('If you do not provide a video name, makethumbnail requires an output matrix');
            warning('Type ''help makethumbnail'' for usage');
        end
    end
end

if processfullvideo    
    videoinfo = VideoReader(videoname);
    videoframerate = round(videoinfo.FrameRate);
    numframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;

    if strcmp(videotype,'truecolor') || (length(size(double(readFrame(videoname)))) > 2)
        disp('Video being analysed is a truecolor video, this program can shrink only 8 bit videos!!');
        warning('Using only the first layer of the video during shrinking');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
    
    videoinfo.CurrentTime = 0;
    mymap = repmat([0:255]' / 255,1,3);
    moviestruct = repmat(struct('cdata',zeros(10),'colormap',mymap),numframes,1);
    thumbnailvideoname = strcat(videoname(1:end - 4),'_thumb.avi');
    thumbnailvideoobject = VideoWriter(thumbnailvideoname, 'Indexed AVI');
    thumbnailvideoobject.FrameRate = videoframerate;
    thumbnailvideoobject.Colormap = mymap;
    open(thumbnailvideoobject);
end

if (nargin < 2) || isempty(thumbnailfactor_row)
    togetrowfactor = 1;
else
    togetrowfactor = 0;
end

if (nargin < 3) || isempty(thumbnailfactor_col)
    togetcolfactor = 1;
else
    togetcolfactor = 0;
end

if togetrowfactor || togetcolfactor
    prompt = {};
    defaultanswer = {};
    name = 'Input for makethumbnail function';
    numlines = 1;

    if togetrowfactor
        prompt{end + 1} = 'Enter the row thumbnail factor';
        defaultanswer{end + 1} = '2';
    end

    if togetcolfactor
        prompt{end + 1} = 'Enter the column thumbnail factor';
        defaultanswer{end + 1} = '2';
    end

    answer = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(answer)
        disp('You need to enter a thumbnail factor/s');
        warning('Using default of 2');
        if togetrowfactor
            thumbnailfactor_row = 2;
        end
        if togetcolfactor
            thumbnailfactor_col = 2;
        end
    else
        fieldcounter = 1;

        if togetrowfactor
            if ~isempty(answer{fieldcounter})
                thumbnailfactor_row = str2double(answer{fieldcounter});
            else
                disp('User has not entered the row shrink factor');
                warning('Using default of 2')
                thumbnailfactor_row = 2;
            end
            fieldcounter = fieldcounter + 1;
        end

        if togetcolfactor
            if ~isempty(answer{fieldcounter})
                thumbnailfactor_col = str2double(answer{fieldcounter});
            else
                disp('User has not entered the column shrink factor');
                warning('Using default of 2')
                thumbnailfactor_col = 2;
            end
        end
    end
end

if processfullvideo
    shrinkprog = waitbar(0,'Shrinking');
    oldposition = get(shrinkprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(shrinkprog,'Position',newposition);
    for framecounter = 1:numframes
        tempframe = double(readFrame(videoinfo));
        if istruecolor
            tempframe = tempframe(:,:,1);
        end
        newframe = shrink(tempframe,thumbnailfactor_row,thumbnailfactor_col);
        frame2add = im2frame(uint8(floor(scale(newframe) * 255) + 1),mymap);
        writeVideo(thumbnailvideoobject,frame2add);
        
        moviestruct(framecounter).cdata = uint8(floor(newframe) + 1);

        prog = framecounter / numframes;
        waitbar(prog,shrinkprog);
    end

    close(shrinkprog);
    close(thumbnailvideoobject);
else
    thumbnailvideoname = shrink(videoname,thumbnailfactor_row,thumbnailfactor_col);
end


%--------------------------------------------------------------------------

function smallarray = shrink(largearray,rowfactor,colfactor)

[numrows numcols numlayers] = size(largearray);

largearray = largearray(1:(rowfactor * (floor(numrows / rowfactor))),...
    1:(colfactor * (floor(numcols / colfactor))),numlayers);

[numrows numcols numlayers] = size(largearray);
numsmallrows = numrows / rowfactor;
numsmallcols  = numcols / colfactor;

maxvalueinlargearray = max(largearray(:));
minvalueinlargearray = min(largearray(:));
valuerangeinlargearray = maxvalueinlargearray - minvalueinlargearray;

smallarray_rows = reshape(mean(reshape(largearray,[rowfactor,numrows / rowfactor * numcols,numlayers]),...
    1),[numsmallrows,numcols,numlayers]);

smallarray = permute(smallarray_rows,[2,1,3]);
smallarray = reshape(mean(reshape(smallarray,[colfactor,numcols / colfactor * numsmallrows,numlayers]),...
    1),[numsmallcols,numsmallrows,numlayers]);
smallarray = permute(smallarray,[2,1,3]);
smallarray = (scale(smallarray) * valuerangeinlargearray) + minvalueinlargearray;

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------

function scaledarray = scale(oldarray)

scaledarray = oldarray - min(oldarray(:));
scaledarray = scaledarray / max(scaledarray(:));

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help makethumbnail'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------