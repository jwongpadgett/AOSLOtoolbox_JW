function datafilename = analysevideo_priorref(videoname,refframefilename,blinkframefilename,...
    referencevarname,searchparamstruct,programflags,correlationflags,verbosityarray)

rand('state',sum(100 * clock));
randn('state',sum(100 * clock));

currentdirectory = pwd;
screensize = get(0,'Screensize');
if ispc
    pathslash = '\';
else
    pathslash = '/';
end

if (nargin < 1) || isempty(videoname)
    togetvideoname = 1;
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
            togetvideoname = 0;
        else
            disp('Supplied video name does not point to a valid file');
            togetvideoname = 1;
        end
    else
        disp('Supplied video name must be a string');
        togetvideoname = 1;
    end
end

if togetvideoname
    [videofilename videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
    if videofilename == 0
        disp('No video to analyse,stopping program');
        error('Type ''help analysevideo_priorref'' for usage');
    else
        videoname = strcat(videopath,videofilename);
        cd(videopath);
    end
end

videoinfo = VideoReader(videoname); % Get important info of the avifile
videoframerate = round(videoinfo.FrameRate); % The videoframerate of the video
numbervideoframes = round(videoinfo.FrameRate*videoinfo.Duration);
framewidth = videoinfo.Width; % The width of the video (in pixels)
frameheight = videoinfo.Height; % The height of the video (in pixels)
videotype = videoinfo.VideoFormat;

if strcmp(videotype,'truecolor')
    disp('Video being analyssed is a truecolor video, this program can analyse only 8 bit videos!!');
    warning('Using only the first layer of the video during analyses');
    istruecolor = 1;
else
    istruecolor = 0;
end

if (nargin < 2) || isempty(refframefilename)
    togetrefframefilename = 1;
else
    if ischar(refframefilename)
        if exist(refframefilename,'file')
            togetrefframefilename = 0;
            togetreferencevarname = 1;
            toloadreference = 1;
        else
            disp('Second input string does not point to a valid mat file');
            togetrefframefilename = 1;
        end
    else
        if isnumeric(refframefilename)
            togetrefframefilename = 0;
            togetreferencevarname = 0;
            toloadreference = 0;
            referenceimage_prior = refframefilename;
        else
            disp('Second input argument must be a string or 2D double matrix');
            togetrefframefilename = 1;
        end
    end
end

if togetrefframefilename
    [fname pname] = uigetfile('*.mat','Please enter the matfile with the reference image data');
    if fname == 0
        cd(currentdirectory);
        disp('Need reference data,stopping program');
        error('Type ''help analysevideo_priorref'' for usage');
    else
        refframefilename = strcat(pname,fname);
        togetreferencevarname = 1;
        toloadreference = 1;
    end
end

if (nargin < 3) || isempty(blinkframefilename)
    togetbadframefilename = 1;
else
    if ischar(blinkframefilename)
        if exist(blinkframefilename,'file')
            togetbadframefilename = 0;
            toloadblinkframes = 1;
        else
            disp('Third input string does point to a valid mat file');
            togetbadframefilename = 1;
        end
    else
        if isnumeric(blinkframefilename)
            toloadblinkframes = 0;
            togetbadframefilename = 0;
        else
            disp('Third input argument must be either a string or numeric array');
            togetbadframefilename = 1;
        end
    end
end

if togetbadframefilename
    [fname pname] = uigetfile('*.mat','Please enter the matfile with the bad frame data');
    if fname == 0
        cd(currentdirectory);
        disp('Need bad/good frame data,stopping program');
        error('Type ''help makereference_priorref'' for usage');
    else
        blinkframefilename = strcat(pname,fname);
        toloadblinkframes = 1;
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
        'Horizontal Search Zone (Pixels)','Strip Height (Pixels)','Start Frame',...
        'End Frame','Bad Strip Correlation Threshold','Minimum %. of Good Strips Reqd Per Frame',...
        'Number of Lines per Full Frame'};
    
    name = 'Search Parameters Input for Reference Program';
    numlines = 1;
    defaultanswer = {'480','59',num2str(framewidth),'11','1',num2str(numbervideoframes),'0.7',...
        '0.4','525'};
    
    inputanswer = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(inputanswer)
        disp('You have pressed cancel rather than input any values');
        warning('Using default values in fields in the searchaparamstruct structure');
        inputanswer = {'480','59',num2str(framewidth),'11','1',num2str(numbervideoframes),'0.7',...
            '0.4','525'};
    end
    
    searchparamstruct = struct('samplerate',str2double(inputanswer{1}),...
        'vertsearchzone',str2double(inputanswer{2}),'horisearchzone',...
        str2double(inputanswer{3}),'stripheight',str2double(inputanswer{4}),...
        'startframe',str2double(inputanswer{5}),'endframe',str2double(inputanswer{6}),...
        'badstripthreshold',str2double(inputanswer{7}),'minpercentofgoodstripsperframe',...
        str2double(inputanswer{8}),'numlinesperfullframe',str2double(inputanswer{9}));
end

if isstruct(searchparamstruct)
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
    if sum(strcmp(namesofinputfields,'horisearchzone'))
        togethorisearchzone = 0;
    else
        togethorisearchzone = 1;
    end
    if sum(strcmp(namesofinputfields,'stripheight'))
        togetstripheight = 0;
    else
        togetstripheight = 1;
    end
    if sum(strcmp(namesofinputfields,'startframe'))
        togetstartframe = 0;
    else
        togetstartframe = 1;
    end
    if sum(strcmp(namesofinputfields,'endframe'))
        togetendframe = 0;
    else
        togetendframe = 1;
    end
    if sum(strcmp(namesofinputfields,'badstripthreshold'))
        togetbadstripthreshold = 0;
    else
        togetbadstripthreshold = 1;
    end
    if sum(strcmp(namesofinputfields,'minpercentofgoodstripsperframe'))
        togetminpercentofgoodstripsperframe = 0;
    else
        togetminpercentofgoodstripsperframe = 0;
    end
    if sum(strcmp(namesofinputfields,'numlinesperfullframe'))
        togetnumlinesperfullframe = 0;
    else
        togetnumlinesperfullframe = 1;
    end
end

if (togetsamplerate + togetvertsearchzone + togethorisearchzone + togetstripheight +...
        togetstartframe + togetendframe + togetbadstripthreshold + ...
        togetminpercentofgoodstripsperframe + togetnumlinesperfullframe) > 0
    prompt = {};
    defaultanswer = {};
    if togetsamplerate
        prompt{end + 1} = 'Sample Rate (Hz)';
        defaultanswer{end + 1} = '720';
    end
    if togetvertsearchzone
        prompt{end + 1} = 'Vertical Search Zone (Pixels)';
        defaultanswer{end + 1} = '49';
    end
    if togethorisearchzone
        prompt{end + 1} = 'Horizontal Search Zone (Pixels)';
        defaultanswer{end + 1} = num2str(framewidth');
    end
    if togetstripheight
        prompt{end + 1} = 'Strip Height (Pixels)';
        defaultanswer{end + 1} = '11';
    end
    if togetstartframe
        prompt{end + 1} = 'Start Frame';
        defaultanswer{end + 1} = '1';
    end
    if togetendframe
        prompt{end + 1} = 'End Frame';
        defaultanswer{end + 1} = num2str(numbervideoframes);
    end
    if togetbadstripthreshold
        prompt{end + 1} = 'Bad Strip Correlation Threshold';
        defaultanswer{end + 1} = '0.7';
    end
    if togetminpercentofgoodstripsperframe
        prompt{end + 1} = 'Minimum %. of Good Strips Reqd Per Frame';
        defaultanswer{end + 1} = '0.4';
    end
    if togetnumlinesperfullframe
        prompt{end + 1} = 'Number of Lines per Full Frame';
        defaultanswer{end + 1} = '525';
    end
    
    name = 'Search Parameter Input for Reference Program';
    numlines = 1;
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
    if togethorisearchzone
        searchparamstruct.horisearchzone = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetstripheight
        searchparamstruct.stripheight = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetstartframe
        searchparamstruct.startframe = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetendframe
        searchparamstruct.endframe = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetbadstripthreshold
        searchparamstruct.badstripthreshold = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetminpercentofgoodstripsperframe
        searchaparamstruct.minpercentofgoodstripsperframe = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetnumlinesperfullframe
        searchaparamstruct.numlinesperfullframe = str2double(inputanswer{fieldcounter});
    end
end

if (nargin < 6) || isempty(programflags)
    disp('You have not supplied any of the required prgram flags')
    warning('Using defaults...');
    todothumbnails = 1;
    totrycorrection = 0;
else
    todothumbnails = 1;
    totrycorrection = 0;
    
    if length(programflags) < 2
        disp('Flag array is too small');
        warning('Unassigned program flags set to their defaults');
    end
    
    switch (length(programflags))
        case 1
            todothumbnails = programflags(1);
        case 2
            todothumbnails = programflags(1);
            totrycorrection = programflags(2);
    end
end

if (nargin < 7) || isempty(correlationflags)
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

if (nargin < 8) || isempty(verbosityarray)
    verbosityarray = [0; 0; 0; 0];
    correlverbose = 0;
    shiftverbose = 0;
    peakratioverbose = 0;
    referenceverbose = 0;
    toplotfeedbackfigs = 0;
    disp('No feedback will be provided!');
else
    correlverbose = 0;
    shiftverbose = 0;
    peakratioverbose = 0;
    referenceverbose = 0;
    
    if length(verbosityarray) < 4
        disp('Verbose array is too small')
        warning('Unassigned verbose flags set to zero');
    end
    
    switch (length(verbosityarray))
        case 1
            correlverbose = verbosityarray(1);
        case 2
            correlverbose = verbosityarray(1);
            shiftverbose = verbosityarray(2);
        case 3
            correlverbose = verbosityarray(1);
            shiftverbose = verbosityarray(2);
            peakratioverbose = verbosityarray(3);
        case 4
            correlverbose = verbosityarray(1);
            shiftverbose = verbosityarray(2);
            peakratioverbose = verbosityarray(3);
            referenceverbose = verbosityarray(4);
    end
end

samplerate = searchparamstruct.samplerate;
defaultsearchzone_vert_central = round(searchparamstruct.vertsearchzone);
defaultsearchzone_hori_central = round(min(searchparamstruct.horisearchzone,framewidth));
stripheight = searchparamstruct.stripheight;
startframe = searchparamstruct.startframe;
endframe = searchparamstruct.endframe;
badstripthreshold = searchparamstruct.badstripthreshold;
minpercentofgoodstripsperframe = searchparamstruct.minpercentofgoodstripsperframe;
numlinesperfullframe = searchparamstruct.numlinesperfullframe;

if rem(samplerate,1)
    disp('Sample rate should be an whole number');
    warning('Rounding off the sample rate');
    samplerate = round(samplerate);
end
if samplerate < (2 * videoframerate)
    warnig('Too Low a sample sample, increasing to twice the frame rate of video');
    samplerate = (2 * videoframerate);
end
if samplerate > (videoframerate * numlinesperfullframe)
    newsampleratestring = [num2str(videoframerate * numlinesperfullframe),' Hz'];
    dispstring = ['Too High a sample rate, decreasing to ',newsampleratestring];
    warning(dispstring);
    samplerate = (videoframerate * numlinesperfullframe);
end
if rem(samplerate,videoframerate) ~= 0
    disp('Sample rate should be multiple of the video frame rate');
    warning('Reducing sample rate to previous multiple of frame rate');
    samplerate = floor(samplerate / videoframerate) * videoframerate;
end

if defaultsearchzone_vert_central > frameheight
    disp('Default Vertical Search Zone is too high');
    warning('Reducing to 10 pixels less than frame height');
    defaultsearchzone_vert_strips = frameheight - 10;
end
if defaultsearchzone_vert_central < 10
    disp('Default Vertical Search Zone is too low');
    warning('Increasing to 10 pixels');
    defaultsearchzone_vert_strips = 10;
end

if defaultsearchzone_hori_central > framewidth
    disp('Default horizontal search zone is too high');
    warning('Reducing to frame width');
    defaultsearchzone_hori_central = frameframe;
end
if defaultsearchzone_hori_central < (framewidth / 4);
    disp('Default horizontal search zone is too low');
    warning('Increasing 1/4th the width of a single frame');
    defaultsearchzone_hori_central = round(framewidth / 4);
end

if rem(stripheight,1) ~= 0
    disp('Strip height cannot be a decimal');
    warning('Round down...');
    stripheight = floor(stripheight);
end
if stripheight >= defaultsearchzone_vert_central
    disp('Strip Height cannot be larger than vertical search zone');
    warning('Reducing strip height to one less than vertical search zone');
    stripheight = max(defaultsearchzone_vert_central - 1,1);
end
if stripheight <= 0
    disp('Strip should have atleast one line');
    warning('Increasing strip height to 1');
    stripheight = 1;
end

if startframe < 1
    disp('Videos usually do not have frames with negative frame numbers!!!');
    warning('Increasing start frame to 1');
    startframe = 1;
end
if startframe > numbervideoframes
    disp('Cannot start analysing frames after the video has ended');
    warning('Reducing start frame to 5 less than total number of video frames');
    startframe = numbervideoframes - 5;
end

if endframe == -1
    endframe = numbervideoframes;
end
if endframe < 1
    disp('Videos usually do not have frames with negative frame numbers!!!');
    warning('Increasing end frame to 5');
    endframe = 5;
end
if endframe > numbervideoframes
    disp('Cannot continue to analyse frames after the video has ended');
    warning('Reducing end frame the total number of video frames');
    endframe = numbervideoframes;
end
if endframe < startframe
    disp('Analyses can''t proceed in a backward directin');
    warning('Increasing end frame to 5 greater than start frame');
    endframe = startframe + 5;
end

if badstripthreshold >= 1
    disp('Bad Strip Threshold is too high');
    warnig('Reducing to 0.99')
    badstripthreshold = 0.99;
end
if badstripthreshold <= 0.2
    disp('Bad Strip Threshold is too low');
    warnig('Increasing to 0.01')
    badstripthreshold = 0.2;
end

if minpercentofgoodstripsperframe > 1
    disp('A little difficult to get more than 100% good strips in a frame');
    warning('Reducing minimum percentage of good strips per frame to 99%');
    minpercentofgoodstripsperframe = 0.99;
end
if minpercentofgoodstripsperframe < 0.2
    disp('To few strips per frame')
    warning('Increasing minimum percentage of good strips per frame to 20%');
    minpercentofgoodstripsperframe = 0.2;
end

if numlinesperfullframe < frameheight
    disp('Number of lines in full frame cannot be smaller than the number of lines in video frame');
    error('Type ''help analysevideo_priorref'' for usage');
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

if toloadblinkframes
    variablesinfile = who('-file',blinkframefilename);
    doesfilehaveblinkinfo = sum(strcmp(variablesinfile,'blinkframes'));
    doesfilehavevideocheckname = sum(strcmp(variablesinfile,'videoname_check'));
    if doesfilehaveblinkinfo
        load(blinkframefilename,'blinkframes');
        if doesfilehavevideocheckname
            load(blinkframefilename,'videoname_check');
        else
            disp('Problem with bad frame file');
            warning('No video name was in blink frame datafile');
        end
    else
        disp('Problem with blink frame file');
        error('MATLAB data file does not have any good frame info');
    end
    
    if (exist('videoname_check','var')) && isempty(videoname_check) ||...
            (strcmp(videoname_check,videofilename) == 0) %#ok<NODEF>
        disp('Problem with video name in blink frame MAT file')
        warning('Blink frame info was obtained from different video / Video info was in matlab data file is empty');
    end
else
    blinkframes = blinkframefilename(:);
end

if ~isnumeric(referenceimage_prior)
    disp('Reference image has to be a 2D double matrix');
    error('Please supply an appropriate reference image, exiting...');
end
if max(size(size(referenceimage_prior))) > 2
    disp('Reference image cannot have more than one image layer');
    warning('Using only first layer of the reference image');
    referenceimage_prior = referenceimage_prior(:,:,1);
end

if sum(rem(blinkframes,1)) > 0
    disp('Sorry the program prefers non-decimal blink frame indices');
    warning('Rounding off blink numbers');
    blinkframes = unique(round(blinkframes));
end
if min(blinkframes(:)) < 1
    disp('Blink frame numbers supplied has 0/Neg numbers');
    warning('Deleting the crazy numbers');
    blinkframes = blinkframes(blinkframes >= 1);
end
if max(blinkframes(:)) > numbervideoframes
    disp('Blink numbers supplied have indices greater than the number of frames in video');
    warning('Deleting the crazy numbers');
    blinkframes = blinkframes(blinkframes <= numbervideoframes);
end


cd(currentdirectory);

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
subpixelflag = correlationflags(1);
windowflag = correlationflags(2);
thumbnail_factor = 5;

referencesize_x = size(referenceimage_prior,2);
referencesize_y = size(referenceimage_prior,1);

frame_xcentre = floor(framewidth / 2) + 1;
reference_xcentre = floor(referencesize_x / 2) + 1;
xorigin_central = frame_xcentre;

xorigin_strips = frame_xcentre;
yincrement = floor((referencesize_y - frameheight) / 2);

if todothumbnails
    defaultsearchzone_hori_strips = round(2 * defaultsearchzone_hori_central / 3);
    defaultsearchzone_vert_strips = ceil(2 * defaultsearchzone_vert_central / 3);
else
    defaultsearchzone_hori_strips = round(searchparamstruct.horisearchzone);
    defaultsearchzone_vert_strips = round(searchparamstruct.vertsearchzone);
end

if (rem(defaultsearchzone_vert_central,2) == 0)
    defaultsearchzone_vert_central = defaultsearchzone_vert_central + 1;
end

if rem(defaultsearchzone_vert_strips,2) == 0
    defaultsearchzone_vert_strips = defaultsearchzone_vert_strips + 1;
end

numstrips = round(samplerate / videoframerate);
stripseparation = round(numlinesperfullframe / numstrips);
stripidx = zeros(numstrips,1);
stripidx(1) = round(stripseparation / 2); % The location of the first strip

if numstrips > 1
    for stripcounter = 2:numstrips
        stripidx(stripcounter) = stripidx(stripcounter - 1) + stripseparation;
    end
end

stripidx = stripidx(stripidx <= frameheight);
stripidx = stripidx(:);
numstrips = length(stripidx);

mingoodstripsperframes = minpercentofgoodstripsperframe * numstrips;
if mingoodstripsperframes < 2
    disp('Increasing minimum nuumber of good strips to 2');
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

framesforanalyses = setdiff([startframe:endframe],blinkframes);
framesforanalyses = framesforanalyses(:);
numframesforanalyses = length(framesforanalyses);
totalnumofsamples = numframesforanalyses * numstrips;

frameshifts_thumbnails = zeros(numframesforanalyses,2);
peakratios_thumbnails = ones(numframesforanalyses,1);
maxvals_thumbnails = zeros(numframesforanalyses,1);
secondpeaks_thumbnails = zeros(numframesforanalyses,1);
noises_thumbnails = zeros(numframesforanalyses,1);

frameshifts_strips_unwraped = zeros(numstrips,numframesforanalyses,2);
peakratios_strips_unwraped = ones(numstrips,numframesforanalyses,1);
maxvals_strips_unwraped = zeros(numstrips,numframesforanalyses,1);
secondpeaks_strips_unwraped = zeros(numstrips,numframesforanalyses,1);
noises_strips_unwraped = zeros(numstrips,numframesforanalyses,1);

stripsalreadyanalysed_unwraped = zeros(numstrips,numframesforanalyses);
outsidereferenceimage_unwraped = zeros(numstrips,numframesforanalyses,1);
badframesandstrips = zeros(numstrips * numframesforanalyses,5);
stripsearchparams = zeros(numstrips * numframesforanalyses,11);

referenceimage_thumbnail = makethumbnail(referenceimage_prior,thumbnail_factor,thumbnail_factor);

xsearchzone = defaultsearchzone_hori_central;
ysearchzone = defaultsearchzone_vert_central;

if any(verbosityarray)
    toplotfeedbackfigs = 1;
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
    
    if shiftverbose
        shiftstoplot = zeros(totalnumofsamples,2);
        shiftfig = figure;
        shiftaxis = axes;
        shiftplot_hori = plot(shiftstoplot(:,1),'Color',[0 0 1]);
        hold on
        shiftplot_vert = plot(shiftstoplot(:,2),'Color',[0 1 0]);
        hold off;
        title(shiftaxis,'Setting up');
        newposition = [figurewidth + 25,(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(shiftfig,'Position',newposition,'Toolbar','none','Name','Pixel Shifts');
        set(shiftaxis,'Xlim',[1 totalnumofsamples],...
            'YLim',round([(-0.25 * frameheight) (0.25 * frameheight)]));
        set(get(shiftaxis,'XLabel'),'String','Sample No.')
        set(get(shiftaxis,'YLabel'),'String','Shift (Pixels)');
    end
    
    if peakratioverbose
        peakratstoplot = ones(totalnumofsamples,1);
        threshtoplot = repmat(badstripthreshold,totalnumofsamples,1);
        peakratfig = figure;
        peakrataxis = axes;
        peakplot = plot(peakratstoplot,'Color',[0 0 1]);
        hold on
        threshplot = plot(threshtoplot,'Color',[0 0 0]);
        hold off
        newposition = [(2 * (figurewidth + 25)),(screensize(4) - figureheight + 1),...
            figurewidth, figureheight];
        set(peakratfig,'Position',newposition,'Toolbar','none','Name','Peak Ratios');
        set(peakrataxis,'Xlim',[1 totalnumofsamples],'YLim',[0 1]);
        set(get(peakrataxis,'XLabel'),'String','Sample No.')
        set(get(peakrataxis,'YLabel'),'String','Peak Ratio');
    end
    
    if shiftverbose || peakratioverbose
        stripindxaddition = [1:numstrips];
    end
else
    toplotfeedbackfigs = 0;
end

analysisprog = waitbar(0,'Thumbnail and Low Sample Rate Analyses');
oldwaitbarposition = get(analysisprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = round([newstartindex,(oldwaitbarposition(4) + 20),...
    oldwaitbarposition(3),oldwaitbarposition(4)]);
set(analysisprog,'Position',newwaitbarposition);


if todothumbnails
    for framecounter = 1:numframesforanalyses
        testframenumber = framesforanalyses(framecounter);
        videoinfo.CurrentTime = (testframenumber-1)*(1/videoinfo.FrameRate);
        testframe = double(readFrame(videoinfo));
        if istruecolor
            testframe = testframe(:,:,1);
        end
        testframe_thumbnail = makethumbnail(testframe,thumbnail_factor,thumbnail_factor);
        
        [correlation shifts peaks_noise] = ...
            corr2d(referenceimage_thumbnail,testframe_thumbnail,correlationflags(1),correlationflags(2));
        
        if peaks_noise(3) == 0
            peaks_noise(3) = 1;
        end
        
        pixelshifts = shifts * thumbnail_factor;
        peakratio = peaks_noise(2) / peaks_noise(1);
        
        if peakratio > badstripthreshold
            [correlation tempshifts temppeaks_noise] = ...
                corr2d(referenceimage_prior,testframe,correlationflags(1),correlationflags(2));
            if temppeaks_noise(3) == 0
                temppeaks_noise(3) = 1;
            end
            
            temppeakratio = temppeaks_noise(2) / temppeaks_noise(1);
            if temppeakratio <= badstripthreshold
                peakratio = temppeakratio;
                peaks_noise = temppeaks_noise;
                pixelshifts = shifts;
            end
        end
        
        if toplotfeedbackfigs
            titlestring = ['Frame No.: ',num2str(testframenumber)];
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
                title(titlestring)
            end
            
            if shiftverbose
                figure(shiftfig);
                shiftstoplot(indicesintomatrices,:) =...
                    repmat(pixelshifts,numstrips,1);
                set(shiftplot_hori,'YData',shiftstoplot(:,1));
                set(shiftplot_vert,'YData',shiftstoplot(:,2));
                title(titlestring)
            end
            
            if peakratioverbose
                figure(peakratfig);
                peakratstoplot(indicesintomatrices) =...
                    repmat(peakratio,numstrips,1);
                set(peakplot,'YData',peakratstoplot);
                title(titlestring)
            end
            drawnow
        end
        
        frameshifts_thumbnails(framecounter,:) = pixelshifts;
        peakratios_thumbnails(framecounter) = peakratio;
        maxvals_thumbnails(framecounter) = peaks_noise(1);
        secondpeaks_thumbnails(framecounter) = peaks_noise(2);
        noises_thumbnails(framecounter) = peaks_noise(3);
        
%         if peakratio <= badstripthreshold
%             xorigin = xorigin_central;
%             
%             xmovement = round(frameshifts_thumbnails(framecounter,1));
%             ymovement = round(frameshifts_thumbnails(framecounter,2));
%             
%             if framecounter > 1
%                 xvelocity = abs(frameshifts_thumbnails(framecounter,1) -...
%                     frameshifts_thumbnails(framecounter - 1,1));
%                 yvelocity = abs(frameshifts_thumbnails(framecounter,2) -...
%                     frameshifts_thumbnails(framecounter - 1,2));
%             else
%                 xvelocity = 0;
%                 yvelocity = 0;
%             end
%             
%             refxorigin = reference_xcentre - xmovement;
%             
%             if xvelocity > defaultsearchzone_hori_central
%                 xsearchzonetouse = min(round(2.5 * abs(xvelocity)),referencesize_x);
%             else
%                 xsearchzonetouse = xsearchzone;
%             end
%             
%             if yvelocity > defaultsearchzone_vert_central
%                 ysearchzonetouse = min(round(2.5 * abs(yvelocity)),referencesize_y);
%             else
%                 ysearchzonetouse = ysearchzone;
%             end
%             
%             for stripcounter = 1:numcentralstrips
%                 indexintostripmatrix = centralstripmatrixindex(stripcounter);
%                 indexintowrapedmatrix = ((framecounter - 1) * numstrips) + stripcounter;
%                 
%                 yorigin = stripidx(indexintostripmatrix);
%                 refyorigin = yorigin + yincrement - ymovement;
%                 
%                 [referencematrix isbadrefmatrix] = getsubmatrix(referenceimage_prior,...
%                     refxorigin,refyorigin,xsearchzonetouse,ysearchzonetouse,[1 referencesize_x],...
%                     [1 referencesize_y],0,0);
%                 if any(isbadrefmatrix(1:2))
%                     badframesandstrips(indexintowrapedmatrix,:) = [framesforanalyses(framecounter),...
%                         stripcounter,isbadrefmatrix];
%                 end
%                 
%                 teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
%                     stripheight,[1 framewidth], [1 frameheight],0,0);
%                 
%                 [correlation shifts peaks_noise] = ...
%                     findthestrip(referencematrix,teststrip,correlationflags(1),correlationflags(2));
%                 
%                 if peaks_noise(3) == 0
%                     peaks_noise(3) = 1;
%                 end
%                 
%                 peakratio = peaks_noise(2) / peaks_noise(1);
%                 
%                 if toplotfeedbackfigs
%                     titlestring = ['Frame No.: ',num2str(testframenumber),' Strip No.: ',num2str(indexintostripmatrix)];
%                     if shiftverbose || peakratioverbose
%                         idxintomatrices = ((framecounter - 1) * numstrips) + stripcounter;
%                     end
%                     
%                     if correlverbose
%                         figure(correlfig);
%                         set(correlmeshhandle,'Zdata',correlation);
%                         set(correlaxis,'Zlim',[-0.2 1]');
%                         title(titlestring)
%                     end
%                     
%                     if shiftverbose
%                         figure(shiftfig);
%                         shiftstoplot(idxintomatrices,:) = shifts;
%                         set(shiftplot_hori,'YData',shiftstoplot(:,1));
%                         set(shiftplot_vert,'YData',shiftstoplot(:,2));
%                         title(titlestring)
%                     end
%                     
%                     if peakratioverbose
%                         figure(peakratfig);
%                         peakratstoplot(idxintomatrices) = peakratio;
%                         set(peakplot,'YData',peakratstoplot);
%                         title(titlestring)
%                     end
%                     drawnow
%                 end
%                 
%                 stripsearchparams(indexintowrapedmatrix,:) = [framesforanalyses(framecounter),...
%                     indexintostripmatrix,xmovement,ymovement,shifts,...
%                     xsearchzone,ysearchzone,refxorigin,refyorigin,1];
%                 
%                 if peakratio <= badstripthreshold
%                     xpixelshift = xmovement + shifts(1);
%                     ypixelshift = ymovement + shifts(2);
%                     
%                     frameshifts_strips_unwraped(indexintostripmatrix,framecounter,:) =...
%                         cat(3,xpixelshift,ypixelshift);
%                     peakratios_strips_unwraped(indexintostripmatrix,framecounter) =...
%                         peakratio;
%                     maxvals_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(1);
%                     secondpeaks_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(2);
%                     noises_strips_unwraped(indexintostripmatrix,framecounter) = peaks_noise(3);
%                     stripsalreadyanalysed_unwraped(indexintostripmatrix,framecounter) = 1;
%                 end
%             end
%         end
        prog = framecounter / numframesforanalyses;
        waitbar(prog,analysisprog);
        
    end
else
    peakratios_thumbnails(:) = 0;
end

goodmatches_thumbnails = find(peakratios_thumbnails <= badstripthreshold);

xorigin = xorigin_strips;
xsearchzone = defaultsearchzone_hori_strips;
ysearchzone = defaultsearchzone_vert_strips;

absthumbnailvelocities = abs([[0,0];diff(frameshifts_thumbnails,[],1)]);

waitbar(0,analysisprog,'High Rate Strip Analysis');
for framecounter = 1:numframesforanalyses
    wasprevstripagoodmatch = 0;
    framenumber = framesforanalyses(framecounter);
    videoinfo.CurrentTime = (framenumber-1)*(1/videoinfo.FrameRate);
    testframe = double(readFrame(videoinfo));
    if istruecolor
        testframe = testframe(:,:,1);
    end
    
    if ~isempty(goodmatches_thumbnails == framecounter)
        currentframethumbnailvelocity = absthumbnailvelocities(framecounter,:);
    else
        currentframethumbnailvelocity = [defaultsearchzone_hori_strips,...
            defaultsearchzone_vert_strips] + 2;
    end
    if currentframethumbnailvelocity(1) > defaultsearchzone_hori_strips
        framexsearchzonetouse = min(round(2.5 * currentframethumbnailvelocity(1)),...
            framewidth);
    else
        framexsearchzonetouse = xsearchzone;
    end
    
    if currentframethumbnailvelocity(2) > defaultsearchzone_vert_strips
        frameysearchzonetouse = min(round(2.5 * currentframethumbnailvelocity(2)),...
            round(5 * referencesize_y / 6));
    else
        frameysearchzonetouse = ysearchzone;
    end
    
    for stripcounter = 1:numstrips
        indexintowrapedmatrix = ((framecounter - 1) * numstrips) + stripcounter;
        if stripsalreadyanalysed_unwraped(stripcounter,framecounter) == 1
            continue
        end
        
        yorigin = stripidx(stripcounter);
        
        if wasprevstripagoodmatch
            stripindexofprevgoodmatch = stripcounter - 1;
            frameindexofprevgoodmatch = framecounter;
            
            xmovement = round(frameshifts_strips_unwraped(stripindexofprevgoodmatch,...
                frameindexofprevgoodmatch,1));
            ymovement = round(frameshifts_strips_unwraped(stripindexofprevgoodmatch,...
                frameindexofprevgoodmatch,2));
            
            xsearchzonetouse = max(round(2 * framexsearchzonetouse / 3),round(framewidth / 3));
            ysearchzonetouse = max(round(2 * frameysearchzonetouse / 3),stripheight + 5);
        else
            if ~isempty(goodmatches_thumbnails == framecounter)
                xmovement = round(frameshifts_thumbnails(framecounter,1));
                ymovement = round(frameshifts_thumbnails(framecounter,2));
            else
                xmovement = 0;
                ymovement = 0;
            end
            xsearchzonetouse = framexsearchzonetouse;
            ysearchzonetouse = frameysearchzonetouse;
        end
        
        refxorigin = reference_xcentre - xmovement;
        refyorigin = yorigin + yincrement - ymovement;
        
        if (refyorigin <= 0) || (refyorigin >= referencesize_y)
            outsidereferenceimage_unwraped(stripcounter,framecounter) = 1;
        end
        
        [referencematrix isbadrefmatrix] = getsubmatrix(referenceimage_prior,refxorigin,refyorigin,...
            xsearchzonetouse,ysearchzonetouse,[1 referencesize_x], [1 referencesize_y],0,0);
        if any(isbadrefmatrix(1:2))
            badframesandstrips(indexintowrapedmatrix,:) = [framesforanalyses(framecounter),stripcounter,isbadrefmatrix];
        end
        
        teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
            stripheight,[1 framewidth], [1 frameheight],0,0);
        
        [correlation shifts peaks_noise] = ...
            findthestrip(referencematrix,teststrip,correlationflags(1),correlationflags(2));
        
        xpixelshift = xmovement + shifts(1);
        ypixelshift = ymovement + shifts(2);
        
        if peaks_noise(3) == 0
            peaks_noise(3) = 1;
        end
        peakratio = peaks_noise(2) / peaks_noise(1);
        
        if peakratio > badstripthreshold
            xsearchzonetouse = min((xsearchzonetouse * 3),framewidth);
            [referencematrix isbadrefmatrix] = getsubmatrix(referenceimage_prior,refxorigin,refyorigin,...
                xsearchzonetouse,ysearchzonetouse,[1 referencesize_x], [1 referencesize_y],0,0);
            if any(isbadrefmatrix(1:2))
                badframesandstrips(indexintowrapedmatrix,:) = [framesforanalyses(framecounter),stripcounter,isbadrefmatrix];
            end
            
            teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
                stripheight,[1 framewidth], [1 frameheight],0,0);
            
            [correlation shifts peaks_noise] = ...
                findthestrip(referencematrix,teststrip,correlationflags(1),correlationflags(2));
            
            xpixelshift = xmovement + shifts(1);
            ypixelshift = ymovement + shifts(2);
            
            if peaks_noise(3) == 0
                peaks_noise(3) = 1;
            end
            peakratio = peaks_noise(2) / peaks_noise(1);
        end
            
        
        if toplotfeedbackfigs
            titlestring = ['Frame No.: ',num2str(testframenumber)];
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
                title(titlestring)
            end
            
            if shiftverbose
                figure(shiftfig);
                shiftstoplot(indicesintomatrices,:) =...
                    repmat([xpixelshift ypixelshift],numstrips,1);
                set(shiftplot_hori,'YData',shiftstoplot(:,1));
                set(shiftplot_vert,'YData',shiftstoplot(:,2));
                title(titlestring)
            end
            
            if peakratioverbose
                figure(peakratfig);
                peakratstoplot(indicesintomatrices) =...
                    repmat(peakratio,numstrips,1);
                set(peakplot,'YData',peakratstoplot);
                title(titlestring)
            end
            drawnow
        end
        
        stripsearchparams(indexintowrapedmatrix,:) = [framesforanalyses(framecounter),...
            stripcounter,xmovement,ymovement,shifts,...
            xsearchzone,ysearchzone,refxorigin,refyorigin,2];
        
        if peakratio <= badstripthreshold
            frameshifts_strips_unwraped(stripcounter,framecounter,:) = cat(3,xpixelshift,ypixelshift);
            peakratios_strips_unwraped(stripcounter,framecounter) = peakratio;
            maxvals_strips_unwraped(stripcounter,framecounter) = peaks_noise(1);
            secondpeaks_strips_unwraped(stripcounter,framecounter) = peaks_noise(2);
            noises_strips_unwraped(stripcounter,framecounter) = peaks_noise(3);
            
            stripsalreadyanalysed_unwraped(stripcounter,framecounter) = 1;
            
            wasprevstripagoodmatch = 1;
        else
            wasprevstripagoodmatch = 0;
        end
    end
    prog = framecounter / numframesforanalyses;
    waitbar(prog,analysisprog);
end

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

badstripindices = find(stripsalreadyanalysed_unwraped == 0);

if totrycorrection
    if ~isempty(badstripindices)
        badframeindices = ceil(badstripindices / numstrips);
        
        uniquebadframeindices = unique(badframeindices);
        uniquebadframenumbers = framesforanalyses(uniquebadframeindices);
        numframeswithbadstrips = length(uniquebadframenumbers);
        
        xsearchzonetouse = round(min((5 *  framewidth / 3),referencesize_x));
        ysearchzone = round(5 * (defaultsearchzone_vert_strips / 3));
        
        waitbar(0,analysisprog,'Analysing Dropped Strips');
        for badframecounter = 1:numframeswithbadstrips
            currentbadframenumber = uniquebadframenumbers(badframecounter);
            currentbadframeindex = uniquebadframeindices(badframecounter);
            
            videoinfo.CurrentTime = (currentbadframenumber-1)*(1/videoinfo.FraemRate);
            testframe = double(readFrame(videoinfo));
            if istruecolor
                testframe = testframe(:,:,1);
            end
            
            badstripsinthisframe = find(stripsalreadyanalysed_unwraped(:,currentbadframeindex) == 0);
            numbadstripsinthisframe = length(badstripsinthisframe);
            
            for badstripcounter = 1:numbadstripsinthisframe
                currentstripindex = badstripsinthisframe(badstripcounter);
                
                indexintowrapedmatrix = ((currentbadframeindex - 1) * numstrips) + currentstripindex;
                
                if ((currentstripindex == 1) && (currentbadframeindex == 1))
                    continue
                end
                if ((currentstripindex == numstrips) && (currentbadframeindex == numframesforanalyses))
                    continue
                end
                
                yorigin = stripidx(currentstripindex);
                
                currentstripsubscript = ((currentbadframeindex - 1) * numstrips) + currentstripindex;
                tempstripalreadyanalysed = stripsalreadyanalysed_unwraped(:);
                goodstripindices = find(tempstripalreadyanalysed == 1);
                
                prevgoodstrip = goodstripindices(max(goodstripindices < currentstripsubscript));
                nextgoodstrip = goodstripindices(min(goodstripindices > currentstripsubscript));
                
                if isempty(prevgoodstrip) || isempty(nextgoodstrip)
                    continue
                end
                
                prevxmovement = frameshifts_strips_unwraped(prevgoodstrip);
                nextxmovement = frameshifts_strips_unwraped(nextgoodstrip);
                if isempty(prevxmovement) || isempty(nextxmovement)
                    continue
                end
                
                prevymovement = frameshifts_strips_unwraped(prevgoodstrip + totalnumofsamples);
                nextymovement = frameshifts_strips_unwraped(nextgoodstrip + totalnumofsamples);
                if isempty(prevxmovement) || isempty(nextxmovement)
                    continue
                end
                
                horidiffinmotion = abs(nextxmovement - prevxmovement);
                vertdiffinmotion = abs(nextymovement - prevymovement);
                if vertdiffinmotion < ysearchzone
                    ysearchzonetouse = ysearchzone;
                else
                    ysearchzonetouse = vertdiffinmotion + 45;
                end
                
                if rem(ysearchzonetouse,2) == 0
                    ysearchzonetouse = ysearchzonetouse - 1;
                end
                
                xmovements = round([prevxmovement;prevxmovement;nextxmovement;nextxmovement]);
                ymovements = round([prevymovement;nextymovement;prevymovement;nextymovement]);
                
                for origincounter = 1:4
                    xmovement = xmovements(origincounter);
                    ymovement = ymovements(origincounter);
                    
                    refxorigin = reference_xcentre - xmovement;
                    refyorigin =  yorigin + yincrement - ymovement;
                    
                    [referencematrix  isbadrefmatrix] = getsubmatrix(referenceimage_prior,refxorigin,refyorigin,xsearchzonetouse,...
                        ysearchzonetouse,[1 referencesize_x], [1 referencesize_y],0,0);
                    if any(isbadrefmatrix(1:2))
                        badframesandstrips(indexintowrapedmatrix,:) =...
                            [currentbadframe currentstripindex,isbadrefmatrix];
                    end
                    teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
                        stripheight,[1 framewidth], [1 frameheight],0,0);
                    
                    [correlation shifts peaks_noise] = ...
                        findthestrip(referencematrix,teststrip,correlationflags(1),correlationflags(2));
                    
                    if peaks_noise(3) == 0
                        peaks_noise(3) = 1;
                    end
                    peakratio = peaks_noise(2) / peaks_noise(1);
                    
                    xpixelshift = xmovement + shifts(1);
                    ypixelshift = ymovement + shifts(2);
                    
                    if (peakratio < badstripthreshold)
                        frameshifts_strips_unwraped(currentstripindex,currentbadframeindex,:) =...
                            cat(3,xpixelshift,ypixelshift);
                        peakratios_strips_unwraped(currentstripindex,currentbadframeindex) = peakratio;
                        maxvals_strips_unwraped(currentstripindex,currentbadframeindex) = peaks_noise(1);
                        secondpeaks_strips_unwraped(currentstripindex,currentbadframeindex) = peaks_noise(2);
                        noises_strips_unwraped(currentstripindex,currentbadframeindex) = peaks_noise(3);
                        
                        stripsalreadyanalysed_unwraped(currentstripindex,currentbadframeindex) = 1;
                        stripsearchparams(indexintowrapedmatrix,:) =...
                            [framesforanalyses(framecounter),currentstripindex,xmovement,ymovement,...
                            shifts,xsearchzone,ysearchzone,refxorigin,refyorigin,3];
                        if origincounter == 1
                            break;
                        end
                    end
                end
            end
            prog = badframecounter / numframeswithbadstrips;
            waitbar(prog,analysisprog);
        end
    end
end

numgoodstripsperframe = sum(stripsalreadyanalysed_unwraped,1);
frameindicestodrop = find(numgoodstripsperframe < mingoodstripsperframes);

if ~isempty(frameindicestodrop)
    frameindicestokeep = find(numgoodstripsperframe >= mingoodstripsperframes);
    droppedframes = framesforanalyses(frameindicestodrop);
    framesforanalyses = framesforanalyses(frameindicestokeep);
    framesforanalyses = framesforanalyses(:);
    numframesforanalyses = length(frameindicestokeep);
    
    frameshifts_strips_unwraped = frameshifts_strips_unwraped(:,frameindicestokeep,:);
    peakratios_strips_unwraped = peakratios_strips_unwraped(:,frameindicestokeep);
    maxvals_strips_unwraped = maxvals_strips_unwraped(:,frameindicestokeep);
    secondpeaks_strips_unwraped = secondpeaks_strips_unwraped(:,frameindicestokeep);
    noises_strips_unwraped = noises_strips_unwraped(:,frameindicestokeep);
    
    stripsalreadyanalysed_unwraped = stripsalreadyanalysed_unwraped(:,frameindicestokeep);
else
    droppedframes = [];
end

totalnumofsamples = numframesforanalyses * numstrips;
badmatchaddition = [-3:3];
badmatches_initial = find(stripsalreadyanalysed_unwraped(:) == 0);
badmatches_initial = badmatches_initial(:);
numbadmatches_initial = length(badmatches_initial);

badmatches = repmat(badmatches_initial,1,length(badmatchaddition)) +...
    repmat(badmatchaddition,numbadmatches_initial,1);
badmatches = unique(max(min(badmatches(:),totalnumofsamples),1));
if abs(totalnumofsamples - length(badmatches)) <= 2
    if abs(totalnumofsamples - length(numbadmatches_initial)) <= 2
        goodmatches = [1:totalnumofsamples]';
    else
        goodmatches = setdiff([1:totalnumofsamples]',tempunanalysedstrips);
    end
else
    goodmatches = setdiff([1:totalnumofsamples]',badmatches);
end

firstgoodsample = min(goodmatches(:));
firstframewithgoodsamples = ceil(firstgoodsample / numstrips);
if firstframewithgoodsamples > 1
    frameindicestokeep = [firstframewithgoodsamples:numframesforanalyses];
    droppedframes = sort([droppedframes;framesforanalyses(1)],'ascend');
    framesforanalyses = framesforanalyses(frameindicestokeep);
    framesforanalyses = framesforanalyses(:);
    numframesforanalyses = length(frameindicestokeep);
    
    frameshifts_strips_unwraped = frameshifts_strips_unwraped(:,frameindicestokeep,:);
    peakratios_strips_unwraped = peakratios_strips_unwraped(:,frameindicestokeep);
    maxvals_strips_unwraped = maxvals_strips_unwraped(:,frameindicestokeep);
    secondpeaks_strips_unwraped = secondpeaks_strips_unwraped(:,frameindicestokeep);
    noises_strips_unwraped = noises_strips_unwraped(:,frameindicestokeep);
    
    stripsalreadyanalysed_unwraped = stripsalreadyanalysed_unwraped(:,frameindicestokeep);
end

lastgoodsample = max(goodmatches(:));
lastframewithgoodsamples = ceil(lastgoodsample / numstrips);
if lastframewithgoodsamples < numframesforanalyses
    frameindicestokeep = [1:lastframewithgoodsamples];
    droppedframes = sort([droppedframes;framesforanalyses(end)],'ascend');
    framesforanalyses = framesforanalyses(frameindicestokeep);
    framesforanalyses = framesforanalyses(:);
    numframesforanalyses = length(frameindicestokeep);
    
    frameshifts_strips_unwraped = frameshifts_strips_unwraped(:,frameindicestokeep,:);
    peakratios_strips_unwraped = peakratios_strips_unwraped(:,frameindicestokeep);
    maxvals_strips_unwraped = maxvals_strips_unwraped(:,frameindicestokeep);
    secondpeaks_strips_unwraped = secondpeaks_strips_unwraped(:,frameindicestokeep);
    noises_strips_unwraped = noises_strips_unwraped(:,frameindicestokeep);
    
    stripsalreadyanalysed_unwraped = stripsalreadyanalysed_unwraped(:,frameindicestokeep);
end


totalnumofsamples = numframesforanalyses * numstrips;
badmatchaddition = [-3:3];
badmatches_initial = find(stripsalreadyanalysed_unwraped(:) == 0);
badmatches_initial = badmatches_initial(:);
numbadmatches_initial = length(badmatches_initial);

badmatches = repmat(badmatches_initial,1,length(badmatchaddition)) +...
    repmat(badmatchaddition,numbadmatches_initial,1);
badmatches = unique(max(min(badmatches(:),totalnumofsamples),1));
if abs(totalnumofsamples - length(badmatches)) <= 2
    if abs(totalnumofsamples - length(numbadmatches_initial)) <= 2
        goodmatches = [1:totalnumofsamples]';
    else
        goodmatches = setdiff([1:totalnumofsamples]',tempunanalysedstrips);
    end
else
    goodmatches = setdiff([1:totalnumofsamples]',badmatches);
end

maxvals_strips = maxvals_strips_unwraped(:);
secondpeaks_strips = secondpeaks_strips_unwraped(:);
noises_strips = noises_strips_unwraped(:);
peakratios_strips = peakratios_strips_unwraped(:);

frameshifts_strips = zeros(length(maxvals_strips),2);
frameshifts_strips_spline = zeros(length(maxvals_strips),2);

interp_xaxis = [0:length(maxvals_strips) - 1];
sample_xaxis = interp_xaxis(goodmatches);

for directioncounter = 1:2
    tempshifts = frameshifts_strips_unwraped(:,:,directioncounter);
    tempshifts = tempshifts(:);
    
    frameshifts_strips(:,directioncounter) = tempshifts;
    interp_yaxis = interp1(sample_xaxis,tempshifts(goodmatches),interp_xaxis,'linear','extrap');
    frameshifts_strips_spline(:,directioncounter) = interp_yaxis;
end

if max(badmatches(:)) == size(peakratios_strips,1)
    lastgoodsample = max(goodmatches(:));
    for directioncounter = 1:2
        frameshifts_strips(lastgoodsample + 1:end,directioncounter) =...
            frameshifts_strips(lastgoodsample,directioncounter);
        
        frameshifts_strips_spline(lastgoodsample + 1:end,directioncounter) =...
            frameshifts_strips_spline(lastgoodsample,directioncounter);
    end
end
if min(badmatches(:)) == 1
    firstgoodsample = min(goodmatches(:));
    for directioncounter = 1:2
        frameshifts_strips(1:firstgoodsample - 1,directioncounter) =...
            frameshifts_strips(firstgoodsample,directioncounter);
        
        frameshifts_strips_spline(1:firstgoodsample - 1,directioncounter) =...
            frameshifts_strips_spline(firstgoodsample,directioncounter);
    end
end

close(analysisprog);

[referencematrix,referencematrix_full] = ...
    makestabilizedframe(videoname,framesforanalyses,frameshifts_strips_spline,peakratios_strips,...
    stripidx,badstripthreshold,numlinesperfullframe,3,0,0);

referenceimage = referencematrix(:,:,2);

timeaxis = [0:(numlinesperfullframe * numbervideoframes) - 1];
timeaxis = reshape(timeaxis,numlinesperfullframe,numbervideoframes);
timeaxis = timeaxis(stripidx,framesforanalyses);
timeaxis = timeaxis(:);
timeaxis_secs = timeaxis / (numlinesperfullframe * videoframerate);

outsidereferenceimage = outsidereferenceimage_unwraped(:);

randstring = num2str(min(ceil(rand(1) * 10000),9999));
sampleratestring = num2str(samplerate);
filestring = strcat('_',sampleratestring,'_hz','_',randstring,'.mat');
datafilename = strcat(videoname(1:end - 4),filestring);

videoname_check = videofilename;
analysedframes = framesforanalyses;

save(datafilename,'referenceimage','referencematrix','referencematrix_full',...
    'referenceimage_prior','frameshifts_strips','frameshifts_strips_spline',...
    'maxvals_strips','secondpeaks_strips','noises_strips','peakratios_strips',...
    'frameshifts_thumbnails','maxvals_thumbnails','secondpeaks_thumbnails',...
    'noises_thumbnails','samplerate','defaultsearchzone_vert_central',...
    'defaultsearchzone_hori_central','stripheight','startframe','endframe',...
    'badstripthreshold','minpercentofgoodstripsperframe','numlinesperfullframe',...
    'subpixelflag','todothumbnails','blinkframes','videoname_check','analysedframes',...
    'stripidx','droppedframes','outsidereferenceimage','stripsearchparams',...
    'badframesandstrips','videoframerate','framewidth','frameheight','numbervideoframes',...
    'timeaxis','timeaxis_secs','windowflag');

if referenceverbose
    mymap = repmat([0:255]' / 256,1,3);
    titlestring = ['Stabilized Frame from video ',videofilename];
    figure
    set(gcf,'Name','Stabilized Frame');
    image(referenceimage);
    colormap(gray(256));
    axis off;
    truesize;
    title(titlestring,'Interpreter','none');
end