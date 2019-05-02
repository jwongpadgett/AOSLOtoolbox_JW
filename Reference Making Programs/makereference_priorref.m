function [datafilename,referenceimage] = makereference_priorref(videoname,refframefilename,badframefilename,...
    referencevarname,searchparamstruct,correlationflags,verbosityarray)
% makereference_priorref.m. This program is designed to create a reference image. The program does this by conducting a "strip"
% cross-correlation using a image that has already been constructed as a reference image.
%
%Usage: [datafilename,referenceimage] = makereference_priorref(videoname,refframefilename,...
%            badframefilename,referencevarname,searchparamstruct,verbosityarray)
%
% videoname               - A string that contains the full path to video/3D matrix consisting of multiple 2D images. The program will
%                           query the user to provide a video path and name if this variable is not provided.
% refframefilename        - The string that points to matfile name that contains the reference image.
% badframefilename        - A string that contains the full path to a  mat file that contains bad frame infomation in a format that is the
%                           same as created by getbadframes.m/a one column array containing the "good" frames all of which that can
%                           be used to create a referenceimage.
% referencevarname        - The name of the variable within the reference matfile that is the reference image.
% searchparamstruct       - A structure data type that has the following fields:
%                                   samplerate                          : The samplerate of the extracted eye motion trace in hertz
%                                   vertsearchzone                      : The number of pixel lines that are searched for a match for individual
%                                                                         strips.
%                                   stripheight                         : The number of pixel lines that constitute a single strip.
%                                   badstripthreshold
%                                   frameincrement                      : The number of frames within the "good" frames that are skipped over
%                                                                         while choosing the frames will be used to make the reference
%                                   minpercentofgoodstripsperframe      : The decimal percentage that denotes the minimum percent of good
%                                                                         strips/samples matches within a frame for the frame to be used in the
%                                                                         reference frame
%                                   numlinesperfullframe                : The number of pixel lines that constitute a full frame including the scan
%                                                                         mirror flyback.
% correlationflags        -  A 2 element array that controls the correlations conducted during this program. The first element can
%                            be either a 1 (which forces the program to use sub-pixel resolution correlations) or 0. Similarly the second
%                            element can be a 1 (which forces the program to use a raised cosine window during the correlations).
%                            Default - [0 0].
% verbosityarray          - A 4 element array that determines the type of feedback that is given to the user. If the first element is set to
%                           1, then the program plots the cross-correlation function everytime the program conducts a cross-correlation.
%                           If the second and third element are set to 1 then then program plots the extracted eye motion trace and the peak
%                           ratios respectively. if the fourth element is set to 1 then the program draws the image of the reference image once
%                           the program is done with its analyses.
%
% datafilename            - The name of the matfile into which the reference image and related data are written into.
% referenceimage          - The reference image created after the analyses. The reference image is a cropped image that has the maximum
%                           image data. Pixels that have no image data is filled with random image data taken from image data.
%
%
% Program Creator: Girish Kumar

rand('state',sum(100 * clock));

currentdirectory = pwd;
screensize = get(0,'Screensize');
if ispc
    pathslash = '\';
else
    pathslash = '/';
end

toanalysevideo = 1;
togetreferencevarname = 1;
toloadreference = 1;
toloadbadframenumbers = 1;


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

if (nargin < 2) || isempty(refframefilename)
    refframefilename = getreffilename(currentdirectory);
else
    if ischar(refframefilename)
        if ~exist(refframefilename,'file')
            disp('Second input string does not point to a valid mat file');
            refframefilename = getreffilename(currentdirectory);
        end
    else
        if isnumeric(refframefilename)
            togetreferencevarname = 0;
            toloadreference = 0;
            referenceimage_prior = refframefilename;
        else
            disp('Second input argument must be a string or 2D double matrix');
            refframefilename = getreffilename(currentdirectory);
        end
    end
end

if (nargin < 3) || isempty(badframefilename)
    badframefilename = getbadframefilename(currentdirectory);
end

if (nargin >= 3)
    if ischar(badframefilename)
        if ~exist(badframefilename,'file')
            warning('Third input string does not point to a valid mat file');
            badframefilename = getbadframefilename(currentdirectory);
        end
    else
        if ~isnumeric(badframefilename)
            disp('The third input variable is not a numeric datatype');
            warning('Please choose a data file with bad frame data');
            badframefilename = getbadframefilename(currentdirectory);
        else
            toloadbadframenumbers = 0;
        end
    end
end

if (nargin < 4 || isempty(referencevarname) || ~ischar(referencevarname)) && togetreferencevarname
    variablesinfile = who('-file',refframefilename);
    [selection,ok] = listdlg('PromptString','Which variable is the reference',...
        'SelectionMode','single','ListString',variablesinfile);
    if ok == 0
        warning('You have not made a valid selection, exiting...');
        return;
    end
    referencevarname = variablesinfile{selection};
end

if nargin < 5 || isempty(searchparamstruct) || ~isstruct(searchparamstruct)
    prompt = {'Sample Rate (Hz)','Vertical Search Zone (Pixels)',...
        'Strip Height (Pixels)','Bad Strip Correlation Threshold',...
        'Frame Number Increment','Minimum %. of Good Strips Reqd Per Frame',...
        'Number of Lines per Full Frame'};
    
    name = 'Search Parameters Input for Reference Program';
    numlines = 1;
    defaultanswer = {'720','75','11','0.6','12','0.4','525'};
    
    inputanswer = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(inputanswer)
        disp('You have pressed cancel rather than input any values');
        warning('Using default values in fields in the searchparamstruct structure');
        inputanswer = {'720','75','11','0.6','12','0.4','525'};
    end
    
    if isempty(inputanswer{1})
        togetsamplerate = 1;
    else
        togetsamplerate = 0;
        searchparamstruct = struct('samplerate',str2double(inputanswer{1}));
    end
    
    if isempty(inputanswer{2})
        togetvertsearchzone = 1;
    else
        togetvertsearchzone = 0;
        searchparamstruct.vertsearchzone = str2double(inputanswer{2});
    end
    
    if isempty(inputanswer{3})
        togetstripheight = 1;
    else
        togetstripheight = 0;
        searchparamstruct.stripheight = str2double(inputanswer{3});
    end
    
    if isempty(inputanswer{4})
        togetbadstripthreshold = 1;
    else
        togetbadstripthreshold = 0;
        searchparamstruct.badstripthreshold = str2double(inputanswer{4});
    end
    
    if isempty(inputanswer{5})
        togetframeincrement = 1;
    else
        togetframeincrement = 0;
        searchparamstruct.frameincrement = str2double(inputanswer{5});
    end
    
    if isempty(inputanswer{6})
        togetminpercentofgoodstripsperframe = 1;
    else
        togetminpercentofgoodstripsperframe = 0;
        searchparamstruct.minpercentofgoodstripsperframe = str2double(inputanswer{6});
    end
    
    if isempty(inputanswer{7})
        togetnumlinesperfullframe = 1;
    else
        togetnumlinesperfullframe = 0;
        searchparamstruct.numlinesperfullframe = str2double(inputanswer{7});
    end
else
    namesofinputfields = fieldnames(searchparamstruct);
    if sum(strcmp(namesofinputfields,'samplerate'))
        togetsamplerate = 0;
    else
        togetsamplerate = 1;
    end
    if sum(strcmp(namesofinputfields,'vertsearchzone'))
        togetvertsearchzone = 0;
    else
        togetvertsearchzone = 1;
    end
    if sum(strcmp(namesofinputfields,'stripheight'))
        togetstripheight = 0;
    else
        togetstripheight = 1;
    end
    if sum(strcmp(namesofinputfields,'badstripthreshold'))
        togetbadstripthreshold = 0;
    else
        togetbadstripthreshold = 1;
    end
    if sum(strcmp(namesofinputfields,'frameincrement'))
        togetframeincrement = 0;
    else
        togetframeincrement = 1;
    end
    if sum(strcmp(namesofinputfields,'minpercentofgoodstripsperframe'))
        togetminpercentofgoodstripsperframe = 0;
    else
        togetminpercentofgoodstripsperframe = 1;
    end
    if sum(strcmp(namesofinputfields,'numlinesperfullframe'))
        togetnumlinesperfullframe = 0;
    else
        togetnumlinesperfullframe = 1;
    end
end

if ~exist('searchparamstruct','var')
    searchparamstruct = [];
end

if any([togetsamplerate;togetvertsearchzone;togetstripheight;togetbadstripthreshold;
        togetminpercentofgoodstripsperframe;togetnumlinesperfullframe])
    prompt = {};
    defaultanswer = {};
    name = 'Search Parameter Input for Reference Program';
    numlines = 1;
    
    if togetsamplerate
        prompt{end + 1} = 'Sample Rate (Hz)';
        defaultanswer{end + 1} = '720';
    end
    if togetvertsearchzone
        prompt{end + 1} = 'Vertical Search Zone (Pixels)';
        defaultanswer{end + 1} = '75';
    end
    if togetstripheight
        prompt{end + 1} = 'Strip Height (Pixels)';
        defaultanswer{end + 1} = '11';
    end
    if togetbadstripthreshold
        prompt{end + 1} = 'Bad Strip Correlation Threshold';
        defaultanswer{end + 1} = '0.6';
    end
    if togetframeincrement
        prompt{end + 1} = 'Frame Number Increment';
        defaultanswer{end + 1} = '12';
    end
    if togetminpercentofgoodstripsperframe
        prompt{end + 1} = 'Minimum %. of Good Strips Reqd Per Frame';
        defaultanswer{end + 1} = '0.4';
    end
    if togetnumlinesperfullframe
        prompt{end + 1} = 'Number of Lines per Full Frame';
        defaultanswer{end + 1} = '525';
    end
    
    inputanswer = inputdlg(prompt,name,numlines,defaultanswer);
    fieldcounter = 1;
    if togetsamplerate
        searchparamstruct.samplerate = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetvertsearchzone
        searchparamstruct.vertsearchzone = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetstripheight
        searchparamstruct.stripheight = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetbadstripthreshold
        searchparamstruct.badstripthreshold = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetframeincrement
        searchparamstruct.frameincrement = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetminpercentofgoodstripsperframe
        searchparamstruct.minpercentofgoodstripsperframe = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetnumlinesperfullframe
        searchparamstruct.numlinesperfullframe = str2double(inputanswer{fieldcounter});
    end
end


if (nargin < 6) || isempty(correlationflags)
    subpixelquery = questdlg('Do you want to calculate shifts with sub-pixel accuracy?','Sub-Pixel Question','Yes','No','Yes');
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
elseif length(correlationflags) < 2
    windowquery = questdlg('Do you want to window the test matrices during correlation?','Window Question','Yes','No','No');
    if strcmpi(windowquery(1),'y')
        windowflag = 1;
    else
        windowflag = 0;
    end
    
    correlationflags = [correlationflags;windowflag];
end

if (nargin < 7) || isempty(verbosityarray)
    verbosityarray = [0;0;0;0];
    warning('No feedback will be provided!');
else
    if length(verbosityarray) < 4
        warning('Verbose array is too small, unassigned verbose flags set to zero');
    end
    
    verbosityarray = [verbosityarray(:);zeros(4 - length(verbosityarray),1)];
end

if toanalysevideo
    %keyboard;
    videoinfo = VideoReader(videoname); % Get important info of the avifile
    numbervideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
    framewidth = videoinfo.Width; % The width of the video (in pixels)
    frameheight = videoinfo.Height; % The height of the video (in pixels)
    videotype = videoinfo.VideoFormat;
    videoframerate = videoinfo.FrameRate;
    if strcmp(videotype,'truecolor') || (length(size(double(readFrame(videoinfo)))) >= 3)
        warning('Video being analysed is a truecolor video, this program can analyse only 8 bit videos!!');
        warning('Using only the first layer of the video during analyses');
        istruecolor = 1;
    else
        istruecolor = 0;
    end
    videoinfo.CurrentTime = 0;
else
    framewidth = size(videoname,2); % The width of the video (in pixels)
    frameheight = size(videoname,1); % The height of the video (in pixels)
    numbervideoframes = size(videoname,3);
    videoframerate = 30; % The videoframerate of the video
end

if toloadreference
    variablesinfile = who('-file',refframefilename);
    doesfilehavereference = sum(strcmp(variablesinfile,referencevarname));
    if doesfilehavereference
        load(refframefilename,referencevarname);
        renamestring = strcat('referenceimage_prior =',referencevarname,';');
        eval(renamestring);
    else
        disp('Problem with file supplied, variable does not exist within the file');
        error('Unable to load reference image, exiting...');
    end
end

if ~isnumeric(referenceimage_prior)
    disp('Reference image has to be a 2D double matrix');
    error('Please supply an appropriate reference image, exiting...');
end
if length(size(referenceimage_prior)) > 2
    disp('Reference image cannot have more than one image layer');
    warning('Using only first layer of the reference image');
    referenceimage_prior = referenceimage_prior(:,:,1);
end

samplerate = searchparamstruct.samplerate;
defaultsearchzone_vert_strips = searchparamstruct.vertsearchzone;
stripheight = searchparamstruct.stripheight;
badstripthreshold = searchparamstruct.badstripthreshold;
frameincrement = searchparamstruct.frameincrement;
minpercentofgoodstripsperframe = searchparamstruct.minpercentofgoodstripsperframe;
numlinesperfullframe = searchparamstruct.numlinesperfullframe;

if rem(samplerate,1)
    warning('Sample rate should be an whole number, rounding off the sample rate');
    samplerate = round(samplerate);
end
if samplerate > (videoframerate * numlinesperfullframe)
    newsampleratestring = [num2str(videoframerate * numlinesperfullframe),' Hz'];
    dispstring = ['Too High a sample rate, decreasing to ',newsampleratestring];
    warning(dispstring);
    samplerate = round((videoframerate * numlinesperfullframe));
end
if rem(samplerate,videoframerate) ~= 0
    warning('Sample rate should be multiple of the video frame rate, reducing sample rate to previous multiple of frame rate');
    samplerate = round(floor(samplerate / videoframerate) * videoframerate);
end
if samplerate < (2 * videoframerate)
    warning('Too Low a sample sample, increasing to twice the frame rate of video');
    samplerate = round((2 * videoframerate));
end

if defaultsearchzone_vert_strips > frameheight
    warning('Default Vertical Search Zone is too high, reducing to 10 pixels less than frame height');
    defaultsearchzone_vert_strips = frameheight - 10;
end
if defaultsearchzone_vert_strips < 10
    warning('Default Vertical Search Zone is too low, increasing to 10 pixels');
    defaultsearchzone_vert_strips = 10;
end

if rem(stripheight,1) ~= 0
    warning('Strip height cannot be a decimal, rounding down...');
    stripheight = floor(stripheight);
end
if stripheight >= defaultsearchzone_vert_strips
    warning('Strip Height cannot be larger than vertical search zone, reducing strip height to one less than vertical search zone');
    stripheight = max(defaultsearchzone_vert_strips - 1,1);
end
if stripheight <= 0
    warning('Strip should have atleast one line, increasing strip height to 1');
    stripheight = 1;
end

if badstripthreshold > 0.99
    warning('Bad Strip Threshold is too high, reducing to 0.99');
    badstripthreshold = 0.99;
end
if badstripthreshold <= 0.01
    warning('Bad Strip Threshold is too low, increasing to 0.01')
    badstripthreshold = 0.01;
end

if (frameincrement < 3)
    warning('Frame increment is too low, increasing to 3');
    frameincrement = 3;
end
if (frameincrement > (numbervideoframes / 5))
    warning('Frame increment is too high, reducing to 1/5 the number of frames to use for reference');
    frameincrement = round(numbervideoframes / 5);
end

if minpercentofgoodstripsperframe > 1
    warning('It is a little (just a little!!) difficult to get more than 100% good strips in a frame, reducing minimum percentage of good strips per frame to 100%');
    minpercentofgoodstripsperframe = 1;
end
if minpercentofgoodstripsperframe < 0.2
    warning('To few strips per frame, increasing minimum percentage of good strips per frame to 20%');
    minpercentofgoodstripsperframe = 0.2;
end

if numlinesperfullframe < frameheight
    warning('Number of lines in full frame cannot be smaller than the number of lines in video frame, increasing to 1 greater than frame height');
    numlinesperfullframe = frameheight + 1;
end

if toloadbadframenumbers
    variablesinfile = who('-file',badframefilename);
    doesfilehavegoodframeinfo = sum(strcmp(variablesinfile,'goodframesforrefanalysis'));
    doesfilehavevideocheckname = sum(strcmp(variablesinfile,'videoname_check'));
    if doesfilehavegoodframeinfo
        load(badframefilename,'goodframesforrefanalysis');
        if doesfilehavevideocheckname
            load(badframefilename,'videoname_check');
        else
            warning('Problem with bad frame file, no video name was in bad frame datafile');
        end
    else
        error('Problem with bad frame file, MATLAB data file does not have any good frame info');
    end
    
    if (exist('videoname_check','var')) && isempty(videoname_check) ||...
            (strcmp(videoname_check,videofilename) == 0)
        warning('Problem with video name in bad frame MAT file')
        warning('Bad frame info was obtained from different video / Video info was in matlab data file is empty');
    end
    if isempty(goodframesforrefanalysis)
        error('Problem with good frame info, MATLAB data file does not have any good frame info');
    end
    
    framesforreference_indices = [1:frameincrement:length(goodframesforrefanalysis)];
    framesforreference = goodframesforrefanalysis(framesforreference_indices);
else
    framesforreference = badframefilename(:);
end

if sum(rem(framesforreference,1)) > 0
    warning('Sorry program can analyse frames with decimal indices, rounding off frames numbers');
    framesforreference = unique(round(framesforreference));
end
if min(framesforreference(:)) < 1
    warning('Frame numbers supplied for refererence creation has 0/Neg numbers, deleting the crazy numbers');
    framesforreference = unique(sort(framesforreference(framesforreference >= 1),'ascend'));
end
if max(framesforreference(:)) > numbervideoframes
    warning('Frame numbers supplied for refererence creation has number greater than number of frames in video');
    warning('Deleting the crazy numbers');
    framesforreference = unique(sort(framesforreference(framesforreference <= numbervideoframes),'ascend'));
end

subpixelflag = correlationflags(1);
windowflag = correlationflags(2);
correlverbose = verbosityarray(1);
shiftverbose = verbosityarray(2);
peakratioverbose = verbosityarray(3);
referenceverbose = verbosityarray(4);

cd(currentdirectory);

thumbnail_factor = 10;
stabmaxsizeincrement = 3;
stabsplineflag = 1;
stabverbose = 0;

numframesforreference = length(framesforreference);

referencesize_x = size(referenceimage_prior,2);
referencesize_y = size(referenceimage_prior,1);

if (referencesize_x < framewidth) || (referencesize_y < frameheight)
    disp('Reference image is smaller than video frame')
    warning('Parts of the video might not be registered using current reference image')
end

reference_xcentre = floor(referencesize_x / 2) + 1;
frame_xcentre = floor(framewidth / 2) + 1;

yincrement = floor((referencesize_y - frameheight) / 2);

defaultsearchzone_hori_strips = round(framewidth / 3);
defaultsearchzone_hori_strips_reduced = round(defaultsearchzone_hori_strips / 3);

if ~rem(defaultsearchzone_vert_strips,2)
    defaultsearchzone_vert_strips = defaultsearchzone_vert_strips + 1;
end
defaultsearchzone_vert_strips_reduced = round(defaultsearchzone_vert_strips / 2);
if ~rem(defaultsearchzone_vert_strips_reduced,2)
    defaultsearchzone_vert_strips_reduced = defaultsearchzone_vert_strips_reduced + 1;
end
if defaultsearchzone_vert_strips_reduced <= stripheight
    defaultsearchzone_vert_strips_reduced = stripheight + 1 + rem(stripheight,2);
end

if rem(stripheight,2) == 0
    stripheight = stripheight - 1;
end

numstrips = round(samplerate / videoframerate);
stripseparation = round(numlinesperfullframe / numstrips);

stripidx(1) = round(stripseparation / 2); % The location of the first strip
if numstrips > 1
    for stripcounter = 2:numstrips
        stripidx(stripcounter) = stripidx(stripcounter - 1) + stripseparation;
    end
end

stripidx = stripidx(stripidx <= frameheight);
stripidx = stripidx(:);
numstrips = length(stripidx);
mingoodstripsperframes = numstrips * minpercentofgoodstripsperframe;

if mingoodstripsperframes < 2
    warning('Increasing minimum number of good strips to 2');
    mingoodstripsperframes = 2;
end

if numstrips <= 4
    centralstripmatrixindex = max(min(floor(numstrips / 2),numstrips),1);
else
    if numstrips == 5
        centralstripmatrixindex = [2,4]';
    else
        if (numstrips > 5) && (numstrips <= 10)
            centralstripmatrixindex = zeros(3,1);
            centralstripmatrixindex(:) = ceil(numstrips / 4);
            centralstripmatrixindex = cumsum(centralstripmatrixindex);
            centralstripmatrixindex = unique(min(centralstripmatrixindex,numstrips));
        else
            if (numstrips > 10)
                centralstripmatrixindex = zeros(5,1);
                centralstripmatrixindex(:) = ceil(numstrips / 5);
                centralstripmatrixindex = cumsum(centralstripmatrixindex);
                centralstripmatrixindex = unique(min(centralstripmatrixindex,numstrips));
            end
        end
    end
end

numcentralstrips = length(centralstripmatrixindex);

frameshifts_thumbnails = zeros(numframesforreference,2);
peakratios_thumbnails = ones(numframesforreference,1);
maxvals_thumbnails = ones(numframesforreference,1);
secondpeaks_thumbnails = ones(numframesforreference,1);
noises_thumbnails = ones(numframesforreference,1);

frameshifts_strips_unwraped = zeros(numstrips,numframesforreference,2);
peakratios_strips_unwraped = zeros(numstrips,numframesforreference,1);
maxvals_strips_unwraped = ones(numstrips,numframesforreference,1);
secondpeaks_strips_unwraped = ones(numstrips,numframesforreference,1);
noises_strips_unwraped = ones(numstrips,numframesforreference,1);

totalnumsamples = numframesforreference * numstrips;

referenceimage_thumbnail = makethumbnail(referenceimage_prior,thumbnail_factor,thumbnail_factor);

xorigin = frame_xcentre;

wasgoodcorrelation = zeros(numstrips,numframesforreference);

if any(verbosityarray)
    toplotfeedbackfigs = 1;
    figurewidth = round((screensize(3) - 50) / 3);
    figureheight = round(screensize(4) / 3);
    
    if correlverbose
        correlfig = figure;
        correlaxis = axes;
        newposition = [0,(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(correlfig,'Position',newposition,'Toolbar','none','Name','Cross-Correlation Function');
        set(correlaxis,'Zlim',[-1 1]');
        set(get(correlaxis,'XLabel'),'String','Horizontal Pixel Index')
        set(get(correlaxis,'YLabel'),'String','Vertical Pixel Index');
        set(get(correlaxis,'ZLabel'),'String','Correlation Strength');
        set(get(correlaxis,'Title'),'String','Cross-correlation Function');
        plottedcorrelmesh = 0;
    end
    
    if shiftverbose
        shiftstoplot = zeros(totalnumsamples,2);
        shiftfig = figure;
        shiftaxis = axes;
        shiftplot_hori = plot(shiftstoplot(:,1),'Color',[0 0 1]);
        hold on
        shiftplot_vert = plot(shiftstoplot(:,2),'Color',[0 1 0]);
        hold off;
        newposition = [figurewidth + 25,(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(shiftfig,'Position',newposition,'Toolbar','none','Name','Pixel Shifts');
        set(shiftaxis,'Xlim',[1 totalnumsamples],...
            'YLim',round([(-0.25 * frameheight) (0.25 * frameheight)]));
        set(get(shiftaxis,'XLabel'),'String','Sample No.')
        set(get(shiftaxis,'YLabel'),'String','Shift (Pixels)');
        set(get(shiftaxis,'Title'),'String','Pixel Shifts');
    end
    
    if peakratioverbose
        peakratstoplot = zeros(totalnumsamples,1);
        threshtoplot = repmat(badstripthreshold,totalnumsamples,1);
        peakratfig = figure;
        peakrataxis = axes;
        peakplot = plot(peakratstoplot,'Color',[0 0 1]);
        hold on
        plot(threshtoplot,'Color',[0 0 0]);
        hold off
        newposition = [(2 * (figurewidth + 25)),(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(peakratfig,'Position',newposition,'Toolbar','none','Name','Peak Ratios');
        set(peakrataxis,'Xlim',[1 totalnumsamples],'YLim',[0 1]);
        set(get(peakrataxis,'XLabel'),'String','Sample No.')
        set(get(peakrataxis,'YLabel'),'String','Peak Ratio');
        set(get(peakrataxis,'Title'),'String','Peak Ratios');
    end
    
    if shiftverbose || peakratioverbose
        stripindxaddition = [1:numstrips];
    end
else
    toplotfeedbackfigs = 0;
end

xsearchzone = defaultsearchzone_hori_strips;
ysearchzone = defaultsearchzone_vert_strips;

analysisprog = waitbar(0,'Thumbnail and Low Rate Analysis');
oldwaitbarposition = get(analysisprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,(oldwaitbarposition(4) + 20),...
    oldwaitbarposition(3),oldwaitbarposition(4)];
set(analysisprog,'Position',newwaitbarposition);


for framecounter = 1:numframesforreference
    testframenumber = framesforreference(framecounter);
    
    if toanalysevideo
        videoinfo.CurrentTime = (testframenumber-1)*(1/videoinfo.FrameRate);
        testframe = double(readFrame(videoinfo));
        if istruecolor
            testframe = testframe(:,:,1);
        end
    else
        testframe = videoname(:,:,testframenumber);
    end
    
    testframe_thumbnail = makethumbnail(testframe,thumbnail_factor,thumbnail_factor);
    
    [correlation shifts peaks_noise] = ...
        corr2d(referenceimage_thumbnail,testframe_thumbnail,subpixelflag,windowflag);
    
    if peaks_noise(3) == 0
        peaks_noise(3) = 1;
    end
    
    peakratio = peaks_noise(2) / peaks_noise(1);
    xpixelshift = shifts(1) * thumbnail_factor;
    ypixelshift = shifts(2) * thumbnail_factor;
    
    if peakratio > badstripthreshold
        [correlation tempshifts temppeaks_noise] = ...
            corr2d(referenceimage_prior,testframe,subpixelflag,windowflag);
        
        if temppeaks_noise(3) == 0
            temppeaks_noise(3) = 1;
        end
        
        temppeakratio = temppeaks_noise / temppeaks_noise(1);
        if temppeakratio <= badstripthreshold
            peakratio = temppeakratio;
            peaks_noise = temppeaks_noise;
            xpixelshift = tempshifts(1);
            ypixelshift = tempshifts(2);
        end
    end
    
    if toplotfeedbackfigs
        namestring = ['Frame No.:- ',num2str(testframenumber)];
        titlestring = ['Frame No.:- ',num2str(testframenumber)];
        
        if shiftverbose || peakratioverbose
            indicesintomatrices = ((framecounter - 1) * numstrips) + stripindxaddition;
        end
        
        if correlverbose
            if ~plottedcorrelmesh
                figure(correlfig);
                correlmeshhandle = mesh(correlaxis,correlation);
                plottedcorrelmesh = 1;
            else
                figure(correlfig);
                set(correlmeshhandle,'Zdata',correlation);
            end
            set(correlfig,'Name',['Cross-Correlation Function: ',namestring]);
            set(get(correlaxis,'Title'),'String',['Cross-correlation Function: ',titlestring]);
            set(correlaxis,'Zlim',[-0.2 1]');
        end
        
        if shiftverbose
            figure(shiftfig);
            shiftstoplot_h = get(shiftplot_hori,'YData');
            shiftstoplot_v = get(shiftplot_vert,'YData');
            shiftstoplot = [shiftstoplot_h(:),shiftstoplot_v(:)];
            shiftstoplot(indicesintomatrices,:) =...
                repmat([xpixelshift ypixelshift],numstrips,1);
            set(shiftplot_hori,'YData',shiftstoplot(:,1));
            set(shiftplot_vert,'YData',shiftstoplot(:,2));
            set(shiftfig,'Name',['Cross-Correlation Function: ',namestring]);
            set(get(shiftaxis,'Title'),'String',['Pixel Shifts: ',titlestring]);
        end
        
        if peakratioverbose
            figure(peakratfig);
            peakratstoplot = get(peakplot,'YData');
            peakratstoplot(indicesintomatrices) =...
                repmat(peakratio,numstrips,1);
            set(peakplot,'YData',peakratstoplot);
            set(peakratfig,'Name',['Peak Ratios: ',namestring]);
            set(get(peakrataxis,'Title'),'String',['Peak Ratios: ',titlestring]);
        end
        drawnow
    end
    
    frameshifts_thumbnails(framecounter,:) = [xpixelshift ypixelshift];
    peakratios_thumbnails(framecounter) = peakratio;
    maxvals_thumbnails(framecounter) = peaks_noise(1);
    secondpeaks_thumbnails(framecounter) = peaks_noise(2);
    noises_thumbnails(framecounter) = peaks_noise(3);
    
    if peakratio <= badstripthreshold
        xmovement = round(xpixelshift);
        ymovement = round(ypixelshift);
        for stripcounter = 1:numcentralstrips
            indexintostripmatrix = centralstripmatrixindex(stripcounter);
            
            yorigin = stripidx(indexintostripmatrix);
            
            refxorigin = reference_xcentre - xmovement;
            refyorigin = yorigin + yincrement - ymovement;
            
            referencematrix = getsubmatrix(referenceimage_prior,...
                refxorigin,refyorigin,xsearchzone,ysearchzone,[1 referencesize_x],...
                [1 referencesize_y],0,0);
            teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzone,...
                stripheight,[1 framewidth], [1 frameheight],0,0);
            
            [correlation shifts peaks_noise] = findthestrip(referencematrix,teststrip,...
                subpixelflag,windowflag);
            
            peakratio = peaks_noise(2) / peaks_noise(1);
            
            if peakratio <= badstripthreshold
                wasgoodcorrelation(indexintostripmatrix,framecounter) = 1;
                
                xpixelshift = xmovement + shifts(1);
                ypixelshift = ymovement + shifts(2);
                
                frameshifts_strips_unwraped(indexintostripmatrix,framecounter,:) = cat(3,xpixelshift,ypixelshift);
                peakratios_strips_unwraped(indexintostripmatrix,framecounter) = peakratio;
                maxvals_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(1);
                secondpeaks_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(2);
                noises_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(3);
                
                if toplotfeedbackfigs
                    namestring = ['Frame No.:- ',num2str(testframenumber),', Strip No.:- ',num2str(indexintostripmatrix)];
                    titlestring = ['Frame No.:- ',num2str(testframenumber),', Strip No.:- ',num2str(indexintostripmatrix)];
                    
                    if shiftverbose || peakratioverbose
                        indexintomatrices = ((framecounter - 1) * numstrips) + indexintostripmatrix;
                    end
                    
                    if correlverbose
                        figure(correlfig);
                        set(correlmeshhandle,'Zdata',correlation);
                        set(correlfig,'Name',['Cross-Correlation Function: ',namestring]);
                        set(get(correlaxis,'Title'),'String',['Cross-correlation Function: ',titlestring]);
                        set(correlaxis,'Zlim',[-0.2 1]');
                    end
                    
                    if shiftverbose
                        figure(shiftfig);
                        shiftstoplot_h = get(shiftplot_hori,'YData');
                        shiftstoplot_v = get(shiftplot_vert,'YData');
                        shiftstoplot = [shiftstoplot_h(:),shiftstoplot_v(:)];
                        shiftstoplot(indexintomatrices,:) = [xpixelshift ypixelshift];
                        set(shiftplot_hori,'YData',shiftstoplot(:,1));
                        set(shiftplot_vert,'YData',shiftstoplot(:,2));
                        set(shiftfig,'Name',['Cross-Correlation Function: ',namestring]);
                        set(get(shiftaxis,'Title'),'String',['Pixel Shifts: ',titlestring]);
                    end
                    
                    if peakratioverbose
                        figure(peakratfig);
                        peakratstoplot = get(peakplot,'YData');
                        peakratstoplot(indexintomatrices) = peakratio;
                        set(peakplot,'YData',peakratstoplot);
                        set(peakratfig,'Name',['Peak Ratios: ',namestring]);
                        set(get(peakrataxis,'Title'),'String',['Peak Ratios: ',titlestring]);
                    end
                    drawnow
                end
            end
        end
    end
    
    prog = framecounter / numframesforreference;
    waitbar(prog,analysisprog);
end

goodmatchindices_thumbnails = peakratios_thumbnails <= badstripthreshold;

framesforreference_initial = framesforreference;
framesforreference = framesforreference(goodmatchindices_thumbnails);
numframesforreference = length(framesforreference);

wasgoodcorrelation = wasgoodcorrelation(:,goodmatchindices_thumbnails);

frameshifts_strips_unwraped = frameshifts_strips_unwraped(:,goodmatchindices_thumbnails,:);
peakratios_strips_unwraped = peakratios_strips_unwraped(:,goodmatchindices_thumbnails);
maxvals_strips_unwraped = maxvals_strips_unwraped(:,goodmatchindices_thumbnails);
secondpeaks_strips_unwraped = secondpeaks_strips_unwraped(:,goodmatchindices_thumbnails);
noises_strips_unwraped = noises_strips_unwraped(:,goodmatchindices_thumbnails);

xsearchzone = defaultsearchzone_hori_strips;
ysearchzone = defaultsearchzone_vert_strips;

xsearchzone_reduced = defaultsearchzone_hori_strips_reduced;
ysearchzone_reduced = defaultsearchzone_vert_strips_reduced;

absthumbnailvelocities = abs([[0,0];diff(frameshifts_thumbnails,[],1)]);

waitbar(0,analysisprog,'Higher Rate Analysis');
for framecounter = 1:numframesforreference
    testframenumber = framesforreference(framecounter);
    videoinfo.CurrentTime = (testframenumber-1)*(1/videoinfo.FrameRate);
    testframe = double(readFrame(videoinfo));
    if istruecolor
        testframe = testframe(:,:,1);
    end
    
    currentframethumbnailvelocity = absthumbnailvelocities(framecounter,:);
    if currentframethumbnailvelocity(1) > defaultsearchzone_hori_strips
        toincreasesearchzone_h = 1;
    else
        toincreasesearchzone_h = 0;
    end
    if currentframethumbnailvelocity(1) > defaultsearchzone_vert_strips
        toincreasesearchzone_v = 1;
    else
        toincreasesearchzone_v = 0;
    end
    
    for stripcounter = 1:numstrips
        if wasgoodcorrelation(stripcounter,framecounter) == 1
            continue
        end
        
        if stripcounter > 1
            stripindexofprevstrip = stripcounter - 1;
            frameindexofprevstrip = framecounter;
            wasprevstripagoodmatch = wasgoodcorrelation(stripindexofprevstrip,frameindexofprevstrip);
            if framecounter == 1
                wasprevstripagoodmatch = 0;
            end
        else
            wasprevstripagoodmatch = 0;
        end
        
        yorigin = stripidx(stripcounter);
        
        if wasprevstripagoodmatch
            xmovement = round(frameshifts_strips_unwraped(stripindexofprevstrip,...
                frameindexofprevstrip,1));
            ymovement = round(frameshifts_strips_unwraped(stripindexofprevstrip,...
                frameindexofprevstrip,2));
            
            xsearchzonetouse = xsearchzone_reduced;
            ysearchzonetouse = ysearchzone_reduced;
        else
            xmovement = round(frameshifts_thumbnails(framecounter,1));
            ymovement = round(frameshifts_thumbnails(framecounter,2));
            
            xsearchzonetouse = xsearchzone;
            ysearchzonetouse = ysearchzone;
        end
        
        if toincreasesearchzone_h
            xsearchzonetouse = round(xsearchzonetouse * 2.5);
        end
        if toincreasesearchzone_v
            ysearchzonetouse = round(ysearchzonetouse * 2.5);
        end
        
        refxorigin = reference_xcentre - xmovement;
        refyorigin = yorigin + yincrement - ymovement;
        
        referencematrix = getsubmatrix(referenceimage_prior,refxorigin,refyorigin,...
            xsearchzonetouse,ysearchzonetouse,[1 referencesize_x], [1 referencesize_y],0,0);
        teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
            stripheight,[1 framewidth], [1 frameheight],0,0);
        
        [correlation shifts peaks_noise] =....
            findthestrip(referencematrix,teststrip,subpixelflag,windowflag);
        
        peakratio = peaks_noise(2) / peaks_noise(1);
        
        if peakratio > badstripthreshold
            xsearchzonetouse = min(xsearchzonetouse * 4,framewidth);
            ysearchzonetouse = min(ysearchzonetouse * 4,frameheight);
            
              referencematrix = getsubmatrix(referenceimage_prior,refxorigin,refyorigin,...
                xsearchzonetouse,ysearchzonetouse,[1 referencesize_x], [1 referencesize_y],0,0);
            teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
                stripheight,[1 framewidth], [1 frameheight],0,0);
            
            [correlation tempshifts temppeaks_noise] =....
                findthestrip(referencematrix,teststrip,subpixelflag,windowflag);
            
            temppeakratio = temppeaks_noise(2) / temppeaks_noise(1);
            if temppeakratio <= badstripthreshold
                shifts = tempshifts;
                peaks_noise = temppeaks_noise;
                peakratio = temppeakratio;
            end
        end
        
        xpixelshift = xmovement + shifts(1);
        ypixelshift = ymovement + shifts(2);
        
        frameshifts_strips_unwraped(stripcounter,framecounter,:) = cat(3,xpixelshift, ypixelshift);
        maxvals_strips_unwraped(stripcounter,framecounter) = peaks_noise(1);
        secondpeaks_strips_unwraped(stripcounter,framecounter) = peaks_noise(2);
        noises_strips_unwraped(stripcounter,framecounter) = peaks_noise(3);
        peakratios_strips_unwraped(stripcounter,framecounter) = peakratio;
        
        if toplotfeedbackfigs
            namestring = ['Frame No.:- ',num2str(testframenumber),', Strip No.:- ',num2str(stripcounter)];
            titlestring = ['Frame No.:- ',num2str(testframenumber),', Strip No.:- ',num2str(stripcounter)];
            
            if shiftverbose || peakratioverbose
                indexintomatrices = ((framecounter - 1) * numstrips) + stripcounter;
            end
            
            if correlverbose
                figure(correlfig);
                set(correlmeshhandle,'Zdata',correlation);
                set(correlfig,'Name',['Cross-Correlation Function: ',namestring]);
                set(get(correlaxis,'Title'),'String',['Cross-correlation Function: ',titlestring]);
                set(correlaxis,'Zlim',[-0.2 1]');
            end
            
            if shiftverbose
                figure(shiftfig);
                shiftstoplot_h = get(shiftplot_hori,'YData');
                shiftstoplot_v = get(shiftplot_vert,'YData');
                shiftstoplot = [shiftstoplot_h(:),shiftstoplot_v(:)];
                shiftstoplot(indexintomatrices,:) = [xpixelshift ypixelshift];
                set(shiftplot_hori,'YData',shiftstoplot(:,1));
                set(shiftplot_vert,'YData',shiftstoplot(:,2));
                set(shiftfig,'Name',['Cross-Correlation Function: ',namestring]);
                set(get(shiftaxis,'Title'),'String',['Pixel Shifts: ',titlestring]);
            end
            
            if peakratioverbose
                figure(peakratfig);
                peakratstoplot = get(peakplot,'YData');
                peakratstoplot(indexintomatrices) = peakratio;
                set(peakplot,'YData',peakratstoplot);
                set(peakratfig,'Name',['Peak Ratios: ',namestring]);
                set(get(peakrataxis,'Title'),'String',['Peak Ratios: ',titlestring]);
            end
            drawnow
        end
        
        if peakratio <= badstripthreshold
            wasgoodcorrelation(stripcounter,framecounter) = 1;
        end
    end
    
    prog = framecounter / numframesforreference;
    waitbar(prog,analysisprog);
end

peakratios_strips = peakratios_strips_unwraped(:);
maxvals_strips = maxvals_strips_unwraped(:);
secondpeaks_strips = secondpeaks_strips_unwraped(:);
noises_strips = noises_strips_unwraped(:);

badmatches_initial = find(peakratios_strips > badstripthreshold);

if ~isempty(badmatches_initial)
    frameshifts_strips_spline_unwraped = zeros(size(frameshifts_strips_unwraped));
    badmatchaddition = [-3:3];
    numbadmatchindicestoadd = length(badmatchaddition);
    
    badmatches = repmat(badmatches_initial(:),1,numbadmatchindicestoadd) +...
        repmat(badmatchaddition,length(badmatches_initial),1);
    
    badmatches = sort(unique(min(max(badmatches(:),1),length(peakratios_strips))),'ascend');
    goodmatches = setdiff([1:length(peakratios_strips)]',badmatches);
    
    if abs((length(badmatches) - length(peakratios_strips))) <= 2
        if abs((length(badmatches_initial) - length(peakratios_strips))) <= 2
            goodmatches = [1:length(peakratios_strips)]';
        else
            goodmatches = setdiff([1:length(peakratios_strips)]',badmatches_initial);
        end
    end
    
    interp_xaxis = [0:(numlinesperfullframe * numbervideoframes) - 1];
    interp_xaxis = reshape(interp_xaxis,numlinesperfullframe,numbervideoframes);
    interp_xaxis = interp_xaxis(stripidx,framesforreference);
    interp_xaxis = interp_xaxis(:);
    sample_xaxis = interp_xaxis(goodmatches);
    timeaxis = interp_xaxis;
    
    waitbar(0,analysisprog,'Interpolating Through Bad Shifts');
    for directioncounter = 1:2
        tempshifts = frameshifts_strips_unwraped(:,:,directioncounter);
        sample_yaxis = tempshifts(:);
        interp_yaxis = interp1(sample_xaxis,sample_yaxis(goodmatches),...
            interp_xaxis,'linear','extrap');
        frameshifts_strips_spline_unwraped(:,:,directioncounter) =...
            reshape(interp_yaxis,numstrips,numframesforreference);
        
        prog = directioncounter / 2;
        waitbar(prog,analysisprog);
    end
    
else
    badmatches = [];
    goodmatches = [1:length(peakratios_strips)]';
    timeaxis = [0:(numlinesperfullframe * numbervideoframes) - 1];
    timeaxis = reshape(timeaxis,numlinesperfullframe,numbervideoframes);
    timeaxis = timeaxis(stripidx,framesforreference);
    timeaxis = timeaxis(:);
    frameshifts_strips_spline_unwraped = frameshifts_strips_unwraped;
end

close(analysisprog);

if toplotfeedbackfigs
    if correlverbose
        close(correlfig);
    end
    
    if shiftverbose
        close(shiftfig);
    end
    
    if peakratioverbose
        close(peakratfig);
    end
end

timeaxis_secs = timeaxis / (numlinesperfullframe * videoframerate);

frameshifts_strips = zeros(numframesforreference * numstrips,2);
frameshifts_strips_spline = zeros(numframesforreference * numstrips,2);

for directioncounter = 1:2
    tempshifts = frameshifts_strips_unwraped(:,:,directioncounter);
    frameshifts_strips(:,directioncounter) = tempshifts(:);
    
    tempshifts = frameshifts_strips_spline_unwraped(:,:,directioncounter);
    frameshifts_strips_spline(:,directioncounter) = tempshifts(:);
end

todropfirstframe = 0;
todroplastframe = 0;

firstgoodsample = min(goodmatches(:));
lastgoodsample = max(goodmatches(:));

firstgoodframe = ceil(firstgoodsample / numstrips);
lastgoodframe = ceil(lastgoodsample / numstrips);

if firstgoodframe > 1
    todropfirstframe = 1;
end
if lastgoodframe < numframesforreference
    todroplastframe = 1;
end

if max(badmatches(:)) == size(peakratios_strips,1)
    for directioncounter = 1:2
        frameshifts_strips(lastgoodsample + 1:end,directioncounter) =...
            frameshifts_strips(lastgoodsample,directioncounter);
        
        frameshifts_strips_spline(lastgoodsample + 1:end,directioncounter) =...
            frameshifts_strips_spline(lastgoodsample,directioncounter);
    end
end

if min(badmatches(:)) == 1
    for directioncounter = 1:2
        frameshifts_strips(1:firstgoodsample - 1,directioncounter) =...
            frameshifts_strips(firstgoodsample,directioncounter);
        
        frameshifts_strips_spline(1:firstgoodsample - 1,directioncounter) =...
            frameshifts_strips_spline(firstgoodsample,directioncounter);
    end
end

isgoodstrip = peakratios_strips_unwraped <= badstripthreshold;
numgoodstripsinframes = sum(isgoodstrip,1);
dropframeflag = find(numgoodstripsinframes < mingoodstripsperframes);
dropframeflag = dropframeflag(:);

if todropfirstframe
    if firstgoodframe > 2
        dropframeflag = [dropframeflag;[1:firstgoodframe - 1]'];
    else
        dropframeflag = [dropframeflag;1];
    end
end
if todroplastframe
    if lastgoodframe < (numframesforreference - 1)
        dropframeflag = [dropframeflag;[lastgoodframe + 1:numframesforreference]'];
    else
        dropframeflag = [dropframeflag;numframesforreference];
    end
end

if isempty(dropframeflag)
    framesthweredropped = [];
    frameshifts_strips_withbadframes = [];
    frameshifts_strips_spline_withbadframes = [];
    maxvals_strips_withbadframes = [];
    secondpeaks_strips_withbadframes = [];
    noises_strips_withbadframes = [];
    peakratios_strips_withbadframes = [];
else
    frameshifts_strips_withbadframes = frameshifts_strips;
    frameshifts_strips_spline_withbadframes = frameshifts_strips_spline;
    maxvals_strips_withbadframes = maxvals_strips;
    secondpeaks_strips_withbadframes = secondpeaks_strips;
    noises_strips_withbadframes = noises_strips;
    peakratios_strips_withbadframes = peakratios_strips;
    
    indicesdropped = dropframeflag;
    frameindicestouse = setdiff([1:numframesforreference]',indicesdropped(:));
    framesthweredropped = framesforreference(indicesdropped);
    
    framesforreference = framesforreference(frameindicestouse);
    
    frameshifts_strips_unwraped = frameshifts_strips_unwraped(:,frameindicestouse,:);
    frameshifts_strips_spline_unwraped = frameshifts_strips_spline_unwraped(:,frameindicestouse,:);
    maxvals_strips_unwraped = maxvals_strips_unwraped(:,frameindicestouse);
    secondpeaks_strips_unwraped = secondpeaks_strips_unwraped(:,frameindicestouse);
    noises_strips_unwraped = noises_strips_unwraped(:,frameindicestouse);
    peakratios_strips_unwraped = peakratios_strips_unwraped(:,frameindicestouse);
end


frameshifts_strips = zeros(length(framesforreference) * numstrips,2);
frameshifts_strips_spline = zeros(length(framesforreference) * numstrips,2);

for directioncounter = 1:2
    tempshifts = frameshifts_strips_unwraped(:,:,directioncounter);
    frameshifts_strips(:,directioncounter) = tempshifts(:);
    
    tempshifts = frameshifts_strips_spline_unwraped(:,:,directioncounter);
    frameshifts_strips_spline(:,directioncounter) = tempshifts(:);
end

maxvals_strips = maxvals_strips_unwraped(:);
secondpeaks_strips = secondpeaks_strips_unwraped(:);
noises_strips = noises_strips_unwraped(:);
peakratios_strips = peakratios_strips_unwraped(:);

if length(framesforreference) >= 2
    [referencematrix,referencematrix_full] = makestabilizedframe(videoname,...
        framesforreference,frameshifts_strips_spline,peakratios_strips,...
        stripidx,badstripthreshold,numlinesperfullframe,stabmaxsizeincrement,stabsplineflag,stabverbose);
else
    videoinfo.CurrentTime = (framesforreference_initial(1)-1)*(1/videoinfo.FrameRate);
    frametoadd = double(readFrame(videoinfo));
    referencematrix = repmat(frametoadd,[1 1 3]);
    referencematrix_full = referencematrix;
end

referenceimage = referencematrix(:,:,2);

randstring = num2str(min(ceil(rand(1) * 10000),9999));
sampleratestring = num2str(samplerate);
fullstring = strcat('_priorrefdata_',sampleratestring,'hz_',num2str(frameincrement),'_',randstring,'.mat');

if toanalysevideo
    datafilename = strcat(videoname(1:end - 4),fullstring);
else
    datafilename = fullstring(2:end);
end

analysedframes = framesforreference;
analysedframes_initial = framesforreference_initial;
videoname_check = videofilename;

save(datafilename,'referenceimage','referencematrix','referencematrix_full',...
    'referenceimage_prior','frameshifts_strips','frameshifts_strips_spline',...
    'frameshifts_thumbnails','maxvals_strips','secondpeaks_strips','peakratios_strips',...
    'noises_strips','maxvals_thumbnails','secondpeaks_thumbnails','noises_thumbnails',...
    'peakratios_thumbnails','samplerate','defaultsearchzone_vert_strips','stripheight',...
    'badstripthreshold','numlinesperfullframe','frameincrement','analysedframes','stripidx',...
    'videoname_check','timeaxis','timeaxis_secs','framewidth','frameheight','thumbnail_factor',...
    'goodmatchindices_thumbnails','analysedframes_initial','minpercentofgoodstripsperframe',...
    'framesthweredropped','frameshifts_strips_withbadframes','frameshifts_strips_spline_withbadframes',...
    'maxvals_strips_withbadframes','secondpeaks_strips_withbadframes','noises_strips_withbadframes',...
    'peakratios_strips_withbadframes');

if referenceverbose
    mymap = repmat([0:255]' / 256,1,3);
    titlestring = ['Reference Frame from video ',videofilename];
    figure;
    set(gcf,'Name','Reference Frame');
    image(referenceimage);
    colormap(mymap);
    axis off;
    title(titlestring,'Interpreter','none');
    truesize;
end


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help makereference_priorref'' for usage');
end
cd(videopath);
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function filename = getreffilename(currentdir)
[fname pname] = uigetfile('*.mat','Please enter the matfile with the reference image data');
if fname == 0
    cd(currentdir);
    disp('Need bad/good frame data,stopping program');
    error('Type ''help makereference_priorref'' for usage');
else
    filename = strcat(pname,fname);
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function filename = getbadframefilename(currentdir)
[fname pname] = uigetfile('*.mat','Please enter the matfile with the blink frame data');
if fname == 0
    cd(currentdir);
    disp('Need blink frame infomation,stopping program');
    error('Type ''help makereference_priorref'' for usage');
else
    filename = strcat(pname,fname);
end
%--------------------------------------------------------------------------