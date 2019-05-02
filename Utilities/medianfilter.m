function varargout = medianfilter(videoname,windowsize)


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
            disp('If you do not provide a video name, gaussbandfilter requires an output matrix');
            error('Type ''help gaussbandfilter'' for usage');
        end
    end
end

if (nargin < 2) || isempty(windowsize)
    name = 'Input for medianfilter.m';
    numlines = 1;
    prompt = {'Window Size'};
    defaultanswer = {'15'};

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        warning('Using default window size of 15');
        windowsize = 15;
    else
        if ~isempty(userresponse{1})
            windowsize = str2double(userresponse{1});
        else
            warning('Using default window size of 15');
            windowsize = 15;
        end
    end
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    framerate = round(videoinfo.FrameRate);
    numframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;

    if strcmp(videotype,'truecolor')
        disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
    
    mymap = repmat([0:255]' / 255,1,3);
    moviestruct = repmat(struct('cdata',zeros(frameheight,framewidth),'colormap',mymap),numframes,1);
    newname = strcat(videoname(1:end - 4),'_medfilt.avi');
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numframes = size(videoname,3);
    istruecolor = 0;

    filteredframes = zeros(frameheight,framewidth,numframes);
end


subscriptaddition = round([0:(windowsize - 1)] - (windowsize / 2));

totalwindowpixels = windowsize .^ 2;
startindices_x = repmat([1 floor(framewidth / 3) floor(2 * framewidth / 3)],3,1);
endindices_x = [startindices_x(:,2:end) + 1,repmat(framewidth,3,1)];
startindices_x = startindices_x(:);
endindices_x = endindices_x(:);

startindices_y = [1 floor(frameheight / 3) floor(2 * frameheight / 3)]';
endindices_y = [startindices_y(2:end);frameheight];
startindices_y = repmat(startindices_y,3,1);
endindices_y = repmat(endindices_y,3,1);


totalsegments = 9 * numframes;
filterprog = waitbar(0,'Applying Median Filter');
oldposition = get(filterprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(filterprog,'Position',newposition);

for framecounter = 1:numframes
    if processfullvideo
        currentframe = double(readFrame(videoinfo));
    else
        currentframe = videoname(:,:,framecounter);
    end
    newframe = zeros(frameheight,framewidth);

    for rowcounter = 1:frameheight
        subscriptstofilter_row = max(min((subscriptaddition + rowcounter),frameheight),1);
        for colcounter = 1:framewidth
            subscriptstofilter_col = max(min((subscriptaddition + colcounter),framewidth),1);

            imagedata = currentframe(subscriptstofilter_row,subscriptstofilter_col);
            mediantoadd = median(imagedata(:));

            newframe(rowcounter,colcounter) = mediantoadd;
        end
    end

%     for segmentcounter = 1:9;
%         start_x = startindices_x(segmentcounter);
%         end_x = endindices_x(segmentcounter);
% 
%         start_y = startindices_y(segmentcounter);
%         end_y = endindices_y(segmentcounter);
% 
%         totalxs = end_x - start_x + 1;
%         totalys = end_y - start_y + 1;
%         totalpixels = totalxs * totalys;
% 
%         baseindices_x = repmat([start_x:end_x],totalys,1);
%         baseindices_x = repmat(baseindices_x(:),1,totalwindowpixels);
% 
%         addition_x = repmat([0:windowsize - 1] - floor(windowsize / 2),windowsize,1);
%         addition_x = repmat(addition_x(:)',totalpixels,1);
%         indices_x = min(max((baseindices_x + addition_x),1),framewidth);
% 
%         baseindices_y = repmat(repmat([start_y:end_y]',totalxs,1),1,totalwindowpixels);
%         addition_y = repmat(repmat([0:windowsize - 1]' - floor(windowsize / 2),windowsize,1)',...
%             totalpixels,1);
%         indices_y = min(max((baseindices_y + addition_y),1),frameheight);
% 
%         indices = sub2ind([frameheight framewidth],indices_y,indices_x);
%         medianvalues = median(currentframe(indices),2);
%         newframe(start_y:end_y,start_x:end_x) = reshape(medianvalues,totalys,totalxs);
%     end

    if processfullvideo
        moviestruct(framecounter).cdata = uint8(floor(scale(newframe) * 255) + 1);
    else
        filteredframes(:,:,framecounter) = newframe;
    end
    prog = framecounter / numframes;
    waitbar(prog,filterprog);
end
close(filterprog);

if processfullvideo
    newmovObj = VideoWriter(newname);
    newmovObj.FrameRate = framerate;
    writeVideo(newmovObj, moviestruct);
    close(newmovObj);
else
    varargout{1} = filteredframes;
end


%--------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to filter');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help gaussbandfilter'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------