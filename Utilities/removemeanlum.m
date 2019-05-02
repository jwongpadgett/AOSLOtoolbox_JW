function varargout = removemeanlum(videoname,smoothsd,numframestoaverage,verbose)

screensize = get(0,'Screensize');

if (nargin < 1) || isempty(videoname)
    [avifilename avipath] = uigetfile('*.avi','Please enter filename of video to analyse');
    if avifilename == 0
        disp('No video to analyse,stopping program');
        error('Type ''help removemeanlum'' for usage');
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
                error('Type ''help removemeanlum'' for usage');
            end
            videoname = strcat(avipathname,avifilename);
        end
    else
        if isnumeric(videoname)
            processfullvideo = 0;
            if nargout < 1
                disp('If you do not provide a video name, removemeanlum requires an output matrix');
                warning('Type ''help removemeanlum'' for usage');
            end
        else
            disp('You need to provide either the path of a video file or a numeric matrix of images');
            error('Exiting...');
        end
    end
end

if (nargin < 2) || isempty(smoothsd)
    togetsmoothsd = 1;
else
    togetsmoothsd = 0;

end

if (nargin < 3) || isempty(numframestoaverage)
    togetnumframestoaverage = 1;
else
    togetnumframestoaverage = 0;
end

if (nargin < 4) || isempty(verbose)
    verbose = 0;
end

if togetsmoothsd || togetnumframestoaverage
    name = 'Input for removemeanlum.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};

    if togetsmoothsd
        prompt = {'Smooth Function S.D.'};
        defaultanswer{end + 1} = '15';
    end

    if togetnumframestoaverage
        prompt{end + 1} = 'Number of Frames to Average [-1 for all frames]';
        defaultanswer{end + 1} = '-1';
    end
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        if togetsmoothsd
            warning('Using default value of 15 for Smoothing S.D.');
            smoothsd = 15;
        end

        if togetnumframestoaverage
            warning('Using default value of -1 for number of frames to average');
            numframestoaverage = -1;
        end
    else
        index = 1;

        if togetsmoothsd
            if ~isempty(userresponse{index})
                smoothsd = str2double(userresponse{index});
            else
                disp('User has not entered smoothing s.d.');
                warning('Using default of 15');
                smoothsd = 15;
            end
            index = index + 1;
        end

        if togetnumframestoaverage
            if ~isempty(userresponse{index})
                numframestoaverage = str2double(userresponse{index});
            else
                disp('User has not entered how many frames to average');
                warning('Using default of -1');
                numframestoaverage = -1;
            end
        end
    end
end

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    videoframerate = round(videoinfo.FrameRate);
    numbervideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
    videotype = videoinfo.VideoFormat;

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

    videoinfo.CurrentTime = 0;
    mymap = repmat([0:255]' / 255,1,3);
    newname = strcat(videoname(1:end - 4),'_meanrem.avi');
    nomeanvideooject = VideoWriter(newname, 'Indexed AVI');
    nomeanvideooject.Colormap = mymap;
    nomeanvideooject.FrameRate = videoframerate;
    open(nomeanvideooject);
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);

    nomeanframes = zeros(frameheight,framewidth,numbervideoframes);
end

if numframestoaverage <= 1
    disp('You have provided too low number for number of frames to average, Using all frames in video');
    numframestoaverage = -1;
end

if numframestoaverage == -1
    divisor = numbervideoframes;
    allframesflag = 1;
    sumframe = zeros(frameheight,framewidth);
    startindex = 1;
else
    if ~rem(numframestoaverage,2)
        disp('I was too lazy :D to code for even numbers, increasing number of frames to average by 1');
        numframestoaverage = numframestoaverage + 1;
    end
    
    midpointofframematrix = floor(numframestoaverage / 2) + 1;
    startindex = (1 - midpointofframematrix);
    framenumberaddition = midpointofframematrix;
    indextoputframe = midpointofframematrix;
    framematrix = zeros(frameheight,framewidth,numframestoaverage);
    titleaddition = [startindex,startindex + numframestoaverage];
    
    allframesflag = 0;
    
end

if allframesflag
    meanprog = waitbar(0,'Adding Frames');
else
    meanprog = waitbar(0,'Subtacting Mean Frame');
end
oldposition = get(meanprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex ((2 * oldposition(4)) + 50) ...
        oldposition(3) oldposition(4)];
set(meanprog,'Position',newposition);

for framecounter = startindex:numbervideoframes
    switch allframesflag
        case 1
            if processfullvideo
                videoinfo.CurrentTime = (framecounter-1)*(1/videoinfo.FrameRate);
                currentframe = double(readFrame(videoinfo));
                if istruecolor
                    currentframe = currentframe(:,:,1);
                end
            else
                currentframe = videoname(:,:,framecounter);
            end
            sumframe = sumframe + currentframe;
        case 0            
            framenumbertoput = framecounter + framenumberaddition;
            if framenumbertoput > numbervideoframes
                framedatatoaddtomatrix = zeros(frameheight,framewidth);
            else
                videoinfo.CurrentTime = (framenumbertoput-1)*(1/videoinfo.FrameRate);
                framedatatoaddtomatrix = double(readFrame(videoinfo));
            end
            
            if framecounter >= 1
                sumarray = sum(framematrix,3);
                divisorarray = sum(framematrix >= 1,3);
                aveframe_unsmoothed = sumarray ./ divisorarray;
                
                aveframe = smoothimage(aveframe_unsmoothed,smoothsd);
                aveframe = aveframe - min(aveframe(:));
                aveframe = aveframe - mean(aveframe(:));
                
                if verbose
                    figurewidth = round((screensize(3) - 50) / 3);
                    figureheight = round(screensize(4) / 3);
                    newposition_unsmoothed = [0,(screensize(4) - figureheight + 1),...
                        figurewidth, figureheight];
                    newposition_smoothed = [figurewidth + 20,(screensize(4) - figureheight + 1),...
                        figurewidth, figureheight];
                    
                    if framecounter == 1
                        unsmoothedfigure = figure; %#ok<*NASGU>
                        set(unsmoothedfigure,'Position',newposition_unsmoothed,'Toolbar','none','Name','Unsmoothed Average Frame');
                        
                        smoothedfigure = figure;
                        set(smoothedfigure,'Position',newposition_smoothed,'Toolbar','none','Name','Smoothed Average Frame');
                    end
                    
                    figure(unsmoothedfigure); %#ok<*NODEF>
                    image(floor(scale(aveframe_unsmoothed) * 255) + 1);
                    colormap(gray(256));
                    axis off;
                    truesize;
                    title(['Unsmoothed Average Frame Luminance for Frames ', num2str(max(titleaddition(1) + framecounter,1)),' to ',num2str(min(titleaddition(2) + framecounter,numbervideoframes))]);
                    
                    figure(smoothedfigure);
                    image(floor(scale(aveframe) * 255) + 1);
                    colormap(gray(256));
                    axis off;
                    truesize;
                    title(['Smoothed Average Frame Luminance for Frames ', num2str(max(titleaddition(1),1)),' to ',num2str(min(titleaddition(2),numbervideoframes))]);
                end
                
                if processfullvideo
                    videoinfo.CurrentTime = (framecounter-1)*(1/videoinfo.FrameRate);
                    currentframe = double(readFrame(videoinfo));
                    if istruecolor
                        currentframe = currentframe(:,:,1);
                    end
                else
                    currentframe = videoname(:,:,framecounter);
                end
                
                meanofframe = mean(currentframe(:));
                
                frametoadd = min(max(((currentframe - meanofframe) - aveframe) + meanofframe,1),255);
                
                if processfullvideo
                    writeVideo(nomeanvideooject, frametoadd);
                else
                    nomeanframes(:,:,framecounter) = frametoadd;
                end
                
                frame2add = max(min(((currentframe - aveframe) + meanofframe),256),1);
            end
            
            framematrix(:,:,indextoputframe) = framedatatoaddtomatrix;
            indextoputframe = indextoputframe + 1;
            if indextoputframe > numframestoaverage
                indextoputframe = 1;
            end
                        
            
    end

    prog = framecounter / numbervideoframes;
    waitbar(prog,meanprog);
end

if allframesflag
    aveframe_unsmoothed = sumframe / divisor;
    aveframe = smoothimage(aveframe_unsmoothed,smoothsd);
    aveframe = aveframe - min(aveframe(:));
    aveframe = aveframe - mean(aveframe(:));
    
    if verbose
        figure;
        image(floor(scale(aveframe_unsmoothed) * 255) + 1);
        colormap(gray(256));
        axis off;
        truesize;
        title('Unsmoothed Average Frame Luminance');

        figure;
        image(scale(aveframe) * 255);
        colormap(gray(256));
        axis off;
        truesize;
        title('Smoothed Average Frame Luminance');
    end
    
    waitbar(0,meanprog,'Subtracting Mean Frame');
    for framecounter = 1:numbervideoframes
        if processfullvideo
            videoinfo.CurrentTime = (framecounter-1)*(1/videoinfo.FrameRate);
            currentframe = double(readFrame(videoinfo));
            if istruecolor
                currentframe = currentframe(:,:,1);
            end
        else
            currentframe = videoname(:,:,framecounter);
        end

        meanofframe = mean(currentframe(:));

        frametoadd = ((currentframe - meanofframe) - aveframe) + meanofframe;
        frametoadd = min(max(frametoadd,1),255);

        if processfullvideo
            writeVideo(nomeanvideooject, uint8(frametoadd));
        else
            nomeanframes(:,:,framecounter) = frametoadd;
        end

        prog = framecounter / numbervideoframes;
        waitbar(prog,meanprog);
    end
end


close(meanprog);
if processfullvideo
    close(nomeanvideooject);
else
    varargout{1} = nomeanframes;
end


%--------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));
%--------------------------------------------------------------------------