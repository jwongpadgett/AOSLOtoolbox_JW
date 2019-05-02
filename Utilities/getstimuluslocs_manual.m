function [stimuluslocs varargout] = getstimuluslocs_manual(videoname,blinkfilename,numstimshifts,numlinesperfullframe)

currentdirectory = pwd;

if (nargin < 1) || isempty(videoname)
    [videoname,avifilename,avipathname] = getvideoname;
    cd(avipathname);
else
    if ischar(videoname)
        if ~exist(videoname,'file')
            warning('Video name does not point to a valid file');
            [fullvideoname,avifilename,avipathname] = getvideoname;
            cd(avipathname);
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
    end
    processfullvideo = 1;
end

if (nargin >= 1) && ~ischar(videoname)
    processfullvideo = 0;
    if length(size(videoname)) ~= 3
        disp('Provide a video name or a 3 dimensional array of frames');
        error('type ''help getstimuluslocs_manual'' for usage');
    end
else
    processfullvideo = 1;
end

if (nargin < 2) || isempty(blinkfilename)
    blinkfilename = getblinkfilename(currentdirectory);
    toloadblinkframedata = 1;
end

if (nargin >= 2)
    if ischar(blinkfilename)
        if ~exist(blinkfilename,'file')
            warning('Second input string does not point to a valid mat file');
            blinkfilename = getblinkfilename(currentdirectory);
        end
        toloadblinkframedata = 1;
    else
        if ~isnumeric(blinkfilename)
            disp('The second input variable is not of type double');
            error('Type ''help getstimuluslocs_manual'' for usage');
        end
        toloadblinkframedata = 0;
    end
end

if (nargin < 3) || isempty(numstimshifts)
    togetnumstimshifts = 1;
else
    togetnumstimshifts = 0;
end

if (nargin < 4) || isempty(numlinesperfullframe)
    togetnumlinesperfullframe = 1;
else
    togetnumlinesperfullframe = 0;
end

if togetnumstimshifts || togetnumlinesperfullframe
    name = 'Input for getstimuluslocs_manual.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};
    
    if togetnumstimshifts
        prompt = {'Number of Stimulus Jumps in Video'};
        defaultanswer = {'5'};
    end
    
    if togetnumlinesperfullframe
        prompt{end + 1} = 'Number of lines per full raw frame';
        defaultanswer{end + 1} = '525';
    end
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(userresponse)
        if togetnumstimshifts
            warning('You hav enot provided the number of stimulus jumps in the video, using default of 5');
            numstimshifts = 5;
        end
        
        if togetnumlinesperfullframe
            warning('You have not provided the number of lines per full raw frame of video, using default of 525');
            numlinesperfullframe = 525;
        end
    else
        index = 1;
        if togetnumstimshifts
            if ~isempty(userresponse{index})
                numstimshifts = str2double(userresponse{index});
            else
                warning('You have not provided the number of stimulus jumps in the video, using default of 5');
                numstimshifts = 5;
            end
            index = index + 1;
        end
        
        if togetnumlinesperfullframe
            if ~isempty(userresponse{index})
                numlinesperfullframe = str2double(userresponse{1});
            else
                warning('You have not provided the number of lines per full raw frame of video, using default of 525');
                numlinesperfullframe = 525;
            end
        end
    end
end

cd(currentdirectory);

if processfullvideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    numbervideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);
end

if toloadblinkframedata
    load(blinkfilename,'blinkframes');
else
    blinkframes = unique(sort(blinkfilename(:),'ascend'));
end

if numlinesperfullframe < frameheight
    numlinesperfullframe = frameheight + 1;
end

allframes = [1:numbervideoframes]';
nonframesblinkframes = setdiff(allframes,blinkframes(:));
numframestotest = numstimshifts * 2;
indexofframes = round(linspace(1,length(nonframesblinkframes),numframestotest));
intialtestframes = nonframesblinkframes(indexofframes);

initialstimcentres_x = [];
initialstimcentres_y = [];

framefighandle = figure;
vidObj = VideoReader(videoname);
for framecounter = 1:numframestotest
    currentframenumber = intialtestframes(framecounter);
    vidObj.CurrentTime = (currentframenumber-1)*(1/vidObj.FrameRate);
    currentframe = double(readFrame(vidObj));
    figure(framefighandle)
    imagesc(currentframe);
    colormap(gray(256));
    axis off;
    truesize;
    title('Click on the centre of stimulus, click outside the frame if location has already been selected');
    hold on;
    plot(initialstimcentres_x,initialstimcentres_y,'r*','MarkerSize',5);
    hold off;
    
    [loc_x loc_y] = ginput(1);
    
    if (loc_x > framewidth) || (loc_x < 1) || (loc_y > frameheight) || (loc_y < 1)
        continue;
    else
        xlim(loc_x + [-25,25]);
        ylim(loc_y + [-25,25]);
        
        [loc_x loc_y] = ginput(1);
        
        initialstimcentres_x = [initialstimcentres_x;round(loc_x)];
        initialstimcentres_y = [initialstimcentres_y;round(loc_y)];
        
        xlim([1 framewidth]);
        ylim([1 frameheight]);
    end
end

close(framefighandle);

firstframenumberwithstm = intialtestframes(1);

imagefigure = figure;
vidObj.CurrentTime = (firstframenumberwithstm-1)*(1/vidObj.FrameRate);
imagesc(double(readFrame(vidObj)));
colormap(gray(256));
axis off;
xlim(initialstimcentres_x(1) + [-35,35]);
ylim(initialstimcentres_y(1) + [-35,35]);
truesize;

stimborders = zeros(4,1);
for bordercounter = 1:4
    switch bordercounter
        case 1
            figure(imagefigure);
            set(imagefigure,'Name','Left Border');
            title('Left Border');
        case 2
            figure(imagefigure);
            set(imagefigure,'Name','Right Border');
            title('Right Border');
        case 3
            figure(imagefigure);
            set(imagefigure,'Name','Top Border');
            title('Top Border');
        case 4
            figure(imagefigure);
            set(imagefigure,'Name','Bottom Border');
            title('Bottom Border');
    end
    goodresponse = 0;
    while~goodresponse
        [x y] = ginput(1);
        if (x < 1) || (y < 1) || (x > framewidth) || (y > frameheight)
            goodresponse = 0;
        else
            goodresponse = 1;
        end
    end
    if bordercounter <= 2
        x = round(x);
        stimborders(bordercounter) = x;
    end
    
    if bordercounter > 2
        y = round(y);
        stimborders(bordercounter) = y;
    end
end

close(imagefigure);
stimsize_x = abs(stimborders(2) - stimborders(1));
stimsize_y = abs(stimborders(4) - stimborders(3));

maxindex = frameheight * framewidth;

possibleindicesofstim = zeros(stimsize_y,stimsize_x,length(initialstimcentres_x));
possibleindicesofnonstim = zeros(stimsize_y,stimsize_x,25);

for stimcounter = 1:length(initialstimcentres_x)
    subscripts_x = max(min(([0:(stimsize_x - 1)] - floor(stimsize_x / 2)) + initialstimcentres_x(stimcounter),framewidth),1);
    subscripts_y = max(min(([0:(stimsize_y - 1)] - floor(stimsize_y / 2)) + initialstimcentres_y(stimcounter),frameheight),1);
    
    subscripts_x = repmat(subscripts_x(:)',stimsize_y,1);
    subscripts_y = repmat(subscripts_y(:),1,stimsize_x);
    
    
    
    indicesofstim = sub2ind([frameheight framewidth],subscripts_y,subscripts_x);
    possibleindicesofstim(:,:,stimcounter) = max(min(indicesofstim,maxindex),1);
end

for stimcounter = 1:25
    subscripts_x = max(min(([0:(stimsize_x - 1)] - floor(stimsize_x / 2)) + floor(rand(1) * (framewidth - 1)) + 1,framewidth),1);
    subscripts_y = max(min(([0:(stimsize_y - 1)] - floor(stimsize_y / 2)) + floor(rand(1) * (frameheight - 1)) + 1,frameheight),1);
    
    subscripts_x = repmat(subscripts_x(:)',stimsize_y,1);
    subscripts_y = repmat(subscripts_y(:),1,stimsize_x);
    
    indicesofstim = sub2ind([frameheight framewidth],subscripts_y,subscripts_x);
    possibleindicesofnonstim(:,:,stimcounter) = max(min(indicesofstim,maxindex),1);
end

locstds = zeros(length(initialstimcentres_x),1);
locstds_nonstim = zeros(25,1);

stimlocs = zeros(numbervideoframes,1);
doesframehavestim = zeros(numbervideoframes,1);

stimprog = waitbar(0,'Finding the stimlus locations');
oldposition = get(stimprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(stimprog,'Position',newposition);
for framecounter = 1:length(nonframesblinkframes)
    currentframenumber = nonframesblinkframes(framecounter);    
    vidObj.CurrentTime = (currentframenumber-1)*(1/vidObj.FrameRate);
    currentframe = double(readFrame(vidObj));
    
    for loccounter = 1:length(initialstimcentres_x)
        tempstimpixels = currentframe(possibleindicesofstim(:,:,loccounter));
        locstds(loccounter) = std(tempstimpixels(:));
    end
    
    for loccounter = 1:25
        tempstimpixels = currentframe(possibleindicesofnonstim(:,:,loccounter));
        locstds_nonstim(loccounter) = std(tempstimpixels(:));
    end
    
    threshold = mean(locstds_nonstim(:)) + (2.5 * std(locstds_nonstim(:)));
    
    isstdgreaterthantreshold = sum(locstds > threshold);
    if isstdgreaterthantreshold <= 0
        doesframehavestim(currentframenumber) = 0;
    else
        currentstimloc = find(locstds == max(locstds(:)));
        if length(currentstimloc) > 1
            doesframehavestim(currentframenumber) = 0;
        else
            doesframehavestim(currentframenumber) = 1;
            stimlocs(currentframenumber) = find(locstds == max(locstds(:)));
        end
    end
    
    prog = currentframenumber / numbervideoframes;
    waitbar(prog,stimprog);
end

close (stimprog);

indicesofframeswithstim = find(doesframehavestim == 1);
frameswithstim = allframes(indicesofframeswithstim);

stimsizes = repmat([stimsize_x,stimsize_y],length(frameswithstim),1);

stimcentres_x = initialstimcentres_x(stimlocs(indicesofframeswithstim));
stimuluslocs_x = stimcentres_x - floor(framewidth / 2) + 1;

stimcentres_y = initialstimcentres_y(stimlocs(indicesofframeswithstim));
stimuluslocs_y = stimcentres_y -  floor(frameheight / 2) + 1;

stimtime = ((frameswithstim - 1) * numlinesperfullframe) + stimcentres_y;
stimuluslocs = [stimuluslocs_x,stimuluslocs_y,stimtime];

if processfullvideo
    save(blinkfilename,'stimuluslocs','stimsizes','frameswithstim','-append');
end

if nargout >= 2
    varargout{1} = stimsizes;
end

if nargout == 3
    varargout{2} = frameswithstim;
end

%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help getbadframes'' for usage');
end
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function filename = getblinkfilename(currentdir)
[fname pname] = uigetfile('*.mat','Please enter the matfile with the blink frame data');
if fname == 0
    cd(currentdir);
    disp('Need blink frame infomation,stopping program');
    error('Type ''help getbadframes'' for usage');
else
    filename = strcat(pname,fname);
end
%--------------------------------------------------------------------------