function [datafilename,referenceimage] = makereference_framerate(videoname,badframefilename,...
    frameincrement,badsamplethreshold,correlationflags,verbosityarray)
% makereference_framerate.m. This program is designed to create a reference image. The program does this by conducting a
% full frame cross-correlation. The program creates the reference image using a boot-strap method, initially the first frame is
% used as a temporary reference image and all frames are cross-correlated to this. Any frames that does not have suffcient
% correlation strength are then correlated to a "better" reference image created from all the frames that correlated with the first frame.
%
%Usage: [datafilename,referenceimage] = makereference_framerate(videoname,badframefilename,
%           frameincrement,badsamplethreshold,verbosityarray)
%
% videoname                 - A string that contains the full path to video/3D matrix consisting of multiple 2D images. The program
%                                  will query the user to provide a video path and name if this variable is not provided.
% badframefilename        - A string that contains the full path to a mat file that contains bad frame infomation in a format that
%                                  is the same as created by getbadframes.m/a one column array containing the "good" frames all of which
%                                  that can be used to create a referenceimage.
% frameincrement           - If a matfile is passed as the second input argument, then only a subset of "good" frames will be used to
%                                   create a reference image. If this is the case then the number of frames that are skipped needs to be
%                                   passed to the program. If a numeric array is passed then this argument is ignored.
% badsamplethreshold     - A metric is needed to determine if the automatic cross-correlation has returned a accurate result. The current
%                                  metric we use the ratio between the second and first peaks of the cross-correlation function. The smaller
%                                  this ratio, the more confident we can be on the accuracy of the returned values.
% correlationflags          - A 2 element array that controls the correlations conducted during this program. The first element can
%                                  be either a 1 (which forces the program to use sub-pixel resolution correlations) or 0. Similarly the second
%                                  element can be a 1 (which forces the program to use a raised cosine window during the correlations).
%                                  Default - [0 0].
% verbosityarray            - A 2 element array that determines the type of feedback that is given to the user. If the first element is set
%                                  to 1, then the program plots the cross-correlation function everytime the program conducts a cross-correlation.
%                                  If the second element isset to 1 then the program draws the image of the reference image once the prgram is done with its analyses.
%
% datafilename              - The name of the matfile into which the reference image and related data are written into.
% referenceimage           - The reference image created after the analyses. The reference image is a cropped image that has the maximum
%                                   image data. Pixels that have no image data is filled with random image data taken from image data.
%
%
% Note: This program resets the seed used by rand.
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

rand('state',sum(100 * clock));

currentdirectory = pwd;
screensize = get(0,'Screensize');
if ispc
    pathslash = '\';
else
    pathslash = '/';
end

toanalysevideo = 1;
toloadblinkframedata = 1;

if (nargin < 1) || isempty(videoname)
    [videoname,videofilename,videopath] = getvideoname;
    cd(videopath);
else
    if ischar(videoname)
        if exist(videoname,'file')
            maxslashindex = 0;
            for charcounter = 1:length(videoname)
                testvariable = strcmp(videoname(charcounter),pathslash);
                if testvariable
                    maxslashindex = charcounter;
                end
            end
            videofilename = videoname(maxslashindex + 1:end);
            videopath = videoname(1:maxslashindex);
            cd(videopath);
        else
            disp('Supplied video name does not point to a valid file');
            [videoname,videofilename,videopath] = getvideoname;
            cd(videopath);
        end
    else
        if ~isnumeric(videoname)
            disp('Supplied video name must be a string');
            [videoname,videofilename,videopath] = getvideoname;
            cd(videopath);
        else
            if length(size(videoname)) < 3
                disp('Frame data is not a 3D matrix');
                error('Type ''help makereference_framerate'' for usage');
            else
                toanalysevideo = 0;
            end
        end
    end
end

if (nargin < 2) || isempty(badframefilename)
    badframefilename = getbadframefilename(currentdirectory);
end

if (nargin >= 2)
    if ischar(badframefilename)
        if ~exist(badframefilename,'file')
            warning('Second input string does not point to a valid mat file');
            badframefilename = getbadframefilename(currentdirectory);
        end
    else
        if ~isnumeric(badframefilename)
            disp('The second input variable is not of type double');
            warning('Please choose a data file with bad frame data');
            badframefilename = getbadframefilename(currentdirectory);
        else
            toloadblinkframedata = 0;
        end
    end
end

if (nargin < 3) || isempty(frameincrement)
    togetframeincrement = 1;
else
    togetframeincrement = 0;
end

if (nargin < 4) || isempty(badsamplethreshold)
    togetbadsamplethreshold = 1;
else
    togetbadsamplethreshold = 0;
end

if (nargin < 5) || isempty(correlationflags)
    subpixelquery = questdlg('Do you want to calculate shifts with sub-pixel accuracy?','Sub-Pixel Question','Yes','No','No');
    if strcmpi(subpixelquery(1),'y')
        subpixelflag = 1;
    else
        subpixelflag = 0;
    end
    windowquery = questdlg('Do you want to window the test matrices during correlation?','Window Question','Yes','No','No');
    if strcmpi(windowquery(1),'y')
        windowflag = 1;
    else
        windowflag = 0;
    end
    
    correlationflags = [subpixelflag;windowflag];
end

if (nargin < 6) || isempty(verbosityarray)
    verbosityarray = [0;0];
    disp('No feedback will be provided!');
else
    if length(verbosityarray) < 2
        disp('Verbose array is too small')
        warning('Unassigned verbose flags set to zero');
    end
    verbosityarray = verbosityarray(:);
    verbosityarray = [verbosityarray;0];
end


if togetframeincrement || togetbadsamplethreshold
    name = 'Input for makereference_framerate.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};

    if togetframeincrement
        prompt = {'Frame Increment'};
        defaultanswer{end + 1} = num2str(12);
    end

    if togetbadsamplethreshold
        prompt{end + 1} = 'Bad Sample Threshold';
        defaultanswer{end + 1} = num2str(0.65);
    end

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        if togetframeincrement
            warning('Using default frame increment of 12');
            frameincrement = 12;
        end

        if togetbadsamplethreshold
            warning('Using default bad sample threshold of 0.65');
            badsamplethreshold = 0.65;
        end
    else
        index = 1;
        if togetframeincrement
            if ~isempty(userresponse{index})
                frameincrement = str2double(userresponse{index});
            else
                warning('You have not the frame increment,using default of 0.65');
                frameincrement = 12;
            end
            index = index + 1;
        end

        if togetbadsamplethreshold
            if ~isempty(userresponse{index})
                badsamplethreshold = str2double(userresponse{index});
            else
                warning('You have not entered bad sample threshold,using default of 0.65');
                badsamplethreshold = 0.65;
            end
        end
    end
end

if toanalysevideo
    fileinfo = VideoReader(videoname); % Get important info of the avifile
    framewidth = fileinfo.Width; % The width of the video (in pixels)
    frameheight = fileinfo.Height; % The height of the video (in pixels)
    numbervideoframes = round(fileinfo.FrameRate*fileinfo.Duration);% The number of frames in the video
    videotype = fileinfo.VideoFormat;

    if strcmp(videotype,'truecolor')
        disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
else
    framewidth = size(videoname,2);
    frameheight = size(videoname,1);
    numbervideoframes = size(videoname,3);
end

if (frameincrement < 3)
    warning('Frame increment is too low, increasing to 3');
    frameincrement = 3;
end
if (frameincrement > (numbervideoframes / 5))
    warning('Frame increment is too high, reducing to 1/5 the number of frames in video');
    frameincrement = round(numbervideoframes / 5);
end

if badsamplethreshold >= 1
    disp('Bad Strip Threshold is too high')
    warning('Reducing to 0.99')
    badsamplethreshold = 0.99;
end
if badsamplethreshold <= 0
    disp('Bad Strip Threshold is too low')
    warning('Increasing to 0.01')
    badsamplethreshold = 0.01;
end

if toloadblinkframedata
    variablesinfile = who('-file',badframefilename);
    doesfilehavegoodframeinfo = sum(strcmp(variablesinfile,'goodframesforrefanalysis'));
    doesfilehavevideocheckname = sum(strcmp(variablesinfile,'videoname_check'));
    if doesfilehavegoodframeinfo
        load(badframefilename,'goodframesforrefanalysis');
        if doesfilehavevideocheckname
            load(badframefilename,'videoname_check');
        else
            disp('Problem with bad frame file');
            warning('No video name was in bad frame datafile');
        end
    else
        disp('Problem with bad frame file');
        error('MATLAB data file does not have any good frame info');
    end

    if (exist('videoname_check','var')) && isempty(videoname_check) ||...
            (strcmp(videoname_check,videofilename) == 0) %#ok<NODEF>
        disp('Problem with video name in bad frame MAT file')
        warning('Bad frame info was obtained from different video / Video info was in matlab data file is empty');
    end
    if isempty(goodframesforrefanalysis)
        disp('Problem with good frame info');
        error('MATLAB data file does not have any good frame info');
    end

    framesforreference_indices = [1:frameincrement:length(goodframesforrefanalysis)];
    framesforreference = goodframesforrefanalysis(framesforreference_indices);
else
    framesforreference = badframefilename(:);
end

if length(correlationflags) < 2
    windowquery = questdlg('Do you want to window the test matrices during correlation?','Window Question','Yes','No','No');
    if strcmpi(windowquery(1),'y')
        windowflag = 1;
    else
        windowflag = 0;
    end

    correlationflags = [correlationflags;windowflag];
end

correlationflags = correlationflags(1:2);
correlverbose = verbosityarray(1);
referenceverbose = verbosityarray(2);


cd(currentdirectory);

stripidx = floor(frameheight / 2) + 1;
stabmaxsizeincrement = 3;
stabsplineflag = 1;
stabverbose = 0;

numframesforreference = length(framesforreference);
firstframereferencenumber = framesforreference(1);

if toanalysevideo
    vidObject3 = VideoReader(videoname);
    vidObject3.CurrentTime = (firstframereferencenumber-1)*(1/vidObject3.FrameRate);
    referenceimage = double(readFrame(vidObject3));
    
    if istruecolor
        referenceimage = referenceimage(:,:,1);
    end
else
    referenceimage = videoname(:,:,firstframereferencenumber);
end

matchesthataregood = zeros(numframesforreference,1);
numframesforcurrentlevel = numframesforreference;
badmatches = [1:numframesforreference]';
toexit = 0;

matchesthataregood(1) = 1;

frameshifts = zeros(numframesforreference,2);
peakratios = zeros(numframesforreference,1);
maxvals = zeros(numframesforreference,1);
secondpeaks = zeros(numframesforreference,1);
noises = zeros(numframesforreference,1);

if any(verbosityarray)
    figurewidth = round((screensize(3) - 50) / 3);
    figureheight = round(screensize(4) / 3);

    if correlverbose
        correlfig = figure;
        correlaxis = axes;
        newposition = [0,(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(correlfig,'Position',newposition,'Toolbar','none','Name','Cross-Correlation');
        set(correlaxis,'Zlim',[-1 1]');
        set(get(correlaxis,'XLabel'),'String','Horizontal Pixel Index')
        set(get(correlaxis,'YLabel'),'String','Vertical Pixel Index');
        set(get(correlaxis,'ZLabel'),'String','Correlation Strength');
        plottedcorrelmesh = 0;
    end
end

analysisprog = waitbar(0,'Setting Up');
oldwaitbarposition = get(analysisprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,(oldwaitbarposition(4) + 20),...
oldwaitbarposition(3),oldwaitbarposition(4)];
set(analysisprog,'Position',newwaitbarposition);

while ~toexit
    badmatchesthatcorrelated = [];
    waitbar(0,analysisprog,'Correlating Frames');
    vidObject4 = VideoReader(videoname);
    for framecounter = 1:numframesforcurrentlevel
        indexintomatrices = badmatches(framecounter);
        testframenumber = framesforreference(indexintomatrices);
        vidObject4.CurrentTime = (testframenumber-1)*(1/vidObject4.FrameRate);
        if toanalysevideo
            testframe = double(readFrame(vidObject4));
            
            if istruecolor
                testframe = testframe(:,:,1);
            end
        else
            testframe = videoname(:,:,testframenumber);
        end

        [correlation shifts peaks_noise] = corr2d(referenceimage,testframe,correlationflags(1),correlationflags(2));

        peakratio = peaks_noise(2) / peaks_noise(1);

        if peakratio < badsamplethreshold
            badmatchesthatcorrelated = [badmatchesthatcorrelated;indexintomatrices];
            matchesthataregood(indexintomatrices) = 1;
            frameshifts(indexintomatrices,:) = shifts;
            peakratios(indexintomatrices) = peakratio;
            maxvals(indexintomatrices) = peaks_noise(1);
            noises(indexintomatrices) = peaks_noise(3);
            secondpeaks(indexintomatrices) = peaks_noise(2);
        end

        if correlverbose
            if ~plottedcorrelmesh
                figure(correlfig);
                correlmeshhandle = mesh(correlaxis,correlation);
                set(correlaxis,'Zlim',[-0.2 1]');
                plottedcorrelmesh = 1;
            else
                figure(correlfig);
                set(correlmeshhandle,'Zdata',correlation);
                set(correlaxis,'Zlim',[-0.2 1]');
            end
        end
        
        prog = (framecounter - 1) / (numframesforcurrentlevel - 1);
        waitbar(prog,analysisprog);
    end

    if isempty(badmatchesthatcorrelated) || (sum(matchesthataregood) == numframesforreference)
        toexit = 1;
        break
    end

    badmatchindices = find(matchesthataregood == 0);
    numframesforcurrentlevel = length(badmatchindices);
    badmatches = badmatchindices;

    goodmatchindices = find(matchesthataregood == 1);
    numgoodmatches = length(goodmatchindices);

    goodframeshifts = frameshifts(goodmatchindices,:);
    goodpeakratios = peakratios(goodmatchindices);
    
    [referencematrix,referencematrix_full] = ...
        makestabilizedframe(videoname,framesforreference(goodmatchindices),...
        goodframeshifts,goodpeakratios,stripidx,badsamplethreshold,frameheight + 1,...
        stabmaxsizeincrement,stabsplineflag,stabverbose);
    
    referenceimage = referencematrix_full(:,:,2);
    
    waitbar(0,analysisprog,'Temp');
end

close(analysisprog);

if correlverbose
    close(correlfig);
end

goodmatchindices = find(matchesthataregood == 1);
framesforreference = framesforreference(goodmatchindices);
frameshifts = frameshifts(goodmatchindices,:);
peakratios = peakratios(goodmatchindices);
maxvals = maxvals(goodmatchindices);
noises = noises(goodmatchindices);
secondpeaks = secondpeaks(goodmatchindices);
numframesforreference = length(framesforreference);

if numframesforreference >= 2
    [referencematrix,referencematrix_full] = ...
        makestabilizedframe(videoname,framesforreference,frameshifts,peakratios,...
        stripidx,badsamplethreshold,frameheight + 1,stabmaxsizeincrement,stabsplineflag,stabverbose);
else
    vidObj = VideoReader(videoname);    
    vidObj.CurrentTime = (framesforreference(1)-1)*(1/vidObj.FrameRate);
    frametoadd = double(readFrame(vidObj));
    referencematrix = repmat(frametoadd,[1 1 3]);
    referencematrix_full = referencematrix;
end
    

referenceimage = referencematrix(:,:,2);
analysedframes = framesforreference;
videoname_check = videofilename;

randstring = num2str(min(ceil(rand(1) * 10000),9999));
fullstring = strcat('_coarserefdata_',num2str(frameincrement),'_',randstring,'.mat');
if toanalysevideo
    datafilename = strcat(videoname(1:end - 4),fullstring);
else
    datafilename = fullstring(2:end);
end


save(datafilename,'referenceimage','referencematrix','referencematrix_full',...
    'analysedframes','frameshifts','maxvals','secondpeaks','noises','peakratios',...
    'stripidx','videoname_check','badsamplethreshold','frameincrement','framewidth',...
    'frameheight');

if referenceverbose
    mymap = repmat([0:255]' / 256,1,3);
    if toanalysevideo
        titlestring = ['Reference Frame from video ',videofilename];
    else
        titlestring = ['Reference Frame'];
    end
    figure;
    set(gcf,'Name','Reference Frame');
    image(referenceimage);
    colormap(mymap);
    axis off;
    title(titlestring,'Interpreter','none');
    truesize
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help makereference_framerate'' for usage');
end
cd(videopath);
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function filename = getbadframefilename(currentdir)
[fname pname] = uigetfile('*.mat','Please enter the matfile with the blink frame data');
if fname == 0
    cd(currentdir);
    disp('Need blink frame infomation,stopping program');
    error('Type ''help makereference_framerate'' for usage');
else
    filename = strcat(pname,fname);
end
%--------------------------------------------------------------------------