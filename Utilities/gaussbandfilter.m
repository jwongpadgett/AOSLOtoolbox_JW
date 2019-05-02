function varargout = gaussbandfilter(videoname,lowfreq,smoothsd)
% gaussbandfilter.m. This is a utility program that is designed to band pass filter AOSLO videos/frames. The main requirement for filtering is
% too reduce the high spatial frequency noise in the video/frame (the amount of filtering on the high end controlled by the smoothsd) and any
% low spatial frequency luminance artifacts/retinal structures like the central fovea which is usually darker than the surrounding retina that
% messes up reference image creation.
%
% Usage: [filteredframes] = gaussbandfilter(videoname,lowfreq,smoothsd);
% videoname         - the name of the video or a collection of frames that needs to be filtered. If a 3D array of frames is
%                           provided then then output array is a 3D array of same size with the filtered frames.
% lowfreq             - the lowest frequency in the filtered image in cycles/image. Default is 3.
% smoothsd          - the SD (in pixels) of the guassian function that will be used to filter (smooth) the video/frame. Default
%                          is 2.
%
% filteredframes     - If a set of frames is given then the user should provide an output argument to hold the filtered frames.
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
    togetlowfreq = 1;
else
    togetlowfreq = 0;
end

if (nargin < 3) || isempty(smoothsd)
    togetsmoothsd = 1;
else
    togetsmoothsd = 0;
end

if togetlowfreq || togetsmoothsd
    name = 'Input for gaussbandfilter.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};

    if togetlowfreq
        prompt = {'Low Frequency Cut-off'};
        defaultanswer = {'3'};
    end

    if togetsmoothsd
        prompt{end + 1} = 'Smooth Function S.D.';
        defaultanswer{end + 1} = '2';
    end

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        if togetlowfreq
            warning('Using default value of 3 for low frequenct cutoff');
            lowfreq = 3;
        end

        if togetsmoothsd
            warning('Using default value of 2 for smoothing s.d.');
            smoothsd = 2;
        end
    else
        index = 1;

        if togetlowfreq
            if ~isempty(userresponse{index})
                lowfreq = str2double(userresponse{index});
            else
                disp('User has not entered low frequency cutoff');
                warning('Using default of 3');
                lowfreq = 3;
            end
            index = index + 1;
        end

        if togetsmoothsd
            if ~isempty(userresponse{index})
                smoothsd = str2double(userresponse{index});
            else
                disp('User has not entered smoothing s.d.');
                warning('Using default of 2');
                smoothsd = 2;
            end
        end
    end
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    numframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;
    videoframerate = videoinfo.FrameRate;

    if strcmp(videotype,'truecolor')
        disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end

    mymap = repmat([0:255]' / 255,1,3);
    moviestruct = repmat(struct('cdata',zeros(frameheight,framewidth),'colormap',mymap),numframes,1);
    newname = strcat(videoname(1:end - 4),'_bandfilt.avi');
    filteredvideoobject = VideoWriter(newname,'Grayscale AVI');
    filteredvideoobject.FrameRate = videoframerate;
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numframes = size(videoname,3);
    istruecolor = 0;

    filteredframes = zeros(frameheight,framewidth,numframes);
end

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

if smoothsd > 0
    smoothgauss_x = exp(-((xmatrix .^ 2) / (2 * (smoothsd .^ 2))));
    smoothgauss_y = exp(-((ymatrix .^ 2) / (2 * (smoothsd .^ 2))));

    smoothgauss = smoothgauss_y * smoothgauss_x;
    smoothgauss = smoothgauss / sum(smoothgauss(:));
end

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

if smoothsd > 0
    filter_fft = fftshift(fft2(smoothgauss)) .* lowfreqgauss;
    filter_fft = createsymmetry(filter_fft);
else
    filter_fft = createsymmetry(lowfreqgauss);
end

filter_fft = ifftshift(filter_fft);
filter_fft(1,1) = 1;

if numframes > 1
    filterprog = waitbar(0,'Filtering');
    oldposition = get(filterprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(filterprog,'Position',newposition);
end

for framecounter = 1:numframes
    if processfullvideo        
        vidObject = VideoReader(videoname);
        tempframe = double((readFrame(vidObject)));
        if istruecolor
            tempframe = tempframe(:,:,1);
        end
    else
        tempframe = videoname(:,:,framecounter);
    end

    fullframe = zeros(filterheight,filterwidth) + mean(tempframe(:));

    fullframe(indicesofinterest_y,leftpadindices) = repmat(tempframe(:,3),1,...
        numleftpadindices);
    fullframe(indicesofinterest_y,rightpadindices) = repmat(tempframe(:,end - 2),1,...
        numrightpadindices);
    fullframe(toppadindices,indicesofinterest_x) = repmat(tempframe(3,:),...
        numtoppadindices,1);
    fullframe(bottompadindices,indicesofinterest_x) = repmat(tempframe(end - 2,:),...
        numbottompadindices,1);

    fullframe(indicesofinterest_y,indicesofinterest_x) = tempframe;

    if smoothsd > 0
        newframe = real(ifftshift(ifft2(fft2(fullframe) .* filter_fft)));
    else
        newframe = real(ifft2(fft2(fullframe) .* filter_fft));
    end
    
    frametoadd = newframe(indicesofinterest_y,indicesofinterest_x);

    if processfullvideo
        
        open(filteredvideoobject);
        writeVideo(filteredvideoobject, mat2gray(max(min(frametoadd,256) ,1)));
        %filteredvideoobject = addframe(filteredvideoobject,max(min(frametoadd,256) ,1));
    else
        filteredframes(:,:,framecounter) = frametoadd;
    end

    if framecounter > 1
        prog = framecounter / numframes;
        waitbar(prog,filterprog);
    end
end

if numframes > 1
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
    error('Type ''help gaussbandfilter'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));
%--------------------------------------------------------------------------