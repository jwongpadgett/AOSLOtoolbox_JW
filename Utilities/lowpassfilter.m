function varargout = lowpassfilter(videoname,lowfreq)
% removelowfreqs.m. This is a utility program that is designed to high pass filter AOSLO videos/frames. The main requirement for filtering is
% too reduce the low spatial frequency gradient  in the video/frame (like the central fovea) that can interfere with reference image creation.
%
% Usage: [filteredframes] = removelowfreqs(videoname,lowfreq)
%
% videoname         - the name of the video or a collection of frames that needs to be filtered. If a 3D array of frames is provided then then output
%                           array is a 3D array of same size with the filtered frames.
% lowfreq             - the lowest frequency in the filtered image in cycles/image. Default is 5
%
% filteredframes    - If a set of frames is given then the user should provide an output argument to hold the filtered frames.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love not War


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

if (nargin < 2) || isempty(lowfreq);
    prompt = {'Enter the low frequency cut-off'};
    name = 'Input for gaussbandfilter.m';
    numlines = 1;
    defaultanswer = {'3'};
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if ~isempty(userresponse)
        lowfreq = str2double(userresponse{1});
    else
        warning('You have not provided the low frequncy cut off, using default of 3 cycles/image');
        lowfreq = 3;
    end
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    videoframerate = round(videoinfo.FrameRate);
    numvideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.Type;

    firstframe = double(readFrame(videoinfo));
    if length(size(firstframe)) >= 3
        videotype = 'truecolor';
    end

    if strcmp(videotype,'truecolor')
        disp('Video being analysed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end

    mymap = repmat([0:255]' / 255,1,3);
    newname = strcat(videoname(1:end - 4),'_highpassfilt.avi');
    filteredvideoobject = VideoWriter(newname, 'Indexed AVI');
    filteredvideoobject.Colormap = mymap;
    filteredvideoobject.FrameRate = videoframerate;
    open(filteredvideoobject);
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numvideoframes = size(videoname,3);

    filteredframes = zeros(frameheight,framewidth,numvideoframes);
end

numpadpixels = 100;
numpadpixels = 100;

filterwidth = framewidth + numpadpixels;
filterheight = frameheight + numpadpixels;
imagesize = [filterheight filterwidth];
if rem(filterheight,2)
    vertpad = 1;
else
    vertpad = 0;
end

filtercenter_x = floor(filterwidth / 2) + 1;
filtercenter_y = floor(filterheight / 2) + 1;

xmatrix = [0:filterwidth - 1] - floor(filterwidth / 2);
ymatrix = flipud([0:filterheight - 1]') - floor(filterheight / 2) + vertpad;

indicesofinterest_x = [0:framewidth - 1] + floor((filterwidth - framewidth) / 2);
indicesofinterest_y = [0:frameheight - 1] + floor((filterheight - frameheight) / 2);

leftpadindices = [1:indicesofinterest_x(1) - 1];
rightpadindices = [indicesofinterest_x(end) + 1:filterwidth];

toppadindices = [1:indicesofinterest_y(1) - 1];
bottompadindices = [indicesofinterest_y(end) + 1:filterheight];

numleftpadindices = length(leftpadindices);
numrightpadindices = length(rightpadindices);
numtoppadindices = length(toppadindices);
numbottompadindices = length(bottompadindices);

lowfreqsd = 1.5;

lowfreqgauss_x = exp(-((xmatrix .^ 2) / (2 * (lowfreqsd .^ 2))));
lowfreqgauss_y = exp(-((ymatrix .^ 2) / (2 * (lowfreqsd .^ 2))));
lowfreqgauss = lowfreqgauss_y * lowfreqgauss_x;

indicesofzero_h = round([-1.0 * lowfreq:lowfreq] + filtercenter_x);
indicesofzero_v = round([-1.0 * lowfreq:lowfreq] + filtercenter_y);
indicesofzero = sub2ind(imagesize,repmat(indicesofzero_v(:),1,length(indicesofzero_h)),...
    repmat(indicesofzero_h,length(indicesofzero_v),1));
indicesofnonzero = setdiff([1:prod(imagesize)]',indicesofzero(:));
indicesofnonzero_max = max(lowfreqgauss(indicesofnonzero));
indicesofnonzero_min = min(lowfreqgauss(indicesofnonzero));

lowfreqgauss(indicesofzero) = 1;
lowfreqgauss(indicesofnonzero) = (lowfreqgauss(indicesofnonzero) - indicesofnonzero_min) ./...
    indicesofnonzero_max;
lowfreqgauss = scale(lowfreqgauss * -1.0);
lowfreqgauss(filtercenter_y,filtercenter_x) = 1;
lowfreqgauss = createsymmetry(lowfreqgauss);

filter_fft = ifftshift(lowfreqgauss);

if numvideoframes > 1
    waitbarpresent = 1;
    filterprog = waitbar(0,'Filtering');
    oldposition = get(filterprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(filterprog,'Position',newposition);
else
    waitbarpresent = 0;
end

if processfullvideo
    vidObj = VideoReader(videoname);
end
for framecounter = 1:numvideoframes
    if processfullvideo
        tempframe = double(readFrame(vidObj));
        if istruecolor
            tempframe = tempframe(:,:,1);
        end
    else
        tempframe = videoname(:,:,framecounter);
    end

    fullframe = zeros(frameheight,framewidth) + mean(tempframe(:));

    fullframe(indicesofinterest_y,leftpadindices) = repmat(tempframe(:,3),1,...
        numleftpadindices);
    fullframe(indicesofinterest_y,rightpadindices) = repmat(tempframe(:,end - 2),1,...
        numrightpadindices);
    fullframe(toppadindices,indicesofinterest_x) = repmat(tempframe(3,:),...
        numtoppadindices,1);
    fullframe(bottompadindices,indicesofinterest_x) = repmat(tempframe(end - 2,:),...
        numbottompadindices,1);

    fullframe(indicesofinterest_y,indicesofinterest_x) = tempframe;

    newframe = real(ifft2(fft2(fullframe) .* filter_fft));
    frametoadd = newframe(indicesofinterest_y,indicesofinterest_x);

    if processfullvideo
        writeVideo(filteredvideoobject, max(min(frametoadd,256),1));
    else
        filteredframes(:,:,framecounter) = frametoadd;
    end
    
    if waitbarpresent
        prog = framecounter / numvideoframes;
        waitbar(prog,filterprog);
    end
end

if waitbarpresent
    close(filterprog);
end

if processfullvideo
    close(filteredvideoobject);
else
    varargout{1} = filteredframes;
end


%--------------------------------------------------------------------------
function fouriersymmetricmatrix = createsymmetry(oldmatrix)

if rem(size(oldmatrix,2),2)
    startindex_x = 1;
else
    startindex_x = 2;
end

if rem(size(oldmatrix,1),2)
    startindex_y = 1;
else
    startindex_y = 2;
end

centreofmatrix_x = floor(size(oldmatrix,2) / 2) + 1;
centreofmatrix_y = floor(size(oldmatrix,1) / 2) + 1;

fouriersymmetricmatrix = oldmatrix;

fouriersymmetricmatrix(startindex_y:end,startindex_x:(centreofmatrix_x - 1)) =...
    flipud(fliplr(fouriersymmetricmatrix(startindex_y:end,(centreofmatrix_x + 1):end)));
fouriersymmetricmatrix(startindex_y:(centreofmatrix_y - 1),centreofmatrix_x) =...
    flipud(fouriersymmetricmatrix((centreofmatrix_y + 1):end,centreofmatrix_x));
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to filter');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help lowpassfilter'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------

function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));

%--------------------------------------------------------------------------