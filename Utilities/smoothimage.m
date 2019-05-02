function varargout = smoothimage(videoname,smoothsd)
% smoothimage.m. This is a utility program that is designed to band pass filter AOSLO videos/frames. The main requirement for filtering is
% too reduce the high spatial frequency noise in the video/frame (the amount of filtering on the high end controlled by the smoothsd) and any
% low spatial frequency luminance artifacts/retinal structures like the central fovea which is usually darker than the surrounded retina that
% messes up reference image creation.
%
% Usage: [smoothedframes] = smoothimage(videoname,lowfreq,smoothsd);
% videoname             - the name of the video or a collection of frames that needs to be filtered. If a 3D array of frames is
%                              provided then then output array is a 3D array of same size with the filtered frames.
% smoothsd              - the SD (in pixels) of the guassian function that will be used to filter (smooth) the video/frame. Default is 1.
%
% smoothedframes     - If a set of frames is given then the user should provide an output argument to hold the filtered frames.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War



if (nargin < 1) || isempty(videoname)
    [avifilename avipath] = uigetfile('*.avi','Please enter filename of video to analyse');
    if avifilename == 0
        disp('No video to analyse,stoping program');
        error('Type ''help smoothimage'' for usage');
    end
    videoname = strcat(avipath,avifilename);
    processfullvideo = 1;
else
    if ischar(videoname)
        processfullvideo = 1;
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [avifilename avipathname] = uigetfile('*.avi','Please enter filename of video to analyse');
            if avifilename == 0
                disp('No video to analyse,stoping program');
                error('Type ''help smoothimage'' for usage');
            end
            videoname = strcat(avipathname,avifilename);
        end
    else
        processfullvideo = 0;
        if nargout < 1
            disp('If you do not provide a video name, gaussbandfilter requires an output matrix');
            warning('Type ''help smoothimage'' for usage');
        end
    end
end

if (nargin < 2) || isempty(smoothsd)
    togetsmoothsd = 1;
else
    togetsmoothsd = 0;
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    numvideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;
    framerate = round(videoinfo.FrameRate);

    if strcmp(videotype,'truecolor') || (length(size(double(readFrame(videoinfo)))) > 2)
        disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end

    videoinfo.CurrentTime = 0;
    mymap = repmat([0:255]' / 255,1,3);
    smoothedvideoname = strcat(videoname(1:end - 4),'_smoothfilt.avi');
    smoothedvideoobject = VideoWriter(smoothedvideoname,'Indexed AVI');
    smoothedvideoobject.FrameRate = framerate;
    smoothedvideoobject.Colormap = mymap;
    open(smoothedvideoobject);
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numvideoframes = size(videoname,3);

    filteredframes = zeros(frameheight,framewidth,numvideoframes);
end

if togetsmoothsd
    prompt = {'Smooth Function S.D.'};
    name = 'Input for smoothimage.m';
    numlines = 1;
    defaultanswer = {'2'};

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        warning('Using default value of 2 for smoothing s.d.');
        smoothsd = 2;
    else
        smoothsd = str2double(userresponse{1});
    end
end

filterwidth = framewidth + 100;
filterheight = frameheight + 100;

smoothxmatrix = [0:filterwidth - 1] - floor(filterwidth / 2);
smoothymatrix = [0:filterheight - 1]' - floor(filterheight / 2);

indicesofinterest_x = [0:(framewidth - 1)] + ((filterwidth - framewidth) / 2);
indicesofinterest_y = [0:(frameheight - 1)] + ((filterheight - frameheight) / 2);

leftpadindices = [1:indicesofinterest_x(1) - 1];
rightpadindices = [indicesofinterest_x(end) + 1:filterwidth];

toppadindices = [1:indicesofinterest_y(1) - 1];
bottompadindices = [indicesofinterest_y(end) + 1:filterheight];

numleftpadindices = length(leftpadindices);
numrightpadindices = length(rightpadindices);
numtoppadindices = length(toppadindices);
numbottompadindices = length(bottompadindices);

if smoothsd > 0
    smoothgauss_x = exp(-((smoothxmatrix .^ 2) / (2 * (smoothsd .^ 2))));
    smoothgauss_y = exp(-((smoothymatrix .^ 2) / (2 * (smoothsd .^ 2))));

    smoothgauss = smoothgauss_y * smoothgauss_x;
else
    smoothgauss = ones(filtersize);
end

smoothgauss = smoothgauss / sum(smoothgauss(:));

filter_fft = fft2(smoothgauss);
filter_fft(1) = 1;

if numvideoframes > 1
    filterprog = waitbar(0,'Smoothing');
    oldposition = get(filterprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
    set(filterprog,'Position',newposition);
end

for framecounter = 1:numvideoframes
    if processfullvideo
        tempframe = double(readFrame(videoinfo));
        if istruecolor
            tempframe = tempframe(:,:,1);
        end
    else
        tempframe = videoname(:,:,framecounter);
    end

    bigframe = zeros(filterheight,filterwidth) + mean(tempframe(:));

    bigframe(indicesofinterest_y,leftpadindices) = repmat(tempframe(:,3),1,...
        numleftpadindices);
    bigframe(indicesofinterest_y,rightpadindices) = repmat(tempframe(:,end - 2),1,...
        numrightpadindices);
    bigframe(toppadindices,indicesofinterest_x) = repmat(tempframe(3,:),...
        numtoppadindices,1);
    bigframe(bottompadindices,indicesofinterest_x) = repmat(tempframe(end - 2,:),...
        numbottompadindices,1);

    bigframe(indicesofinterest_y,indicesofinterest_x) = tempframe;

    newframe = real(ifftshift(ifft2(fft2(bigframe) .* filter_fft)));
    frametoadd = newframe(indicesofinterest_y,indicesofinterest_x);

    if processfullvideo
        writeVideo(smoothedvideoobject,im2frame(uint8(floor(scale(frametoadd) * 255) + 1),mymap));
    else
        filteredframes(:,:,framecounter) = frametoadd;
    end
    
    if framecounter > 1
        prog = framecounter / numvideoframes;
        waitbar(prog,filterprog);
    end
end

if numvideoframes > 1
    close(filterprog);
end
%keyboard;
if processfullvideo
    close(smoothedvideoobject);
else
    varargout{1} = filteredframes;
end


%--------------------------------------------------------------------------

function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));

%--------------------------------------------------------------------------
