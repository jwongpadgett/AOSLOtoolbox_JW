function [datafilename,referenceimage] = makereference_segmented(videoname,...
    badframefilename,searchparamstruct,verbose)
% makereference_segmented.m. This program is designed to create a reference
% image. The program does this by conducting a "strip"
% cross-correlation using a image that has already been constructed as a
% reference image.
%
%Usage: [datafilename,referenceimage] = makereference_segmented(videoname,refframefilename,...
%            badframefilename,referencevarname,searchparamstruct,verbosityarray)
% videoname                 - A string that contains the full path to video/3D
%                             matrix consisting of multiple 2D images. The
%                             program will query the user to provide a video
%                             path and name if this variable is not
%                             provided.
% refframefilename          - The string that points to matfile name that
%                             contains the reference image.
% badframefilename          - A string that contains the full path to a
%                             mat file that contains bad frame infomation
%                             in a format that is the same as created by
%                             getbadframes.m/a one column array containing
%                             the "good" frames all of which that can be
%                             used to create a referenceimage.
% referencevarname          - The name of the variable within the reference
%                             matfile that is the reference image.
% searchparamstruct         - A structure data type that has the following
%                             fields:
%                                   samplerate
%                                   vertsearchzone
%                                   stripheight
%                                   badstripthreshold
%                                   frameincrement
%                                   minimumframespersegment
%                                   minpercentofgoodstripsperframe
%                                   numlinesperfullframe
%                             samplerate is the samplerate of the extracted
%                             eye motion trace in hertz. vertsearchzone is
%                             the number of pixel lines that are searched
%                             for a match for individual strips.
%                             stripheight is the number of pixel lines are
%                             constitute a single strip. frameincrement is
%                             the number of frames within the "good"
%                             frames that are skipped over while choosing
%                             which frames are used for the reference
%                             frame.minpercentofgoodstripsperframe is the
%                             decimal percentage that denotes the minimum
%                             percent of good strips/samples matches within
%                             a frame for the frame to be used in the
%                             reference frame, while numlinesperfullframe
%                             is the number of pixel lines that constitute
%                             a full frame including the scan mirror
%                             flyback.
% verbosityarray            - A 4 element array that determines the type of
%                             feedback that is given to the user. If the first
%                             element is set to 1, then the program plots
%                             the cross-correlation function everytime the
%                             program conducts a cross-correlation. If the
%                             second and third element are set to 1 then
%                             then program plots the extracted eye motion
%                             trace and the prak ratios respectively. if
%                             the  third element is set to 1 then the program
%                             draws the image of the reference image once
%                             the prgram is done with its analyses.
%
% datafilename              - The name of the matfile into which the
%                             reference image and related data are written
%                             into.
% referenceimage            - The reference image created after the
%                             analyses. The reference image is a cropped
%                             image that has the maximum image data. Pixels
%                             that have no image data is filled with random
%                             image data taken from image data.
%
%
% Program Creator: Girish Kumar

rand('state',sum(100 * clock));
if ispc
    pathslash = '\';
else
    pathslash = '/';
end
currentdirectory = pwd;

if (nargin < 1) || isempty(videoname)
    [videofilename videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
    if videofilename == 0
        disp('No video to analyse,stopping program');
        error('Type ''help makereference_segmented'' for usage');
    else
        videoname = strcat(videopath,videofilename);
        cd(videopath);
    end
else
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
end

if (nargin < 2) || isempty(badframefilename)
    loadgoodframedata = 1;
    [fname pname] = uigetfile('*.mat','Please enter the matfile with the bad frame data');
    if fname == 0
        cd(currentdirectory);
        disp('Need reference data,stopping program');
        error('Type ''help makereference_segmented'' for usage');
    else
        badframefilename = strcat(pname,fname);
    end
end

if ischar(badframefilename)
    loadgoodframedata = 1;
    if ~exist(badframefilename,'file')
        warning('Second input string does not point to a valid mat file');
        [fname pname] = uigetfile('*.mat','Please enter the matfile with the bad frame data');
        if fname == 0
            cd(currentdirectory);
            disp('Need reference data,stopping program');
            error('Type ''help makereference_coarseframerate'' for usage');
        else
            badframefilename = strcat(pname,fname);
        end
    end
else
    loadgoodframedata = 0;
end

if nargin < 3 || isempty(searchparamstruct) || ~isstruct(searchparamstruct)
    prompt = {'Sample Rate (Hz)','Vertical Search Zone (Pixels)',...
        'Strip Height (Pixels)','Bad Strip Correlation Threshold','Position Threshold',...
        'Minimum No. of Frame Per Segment','Number of Lines per Full Video Frame'};
    name = 'Input for Reference Program';
    numlines = 1;
    defaultanswer = {'150','75','11','0.55','0.05','5','512'};
    
    inputanswer = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(inputanswer)
        warning('You have pressed cancel rather than input any values, using default values in fields in the searchparamstruct structure');
        inputanswer = {'150','75','11','0.55','0.05','5','512'};
    end
    
    togetsamplerate = 0;
    togetvertsearchzone = 0;
    togetstripheight = 0;
    togetbadstripthreshold = 0;
    togetsegmentdropthreshold = 0;
    togetminimumframespersegment = 0;
    togetnumlinesperfullframe = 0;
    
    searchparamstruct = struct('samplerate',str2double(inputanswer{1}),...
        'vertsearchzone',str2double(inputanswer{2}),'stripheight',...
        str2double(inputanswer{3}),'badstripthreshold',str2double(inputanswer{4}),...
        'segmentdropthreshold',str2double(inputanswer{5}),'minimumframespersegment',...
        str2double(inputanswer{6}),'numlinesperfullframe',str2double(inputanswer{7}));
else
    namesofinputfields = fieldnames(searchparamstruct);
    if sum(strcmpi(namesofinputfields,'samplerate'))
        togetsamplerate = 0;
    else
        togetsamplerate = 1;
    end
    if sum(strcmpi(namesofinputfields,'vertsearchzone'))
        togetvertsearchzone = 0;
    else
        togetvertsearchzone = 1;
    end
    if sum(strcmpi(namesofinputfields,'stripheight'))
        togetstripheight = 0;
    else
        togetstripheight = 1;
    end
    if sum(strcmpi(namesofinputfields,'badstripthreshold'))
        togetbadstripthreshold = 0;
    else
        togetbadstripthreshold = 1;
    end
    if sum(strcmpi(namesofinputfields,'segmentdropthreshold'))
        togetsegmentdropthreshold = 0;
    else
        togetsegmentdropthreshold = 1;
    end
    if sum(strcmp(namesofinputfields,'minimumframespersegment'))
        togetminimumframespersegment = 0;
    else
        togetminimumframespersegment = 1;
    end
    if sum(strcmp(namesofinputfields,'numlinesperfullframe'))
        togetnumlinesperfullframe = 0;
    else
        togetnumlinesperfullframe = 1;
    end
end

if any([togetsamplerate;togetvertsearchzone;togetstripheight;togetbadstripthreshold;...
        togetsegmentdropthreshold;togetminimumframespersegment;togetnumlinesperfullframe])
    prompt = {};
    defaultanswer = {};
    if togetsamplerate
        prompt{end + 1} = 'Sample Rate (Hz)';
        defaultanswer{end + 1} = '180';
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
        defaultanswer{end + 1} = '0.55';
    end
    if togetsegmentdropthreshold
        prompt{end + 1} = 'Position Threshold';
        defaultanswer{end + 1} = '0.05';
    end
    if togetminimumframespersegment
        prompt{end + 1} = 'Minimum No. of Frames Per Segment';
        defaultanswer{end + 1} = '5';
    end
    if togetnumlinesperfullframe
        prompt{end + 1} = 'Number of Lines per Full Video Frame';
        defaultanswer{end + 1} = '512';
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
    if togetstripheight
        searchparamstruct.stripheight = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetbadstripthreshold
        searchparamstruct.badstripthreshold = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetsegmentdropthreshold
        searchparamstruct.segmentdropthreshold = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetminimumframespersegment
        searchparamstruct.minimumframespersegment = str2double(inputanswer{fieldcounter});
        fieldcounter = fieldcounter + 1;
    end
    if togetnumlinesperfullframe
        searchparamstruct.numlinesperfullframe = str2double(inputanswer{fieldcounter});
    end
end

if (nargin < 4) || isempty(verbose)
    verbose = 0;
end

fileinfo = VideoReader(videoname); % Get important info of the avifile
videoframerate = round(fileinfo.FrameRate); % The videoframerate of the video
framewidth = fileinfo.Width; % The width of the video (in pixels)
frameheight = fileinfo.Height; % The height of the video (in pixels)



samplerate = searchparamstruct.samplerate;
defaultsearchzone_vert = searchparamstruct.vertsearchzone;
defaultsearchzone_hori = round(4 * framewidth / 5);
stripheight = searchparamstruct.stripheight;
badstripthreshold = searchparamstruct.badstripthreshold;
segmentdropthreshold = searchparamstruct.segmentdropthreshold;
minimumframespersegment = searchparamstruct.minimumframespersegment;
numlinesperfullframe = searchparamstruct.numlinesperfullframe;

thresholdstouse = [framewidth,frameheight] * segmentdropthreshold;

if loadgoodframedata
    load(badframefilename,'videoname_check','goodframesegmentinfo')
    if exist('videoname_check','var')
        if isempty(videoname_check) || strcmp(videoname_check,videofilename) == 0 %#ok<NODEF>
            warning('Problem with bad frame mat file, bad frame info was obtained from different video / No video info was in matlab data file');
        end
    else
        warning('Problem with bad frame file, no video name was in bad frame datafile');
    end
    
    if exist('goodframesegmentinfo','var')
        if isempty(goodframesegmentinfo) %#ok<NODEF>
            disp('Problem with bad frame mat file');
            error('Segment info not present in the MATLAB data file');
        end
    else
        error('Problem with bad frame mat file, segment info not present in the MATLAB data file');
    end
else
    goodframesegmentinfo =  badframefilename;
end

if samplerate < (3 * videoframerate)
    newsampleratestring = [numstr(3 * videoframerate),' Hz'];
    warnstring = ['Too Low a sample sample, increasing to ',newsampleratestring];
    warning(warnstring);
    samplerate = round(3 * videoframerate);
end
if samplerate > (videoframerate * numlinesperfullframe)
    newsampleratestring = [numstr(videoframerate * numlinesperfullframe),' Hz'];
    warnstring = ['Too High a sample rate, decreasing to ',newsampleratestring];
    warning(warnstring);
    samplerate = round(videoframerate * numlinesperfullframe);
end
if rem(samplerate,videoframerate) ~= 0
    newsampleratestring = [numstr(floor(samplerate / videoframerate) * videoframerate),' Hz'];
    warnstring = ['Sample rate should be multiple of the video frame rate, reducing to ',newsampleratestring];
    warning(warnstring);
    samplerate = floor(samplerate / videoframerate) * videoframerate;
end

if defaultsearchzone_vert > frameheight
    warning('Default Vertical Search Zone is too high, reducing to 10 pixels less than frame height');
    defaultsearchzone_vert = frameheight - 10;
end
if defaultsearchzone_vert < 10
    warning('Default Vertical Search Zone is too low, increasing to 10 pixels');
    defaultsearchzone_vert_strips = 10;
end

if rem(stripheight,1) ~= 0
    warning('Strip height cannot be a decimal, round down...');
    stripheight = floor(stripheight);
end
if stripheight >= defaultsearchzone_vert
    warning('Strip Height cannot be larger than vertical search zone, reducing strip height to one less than vertical search zone')
    stripheight = max(defaultsearchzone_vert_strips - 1,1);
end
if stripheight < 1
    warning('Strip should have atleast one line, increasing strip height to 1');
    stripheight = 1;
end

if badstripthreshold >= 1
    warning('Bad Strip Threshold is too high, reducing to 0.99')
    badstripthreshold = 0.99;
end
if badstripthreshold < 0.01
    warning('Bad Strip Threshold is too low, increasing to 0.01')
    badstripthreshold = 0.01;
end

if minimumframespersegment < 5
    warning('Minimum frames per segment is too low, increasing to 5');
    minimumframespersegment = 5;
end
if minimumframespersegment > 10
    warning('Minimum frames per segment is too high, decreasing to 15');
    minimumframespersegment = 15;
end


cd(currentdirectory);

pixelsize_deg = [(2 / 480), (2 /512)];
maxvelthreshold = 8.5;
maxexcursionthreshold = 0.1;
thumbnail_factor = 10;
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

segmentstartframes = [];
segmentendframes = [];
framesforreference = [];
referencetouse = [];
segmentnumbers = [];

numframesingoodframesegments = goodframesegmentinfo(:,3);
goodsegments = find(numframesingoodframesegments >= minimumframespersegment);
currentsegmentnumber = 1;

for segmentcounter = 1:length(goodsegments)
    numframesincurrentsegment = goodframesegmentinfo(goodsegments(segmentcounter),3);
    firstframeinsegment = goodframesegmentinfo(goodsegments(segmentcounter),1);
    lastframeinsegment = goodframesegmentinfo(goodsegments(segmentcounter),2);
    
    switch numframesincurrentsegment <= (2 * minimumframespersegment);
        case 1
            framesincurrentsegment = [firstframeinsegment:lastframeinsegment]';
            numframesincurrentsegment = length(framesincurrentsegment);
            
            framesforreference = [framesforreference;framesincurrentsegment];
            
            segmentstartframes = [segmentstartframes;firstframeinsegment];
            segmentendframes = [segmentendframes;lastframeinsegment];
            
            referencetouse = [referencetouse;repmat(firstframeinsegment,numframesincurrentsegment,1)];
            
            segmentnumbers = [segmentnumbers;zeros(numframesincurrentsegment,1) + currentsegmentnumber];
            currentsegmentnumber = currentsegmentnumber + 1;
        case 0
            framesininitalpartofcurrentsegment = [firstframeinsegment:...
                firstframeinsegment + minimumframespersegment - 1]';
            framesinfinalpartofcurrentsegment = [lastframeinsegment - minimumframespersegment + 1:...
                lastframeinsegment]';
            
            numframesincurrentsegment_initialpart = length(framesininitalpartofcurrentsegment);
            numframesincurrentsegment_finalpart = length(framesininitalpartofcurrentsegment);
            
            framesforreference = [framesforreference;framesininitalpartofcurrentsegment;framesinfinalpartofcurrentsegment];
            
            segmentstartframes = [segmentstartframes;firstframeinsegment];
            segmentstartframes = [segmentstartframes;lastframeinsegment - minimumframespersegment + 1];
            
            segmentendframes = [segmentendframes;firstframeinsegment + minimumframespersegment - 1];
            segmentendframes = [segmentendframes;lastframeinsegment];
            
            referencetouse = [referencetouse;repmat(firstframeinsegment,numframesincurrentsegment_initialpart,1);...
                repmat(lastframeinsegment - minimumframespersegment + 1,numframesincurrentsegment_finalpart,1)];
            
            segmentnumbers = [segmentnumbers;zeros(numframesincurrentsegment_initialpart,1) + currentsegmentnumber];
            currentsegmentnumber = currentsegmentnumber + 1;
            
            segmentnumbers = [segmentnumbers;zeros(numframesincurrentsegment_finalpart,1) + currentsegmentnumber];
            currentsegmentnumber = currentsegmentnumber + 1;
    end
end

numframesforreference = length(framesforreference);
numsegments = max(segmentnumbers);

segmentframeshifts_thumbnails = zeros(numframesforreference,2);
segmentmaxvals_thumbnails = ones(numframesforreference,1);
segmentsecondpeaks_thumbnails = ones(numframesforreference,1);
segmentnoises_thumbnails = ones(numframesforreference,1);

indicestodrop = [];
prevrefframenumber = 0;

analysisprog = waitbar(0,'Thumbnail Analyses');
oldwaitbarposition = get(analysisprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,(oldwaitbarposition(4) + 20),...
    oldwaitbarposition(3),oldwaitbarposition(4)];
set(analysisprog,'Position',newwaitbarposition);

for framecounter = 1:numframesforreference
    testframenumber = framesforreference(framecounter);
    refframenumber = referencetouse(framecounter);
    
    if testframenumber == refframenumber
        continue;
    end
    
    fileinfo.CurrentTime = (testframenumber-1)*(1/fileinfo.FrameRate);
    testframe = double(frame2im(readFrame(fileinfo)));
    if prevrefframenumber ~= refframenumber
        fileinfo.CurrentTime = (refframenumber-1)*(1/fileinfo.FrameRate);
        refframe = double(frame2im(readFrame(fileinfo)));
        prevrefframenumber = refframenumber;
    end
    
    testframe_thumbnail = makethumbnail(testframe,thumbnail_factor,thumbnail_factor);
    refframe_thumbnail = makethumbnail(refframe,thumbnail_factor,thumbnail_factor);
    
    [correlation shifts peaks_noise] = ...
        corr2d(refframe_thumbnail,testframe_thumbnail,1);
    
    peakratio = peaks_noise(2) / peaks_noise(1);
    xpixelshift = shifts(1) * thumbnail_factor;
    ypixelshift = shifts(2) * thumbnail_factor;
    
    if peakratio > badstripthreshold
        [correlation tempshifts temppeaks_noise] = ...
            corr2d(refframe,testframe,1);
        
        temppeakratio = temppeaks_noise(2) / temppeaks_noise(1);
        if temppeakratio <= badstripthreshold
            peaks_noise = temppeaks_noise;
            xpixelshift = tempshifts(1);
            ypixelshift = tempshifts(2);
            
            peakratio = peaks_noise(2) / peaks_noise(1);
        else
            indicestodrop = [indicestodrop;framecounter];
        end
    end
    
    segmentframeshifts_thumbnails(framecounter,:) = [xpixelshift ypixelshift];
    segmentmaxvals_thumbnails(framecounter) = peaks_noise(1);
    segmentsecondpeaks_thumbnails(framecounter) = peaks_noise(2);
    segmentnoises_thumbnails(framecounter) = peaks_noise(3);
    
    prog = framecounter / numframesforreference;
    waitbar(prog,analysisprog);
end

framesforreference_initial = framesforreference;
if ~isempty(indicestodrop)
    indicestokeep = setdiff([1:numframesforreference]',indicestodrop);
    
    framesforreference = framesforreference(indicestokeep);
    referencetouse = referencetouse(indicestokeep);
    segmentnumbers = segmentnumbers(indicestokeep);
    
    segmentframeshifts_thumbnails = segmentframeshifts_thumbnails(indicestokeep,:);
    segmentmaxvals_thumbnails = segmentmaxvals_thumbnails(indicestokeep);
    segmentsecondpeaks_thumbnails = segmentsecondpeaks_thumbnails(indicestokeep);
    segmentnoises_thumbnails = segmentnoises_thumbnails(indicestokeep);
end

numframesforreference = length(framesforreference);
segmentframeshifts_strips_unwraped = zeros(numstrips,numframesforreference,2);
segmentmaxvals_strips_unwraped = ones(numstrips,numframesforreference);
segmentsecondpeaks_strips_unwraped = ones(numstrips,numframesforreference);
segmentnoises_strips_unwraped = ones(numstrips,numframesforreference);

frame_xcentre = floor(framewidth / 2) + 1;

xorigin = frame_xcentre;

xsearchzone = defaultsearchzone_hori;
ysearchzone = defaultsearchzone_vert;

absthumbnailvelocities = abs([0,0;diff(segmentframeshifts_thumbnails,[],1)]);

prevrefframenumber = 0;
wasprevstripagoodmatch = 0;

waitbar(0,analysisprog,'Higher Rate Analysis');
for framecounter = 1:numframesforreference
    currentframethumbnailvelocity = absthumbnailvelocities(framecounter,:);
    
    testframenumber = framesforreference(framecounter);
    refframenumber = referencetouse(framecounter);
    
    if testframenumber == refframenumber
        wasprevstripagoodmatch = 0;
        continue;
    end
        
    fileinfo.CurrentTime = (testframenumber-1)*(1/fileinfo.FrameRate);
    testframe = double(frame2im(readFrame(fileinfo)));
    if prevrefframenumber ~= refframenumber
        fileinfo.CurrentTime = (refframenumber-1)*(1/fileinfo.FrameRate);
        refframe = double(frame2im(readFrame(fileinfo)));
        prevrefframenumber = refframenumber;
    end
    
    if currentframethumbnailvelocity(1) > defaultsearchzone_hori
        framexsearchzonetouse = min(round(2.5 * currentframethumbnailvelocity(1)),...
            framewidth);
    else
        framexsearchzonetouse = xsearchzone;
    end
    
    if currentframethumbnailvelocity(2) > defaultsearchzone_vert
        frameysearchzonetouse = min(round(2.5 * currentframethumbnailvelocity(2)),...
            round(5 * frameheight / 6));
    else
        frameysearchzonetouse = ysearchzone;
    end
    
    for stripcounter = 1:numstrips
        yorigin = stripidx(stripcounter);
        
        if wasprevstripagoodmatch
            if stripcounter == 1
                stripindexofprevgoodmatch = numstrips;
                frameindexofprevgoodmatch = framecounter - 1;
            else
                stripindexofprevgoodmatch = stripcounter - 1;
                frameindexofprevgoodmatch = framecounter;
            end
            
            xmovement = round(segmentframeshifts_strips_unwraped(stripindexofprevgoodmatch,...
                frameindexofprevgoodmatch,1));
            ymovement = round(segmentframeshifts_strips_unwraped(stripindexofprevgoodmatch,...
                frameindexofprevgoodmatch,2));
            
            xsearchzonetouse = max(round(2 * framexsearchzonetouse / 3),round(framewidth / 2));
            ysearchzonetouse = max(round(2 * frameysearchzonetouse / 3),stripheight + 5);
        else
            xmovement = round(segmentframeshifts_thumbnails(framecounter,1));
            ymovement = round(segmentframeshifts_thumbnails(framecounter,2));
            
            xsearchzonetouse = framexsearchzonetouse;
            ysearchzonetouse = frameysearchzonetouse;
        end
        
        xsearchzonetouse = framewidth;
        
        refxorigin = frame_xcentre - xmovement;
        refyorigin = yorigin - ymovement;
        
        referencematrix = getsubmatrix(refframe,refxorigin,refyorigin,xsearchzonetouse,...
            ysearchzonetouse,[1 framewidth], [1 frameheight],0,0);
        teststrip = getsubmatrix(testframe,xorigin,yorigin,xsearchzonetouse,...
            stripheight,[1 framewidth], [1 frameheight],0,1);
        
        [correlation shifts peaks_noise] =....
            findthestrip(referencematrix,teststrip,1);
        
        if (peaks_noise(2) / peaks_noise(1)) <= badstripthreshold
            wasprevstripagoodmatch = 1;
        else
            wasprevstripagoodmatch = 0;
        end
        
        xpixelshift = xmovement + shifts(1);
        ypixelshift = ymovement + shifts(2);
        
        segmentframeshifts_strips_unwraped(stripcounter,framecounter,:) = cat(3,xpixelshift, ypixelshift);
        segmentmaxvals_strips_unwraped(stripcounter,framecounter) = peaks_noise(1);
        segmentsecondpeaks_strips_unwraped(stripcounter,framecounter) = peaks_noise(2);
        segmentnoises_strips_unwraped(stripcounter,framecounter) = peaks_noise(3);
    end
    prog = framecounter / numframesforreference;
    waitbar(prog,analysisprog);
end

segmentframeshifts_strips_unwraped_withave = segmentframeshifts_strips_unwraped;
segmentmaxvels = zeros(numsegments,1);
segmentmaxexcursions = zeros(numsegments,1);
segmentreferenceframes = cell(numsegments,1);

segmentsdroppedduetohighvel = [];
waitbar(0,analysisprog,'Registering Individual Segments');
for segmentcounter = 1:numsegments
    indicesofsegmentdata = find(segmentnumbers == segmentcounter);
    numframesinsegment = length(indicesofsegmentdata);
    
    currentsegmentframenumbers = framesforreference(indicesofsegmentdata);
    currentsegmentframeshifts_withave = segmentframeshifts_strips_unwraped(:,indicesofsegmentdata,:);
    
    peakratios_unwraped = segmentsecondpeaks_strips_unwraped(:,indicesofsegmentdata) ./...
        segmentmaxvals_strips_unwraped(:,indicesofsegmentdata);
    peakratios = peakratios_unwraped(:);
    peakratios(1:numstrips) = 0;
    
    badstrips_initial = find(peakratios > badstripthreshold);
    numinitialbadstrips = length(badstrips_initial);
    badstrips = sort(unique(repmat([-2:2],numinitialbadstrips,1) +...
        repmat(badstrips_initial(:),1,5)),'ascend');
    badstrips = max(min(badstrips(:),length(peakratios)),1);
    goodstrips = setdiff([1:length(peakratios)],badstrips);
    
    frameshiftstouse_unwraped = zeros(size(currentsegmentframeshifts_withave));
    frameshiftstouse = zeros(length(peakratios),2);
    
    if length(goodstrips) < length(peakratios)
        interp_xaxis = [0:length(peakratios) - 1];
        sample_xaxis = interp_xaxis(goodstrips);
        
        for directioncounter = 1:2
            sample_yaxis = currentsegmentframeshifts_withave(:,:,directioncounter);
            sample_yaxis = sample_yaxis(:);
            
            interp_yaxis = interp1(sample_xaxis,sample_yaxis(goodstrips),...
                interp_xaxis,'linear','extrap');
            frameshiftstouse_unwraped(:,:,directioncounter) = reshape(interp_yaxis,numstrips,numframesinsegment);
            
            if max(badstrips) == length(peakratios)
                lastgoodsample = max(goodstrips(:));
                if directioncounter == 1
                    indicestochange = [lastgoodsample + 1:length(peakratios)];
                    idxtotakevalfrom = lastgoodsample;
                else
                    indicestochange = [length(peakratios) + lastgoodsample:...
                        numel(currentsegmentframeshifts_withave)];
                    idxtotakevalfrom = length(peakratios) + lastgoodsample - 1;
                end
                frameshiftstouse_unwraped(indicestochange) =...
                    frameshiftstouse_unwraped(idxtotakevalfrom);
            end
        end
    else
        frameshiftstouse_unwraped = currentsegmentframeshifts_withave;
    end
    
    
    tempshifts = frameshiftstouse_unwraped(:,2:end,:);
    meanintraframeshift = mean(tempshifts,1);
    tempshifts = tempshifts - repmat(meanintraframeshift,[numstrips 1 1]);
    firstframeshift = mean(tempshifts,2);
    
    tempshifts = frameshiftstouse_unwraped;
    frameshiftstouse_unwraped(:,1,:) = firstframeshift;
    frameshiftstouse_unwraped(:,2:end,:) = tempshifts(:,2:end,:) -...
        repmat(firstframeshift,[1 (numframesinsegment - 1) 1]);
    segmentframeshifts_strips_unwraped(:,indicesofsegmentdata,:) = frameshiftstouse_unwraped;
    
    for directioncounter = 1:2
        tempshifts = frameshiftstouse_unwraped(:,:,directioncounter);
        frameshiftstouse(:,directioncounter) = tempshifts(:);
    end
    
%     timeaxis = [0:(numlinesperfullframe * numframesinsegment) - 1];
%     timeaxis = reshape(timeaxis,numlinesperfullframe,numframesinsegment);
%     timeaxis = timeaxis(stripidx,:);
%     timeaxis = timeaxis(:);
%     time_secs = timeaxis / (numlinesperfullframe * videoframerate);
%     timediff_secs = diff(time_secs(:),[],1);
%     timediff_secs = repmat([timediff_secs(1);timediff_secs],1,2);
    
    thresholdstouse_currentseg = repmat(thresholdstouse,size(frameshiftstouse,1),1);
    isgreaterthanthreshold = sum(sum((abs(frameshiftstouse) > thresholdstouse_currentseg),1),2);
    
%     pixelsize_deg_currentseg = repmat(pixelsize_deg,size(frameshiftstouse,1),1);
%     frameshifts_deg = frameshiftstouse .* pixelsize_deg_currentseg;
%     velocityinseg = diff([0,0;frameshifts_deg],[],1) ./ timediff_secs;
%     
%     maxabsvelocityinseg = max(max(abs(velocityinseg),[],1),[],2);
%     maxexcursionincurrentseg = max(max(frameshifts_deg,[],1) - min(frameshifts_deg,[],1),[],2);
%     
%     segmentmaxvels(segmentcounter) = maxabsvelocityinseg;
%     segmentmaxexcursions(segmentcounter) = maxexcursionincurrentseg;
%     
%     if (maxabsvelocityinseg > maxvelthreshold) || (maxexcursionincurrentseg > maxexcursionthreshold)
      if isgreaterthanthreshold
        segmentsdroppedduetohighvel = [segmentsdroppedduetohighvel;segmentcounter];
        continue;
    end
    
    [stabilisedframe,stabilisedframe_full] = ...
        makestabilizedframe(videoname,currentsegmentframenumbers,frameshiftstouse,peakratios,...
        stripidx,badstripthreshold,numlinesperfullframe,2.5,1,0);
    
    segmentreferenceframes{segmentcounter} = stabilisedframe;
    
    prog = segmentcounter / numsegments;
    waitbar(prog,analysisprog);
end

if ~isempty(segmentsdroppedduetohighvel)
    goodstitchablesegments = setdiff([1:numsegments]',segmentsdroppedduetohighvel);
else
    goodstitchablesegments = [1:numsegments]';
end

intersegmentshifts = zeros(numsegments,2);
intersegmentmaxvals = ones(numsegments,1);
intersegmentsecondpeaks = ones(numsegments,1);
intersegmentnoises = ones(numsegments,1);

tempreferencematrix = segmentreferenceframes{min(goodstitchablesegments)};
tempreferenceimage = tempreferencematrix(:,:,2);
tempreferenceimage_zerobkgnd = tempreferencematrix(:,:,3);

currentsegmentnumber = 1;
segmentstostitch = intersect([2:numsegments]',goodstitchablesegments);
segmentsstitchedinthisloop = [];

toexit = 0;
while ~toexit
    if currentsegmentnumber == 1
        waitbar(0,analysisprog,'Stitching Segments Together');
    end
    indexintomatrix = segmentstostitch(currentsegmentnumber);
    currenttestrefmatrix = segmentreferenceframes{indexintomatrix};
    currenttestrefimage = currenttestrefmatrix(:,:,2);
    currenttestrefimage_zerobkgnd = currenttestrefmatrix(:,:,3);
    
    [correlation shifts peaks_noise] = corr2d(tempreferenceimage,currenttestrefimage,1);
    
    peakratio = peaks_noise(2) / peaks_noise(1);
    
    if peakratio <= badstripthreshold
        currenttemprefsize = [size(tempreferenceimage,2),size(tempreferenceimage,1)];
        currenttestrefsize = [size(currenttestrefimage,2),size(currenttestrefimage,1)];
        
        indicestoputrefmatrix_h = [1:currenttemprefsize(1)];
        indicestoputrefmatrix_v = [1:currenttemprefsize(2)];
        
        indicestoputtestmatrix_h = (floor((currenttemprefsize(1) - currenttestrefsize(1)) / 2) -...
            round(shifts(1))) + [0:currenttestrefsize(1) - 1];
        if indicestoputtestmatrix_h(1) < 1
            diffinhoriindex = 1 - indicestoputtestmatrix_h(1);
            indicestoputtestmatrix_h = indicestoputtestmatrix_h + diffinhoriindex;
            indicestoputrefmatrix_h = indicestoputrefmatrix_h + diffinhoriindex;
        end
        newtemprefsize_h = max(indicestoputtestmatrix_h(end),indicestoputrefmatrix_h(end));
        
        indicestoputtestmatrix_v = (floor((currenttemprefsize(2) - currenttestrefsize(2)) / 2) -...
            round(shifts(2))) + [0:currenttestrefsize(2) - 1];
        if indicestoputtestmatrix_v(1) < 1
            diffinvertindex = 1 - indicestoputtestmatrix_v(1);
            indicestoputtestmatrix_v = indicestoputtestmatrix_v + diffinvertindex;
            indicestoputrefmatrix_v = indicestoputrefmatrix_v + diffinvertindex;
        end
        newtemprefsize_v = max(indicestoputtestmatrix_v(end),indicestoputrefmatrix_v(end));
        
        intersegmentshifts(indexintomatrix,:) = shifts;
        intersegmentmaxvals(indexintomatrix) = peaks_noise(1);
        intersegmentsecondpeaks(indexintomatrix) = peaks_noise(2);
        intersegmentnoises(indexintomatrix) = peaks_noise(3);
        
        segmentsstitchedinthisloop = [segmentsstitchedinthisloop;segmentstostitch(currentsegmentnumber)];
        
        newtempreferenceimage = zeros(newtemprefsize_v,newtemprefsize_h);
        refsummatrix = zeros(newtemprefsize_v,newtemprefsize_h);
        testsummatrix = zeros(newtemprefsize_v,newtemprefsize_h);
        
        newtempreferenceimage(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = tempreferenceimage_zerobkgnd;
        
        pixelswithrefimagedata = ones(size(tempreferenceimage_zerobkgnd));
        pixelswithrefimagedata(tempreferenceimage_zerobkgnd == 0) = 0;
        refsummatrix(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = pixelswithrefimagedata;
        
        newtempreferenceimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) =...
            newtempreferenceimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) + currenttestrefimage_zerobkgnd;
        
        pixelswithtestimagedata = ones(size(currenttestrefimage_zerobkgnd));
        pixelswithtestimagedata (currenttestrefimage_zerobkgnd == 0) = 0;
        testsummatrix(indicestoputtestmatrix_v,indicestoputtestmatrix_h) = pixelswithtestimagedata ;
        
        summatrix = refsummatrix + testsummatrix;
        summatrix(summatrix == 0) = 1;
        newtempreferenceimage = newtempreferenceimage ./ summatrix;
        newtempreferenceimage_zerobkgnd = newtempreferenceimage;
        
        pixelswithrefimagedata = find(tempreferenceimage_zerobkgnd >= 1);
        pixelswithrefnoimagedata = find(tempreferenceimage_zerobkgnd <= 0);
        
        numpixelswithimagedata = length(pixelswithrefimagedata(:));
        numpixelswithrefnoimagedata = length(pixelswithrefnoimagedata(:));
        
        newtempreferenceimage(pixelswithrefnoimagedata) = tempreferenceimage_zerobkgnd(pixelswithrefimagedata(floor(rand(numpixelswithrefnoimagedata,1) *...
            (numpixelswithimagedata - 1)) + 1));
        
        tempreferenceimage = newtempreferenceimage;
        tempreferenceimage_zerobkgnd = newtempreferenceimage_zerobkgnd;
        
    end
    
    currentsegmentnumber = currentsegmentnumber + 1;
    
    if currentsegmentnumber > length(segmentstostitch)
        currentsegmentnumber = 1;
        segmentstostitch = setdiff(segmentstostitch,segmentsstitchedinthisloop);
        if isempty(segmentstostitch) || isempty(segmentsstitchedinthisloop)
            segmentsnotstitched = segmentstostitch;
            toexit = 1;
            break;
        end
        
        segmentsstitchedinthisloop = [];
        waitbar(0,analysisprog,'Temp');
    end
    
    prog = currentsegmentnumber ./ length(segmentstostitch);
    waitbar(prog,analysisprog);
end

goodsegments = setdiff([1:numsegments]',segmentsnotstitched);

close(analysisprog);

for directioncounter = 1:2
    tempshifts = segmentframeshifts_strips_unwraped(:,:,directioncounter);
    segmentframeshifts_strips(:,directioncounter) = tempshifts(:);
    
    tempshifts = segmentframeshifts_strips_unwraped_withave(:,:,directioncounter);
    segmentframeshifts_strips_withave(:,directioncounter) = tempshifts(:);
end

segmentmaxvals_strips = segmentmaxvals_strips_unwraped(:);
segmentsecondpeaks_strips = segmentsecondpeaks_strips_unwraped(:);
segmentnoises_strips = segmentnoises_strips_unwraped(:);

pixelswithnoimagedata = find(tempreferenceimage_zerobkgnd == 0);
pixelswithimagedata = find(tempreferenceimage_zerobkgnd >= 1);

referenceimage_meanvals = tempreferenceimage_zerobkgnd;
referenceimage_meanvals(pixelswithnoimagedata) = mean(referenceimage_meanvals(pixelswithimagedata));

referenceimage_randvals = tempreferenceimage_zerobkgnd;
referenceimage_randvals(pixelswithnoimagedata) = tempreferenceimage(floor(rand(length(pixelswithnoimagedata),1) * (length(pixelswithimagedata) - 1)) + 1);

referenceimage_zeroval = tempreferenceimage_zerobkgnd;

referenceimage = referenceimage_randvals;
referencematrix = cat(3,referenceimage_meanvals,referenceimage_randvals,referenceimage_zeroval);

randstring = num2str(min(ceil(rand(1) * 10000),9999));
sampleratestring = num2str(samplerate);
fullstring = strcat('_segmented_',sampleratestring,'hz_',...
    num2str(minimumframespersegment),'_',randstring,'.mat');
datafilename = strcat(videoname(1:end - 4),fullstring);

analysedframes_initial = framesforreference_initial;
analysedframes = framesforreference;
videoname_check = videofilename;

save(datafilename,'referenceimage','referencematrix',...
    'analysedframes_initial','analysedframes','videoname_check',...
    'goodsegments','segmentframeshifts_strips','segmentframeshifts_strips_withave',...
    'segmentmaxvals_strips','segmentsecondpeaks_strips','segmentnoises_strips',...
    'segmentframeshifts_thumbnails','segmentmaxvals_thumbnails',...
    'segmentsecondpeaks_thumbnails','segmentnoises_thumbnails','referencetouse',...
    'segmentnumbers','intersegmentshifts','intersegmentmaxvals',...
    'intersegmentsecondpeaks','intersegmentnoises','samplerate','defaultsearchzone_vert',...
    'stripheight','badstripthreshold','minimumframespersegment','numlinesperfullframe',...
    'segmentstartframes','segmentendframes','segmentreferenceframes','pixelsize_deg',...
    'maxvelthreshold','segmentmaxvels','maxexcursionthreshold','segmentmaxexcursions',...
    'segmentsdroppedduetohighvel');

if verbose
    mymap = repmat([0:255]' / 256,1,3);
    figure
    image(referenceimage);
    colormap(mymap);
    axis off;
    truesize
end