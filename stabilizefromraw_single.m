%% Stabilize from raw video
% (c) 2009 SBStevenson@uh.edu and GKR
%
% This script creates a stabilized version of multiple raw AVI format videos.
% It is designed to work with AOSLO retinal images and will not work very
% well with conventional SLO images.
% This script is essentially a macro that calls a series of functions to
% carry out the analysis steps. These functions should be in
% ~\MatlabXXXX\toolbox\AOSLO\
bPRLVid =false;

params.minimummeanlevel = 62; %Use survey videos to judge.%Descriptions at line 115;
params.nostimmeanlevel= 2;
params.blinkthreshold =10;
params.coarseframeincrement =30;
params.peakratiodiff = 0.3;
params.maxmotionthreshold=0.05;
params.badsamplethreshold=0.8;
screensize = get(0,'ScreenSize');

[fname pname] = uigetfile('*.avi','Please enter filename of the video you want stabilized');
videotoanalyse = strcat(pname,fname);
%keyboard;
currentvideoinfo = VideoReader(videotoanalyse);
frameheight = currentvideoinfo.Height;
framewidth = currentvideoinfo.Width;
framerate = round(currentvideoinfo.FrameRate);
numberofframes = round(currentvideoinfo.FrameRate*currentvideoinfo.Duration);
flip =true; %true for aosloIII
% Get the image format in which to save the stabilised image from the user
formatofstabframe = questdlg('In what image format do you want to save the stabilized frame',...
    'Image Format','JPEG','TIFF','GIF','JPEG');
formatofstabframe = strcat('.',lower(formatofstabframe));


% Set the parameters for the various functions used inthis scriptsU
blinkthreshold = params.blinkthreshold;                % This is a maximum change in mean pixel value between
                                    % frames before the function tags the frames as blink
                                    % frames.
minimummeanlevel = params.minimummeanlevel;              % This is minimum mean pixel value that a frame has to
                                    % have for it to be considered for analyses.
peakratiodiff = params.peakratiodiff;   %from 0.05            % Maximum Change in ratio between the secondpeak and firstpeak
                                    % between two frames for the frames before the function tags the frames as "bad".

maxmotionthreshold = params.maxmotionthreshold;           % Maximum motion between frames, expressed as a percentage
                                    % of the frame dimensions, before frames aSre tagged as "bad".
coarseframeincrement = params.coarseframeincrement;          % The step size used when choosing a subset of frames
                                    % from the frames that are good. This is used by the
                                    % makereference_framerate.m function.s
badsamplethreshold = params.badsamplethreshold;           %from 0.55  % The thresholdthat is used to locate the strips that had
                                    % good correlations during the analysis procedure. The lower
                                    % the number the more samples are discarded as "bad matches".

tofilter = 0;                       % If the video has luminance gradients or has too much pixel noise
                                    % then it would be wise to filter the video prior to analyses by setting
                                    % this flag to 1. If not set it to 0.
gausslowcutoff = 3;                 % Low Frequency cutoff  for the gaussbandfilter.m function
smoothsd = 2;                       % The std. deviation of the gaussian smothing filter that is
                                    % applied by the gaussbandfilter.m function.
toremmeanlum = 0;                   % If the video has luminance artifacts that has high frequency content
                                    % set this flag to 1 to use the removemeanlum.m function, otherwise
                                    % set to 0;
smoothsdformeanremoval = 15;        % The std. deviation of the smoothing function used by the removemeanlum.m
                                    % function.
numframestoaverage = -1;            % The number of frame to average toget if you want to remove the influence of
                                    % the mean frame luminance. If you set it to -1 then the program averages all
                                    % the frames
samplerateincrement_priorref = 30;  % The multiple of the framerate that is used
                                    % to obtain the sample rate of the ocular motion
                                    % trace when using the makereference_priorref.m function.
samplerateincrement = 30;           % The multiple of the framerate that is used
                                    % to obtain the sample rate of the ocular motion
                                    % trace when using the analysevideo_priorref.m function.
maintaintimerelationships = 0;      % Certain post analysis questions require the stabilised video
                                    % to reflect accurate time relationships between frames. However
                                    % over the course of the analysis we drop frames that can't be
                                    % analysed accurately. If the user requires accurate time
                                    % relationships then this flag should be set to one, otherwise
                                    % set it to 0. When this flag is turned on, dropped frames are
                                    % replaced by a blank frame in the stabilised video.
numlinesperfullframe = 512;         % The number of pixel lines that would have been present in a video
                                    % frame if data was collected during the vertical mirror flyback.
blacklineflag = 1;                  % When the eye moves faster than the vertical scan rate black lines are present
                                    % in the stabilised video. This occurs because no image data was collected at
                                    % this location. If you find these lines disconcerting, then set this flag to 1,
                                    % otherwise set to 0. These lines are removed by averaging the image data from
                                    % the lines above and below the black lines.
maxsizeincrement = 2;               % When creating stabilised movies and frames, physical memory is a big issue.
                                    % If the maximum motion in the raw video is too high, MATLAB runs out of
                                    % memory and crashes. To prevent that we have to set a maximum size for the
                                    % stabilised video and frame. The maxsizeincrement sets this limit, as a multiple
                                    % of the raw frame size. The maximum value for this parameter that we have
                                    % tested is 2.5. Any image that is outside is set limit is cropped.
splineflag = 0;                     % When calculating splines during the stabilisation, we could calculate
                                    % splines for individual frames (splineflag = 1), or calculate on spline
                                    % for the full video (splineflag = 0).

priorref_inputstruct = struct('samplerate',[],'vertsearchzone',55,'stripheight',13,...
    'badstripthreshold',badsamplethreshold,'frameincrement',coarseframeincrement,'minpercentofgoodstripsperframe',0.4,...
    'numlinesperfullframe',numlinesperfullframe); % Structure that contains input arguments for the makereference_priorref.m function.
analyse_inputstruct = struct('samplerate',[],'vertsearchzone',55,'horisearchzone',[],...
    'startframe',1,'endframe',-1,'stripheight',13,'badstripthreshold',0.6,'minpercentofgoodstripsperframe',0.4,...
    'numlinesperfullframe',numlinesperfullframe); % Structure that contains input arguments for the analysevideo_priorref.m function.

% Set the correlation flags for the analyses programs
correlationflags_framerate =[1;1];% Array that controls the cross-correlations conducted by makereference_framerate
correlationflags_priorref = [1;1];% Array that controls the cross-correlations conducted by makereference_priorref
correlationflags_analyse = [1;1];% Array that controls the cross-correlations conducted by analysevideo_priorref
% For all of the previous correlation flag array, the first element if set to 1 forces the programs to return the
% shift with sub-pixel accuracy, while the second force the programs to multiply the test matrix with a raised cosine
% window prior to the cross-correlation
analyse_programflags = [1 0]; % Array with the analysis flags used by the analysevideo_priorref.m function.
% Note at moment have not implemented the correction factor, so do not set
% the second flag in the above array to 1, until otherwise informed.


% Set the feedback options for the various functions used inthis script
blinkverbosity = 1;                 % Set to 1 if you want feedback from the getblinkframes.m
                                    % function, otherwise set to 0.
meanlumverbosity = 1;               % Set to 1 if you want feedback from the removemeanlum.m
                                    % function, otherwise set to 0.
badframeverbosity = 1;              % Set to 1 if you want feedback from the getbadframes.m
                                    % function, otherwise set to 0.
coarserefverbosity = [0 1];         % The verbose array used by the makereference_framerate.m
                                    % function.
finerefverbosity = [0 0 0 1];       % The verbose array used by the makereference_priorref.m
                                    % function.
analyverbosity = [0 0 0 0];         % The verbose array used by the analysevideo_priorref.m
                                    % function.
stabverbosity = 1;                  % Set to 1 if you want feedback from the makestabilizedvideoandframe.m
                                    % function, otherwise set to 0.
stabframeverbosity = 1;             % Set to 1 if you want feedback from the makestabilizedvideo.m
                                    % function, otherwise set to 0.

priorref_inputstruct.samplerate = framerate * samplerateincrement_priorref;
analyse_inputstruct.samplerate = framerate * samplerateincrement;
analyse_inputstruct.horisearchzone = floor((3 * framewidth) / 4);

blinkfilename = strcat(videotoanalyse(1:end - 4),'_blinkframes.mat');
stimfilename = strcat(videotoanalyse(1:end - 4),'_stimframes.mat');

if tofilter
    filteredname =  strcat(videotoanalyse(1:end-4),'_bandfilt.avi');
else
    filteredname = videotoanalyse;
end

if toremmeanlum
    finalname = strcat(filteredname(1:end - 4),'_meanrem.avi');
else
    finalname = filteredname;
end

stabimagename_noext = videotoanalyse(1:end - 4);

switch (tofilter + toremmeanlum)
    case 0
        stringstoshow = {'Getting Blink Frames';'Getting Bad Frames';...
            'Making the Coarse Reference Frame';...
            'Making the Fine Reference Frame';'Analysing Video';...
            'Making the Stabilised Frame and Video'};
    case 1
        if tofilter
            stringstoshow = {'Getting Blink Frames';'Filtering Video';...
                'Getting Bad Frames';'Making the Coarse Reference Frame';...
                'Making the Fine Reference Frame';'Analysing Video';...
                'Making the Stabilised Frame and Video'};
        else
            stringstoshow = {'Getting Blink Frames';'Removing Mean Luminance';...
                'Getting Bad Frames';'Making the Coarse Reference Frame';...
                'Making the Fine Rerence Frame';'Analysing Video';...
                'Making the Stabilised Frame and Video'};
        end
    case 2
        stringstoshow = {'Getting Blink Frames';'Filtering Video';...
                'Removing Mean Luminance';'Getting Bad Frames';...
                'Making the Coarse Reference Frame';...
                'Making the Fine Reference Frame';'Analysing Video';...
                'Making the Stabilised Frame and Video'};
end

numstringstoshow = length(stringstoshow);
texthandles = zeros(numstringstoshow,1);
startindex = 1 - ((1 - (numstringstoshow / 10)) / 2);
endindex = startindex - ((numstringstoshow - 1) / 10);
indicestoputtext = [startindex:-0.1:endindex];

userfeedbackfig = figure;
oldfigposition = get(userfeedbackfig,'Position');
newfigposition = [1 1 round(screensize(3) / 3) round(2 * screensize(4) / 3)];
set(userfeedbackfig,'Position',newfigposition,'Toolbar','none','Name',...
    'Progress of Analyses','Units','Normalized');
textaxes = axes('Position',[0 0 1 1],'Visible','off','Units','Normalized');
for textcounter = 1:numstringstoshow
    texthandles(textcounter) = text(0.1,indicestoputtext(textcounter),stringstoshow{textcounter},'FontName','Courier');
end
% set(
currenttexthandleindex = 1;
tic

set(texthandles(currenttexthandleindex),'FontWeight','Bold');
currenttexthandleindex = currenttexthandleindex + 1;
blinkframes = getblinkframes(videotoanalyse, blinkthreshold, minimummeanlevel,blinkverbosity);
if(bPRLVid)
   stimframes =  getblinkframes(videotoanalyse, blinkthreshold, params.nostimmeanlevel,0);
end
if tofilter
    set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
    set(texthandles(currenttexthandleindex),'FontWeight','Bold');
    currenttexthandleindex = currenttexthandleindex + 1;
    gaussbandfilter(videotoanalyse, gausslowcutoff, smoothsd);
end

if toremmeanlum
    set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
    set(texthandles(currenttexthandleindex),'FontWeight','Bold');
    currenttexthandleindex = currenttexthandleindex + 1;
    removemeanlum(filteredname,smoothsdformeanremoval,numframestoaverage,meanlumverbosity);    
end


set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
set(texthandles(currenttexthandleindex),'FontWeight','Bold');
currenttexthandleindex = currenttexthandleindex + 1;
[goodframesegmentinfo largemovementframes] = getbadframes(finalname,blinkfilename,...
    peakratiodiff, maxmotionthreshold, badframeverbosity);
if(bPRLVid)
    getbadframes(finalname,stimfilename,...
    peakratiodiff, maxmotionthreshold, badframeverbosity);    
end
set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
set(texthandles(currenttexthandleindex),'FontWeight','Bold');
currenttexthandleindex = currenttexthandleindex + 1;
if(bPRLVid)
    [coarsereffilename, coarsereferimage] = makereference_framerate(finalname,...
        stimfilename, coarseframeincrement, badsamplethreshold,correlationflags_framerate,coarserefverbosity);
else
    [coarsereffilename, coarsereferimage] = makereference_framerate(finalname,...
        blinkfilename, coarseframeincrement, badsamplethreshold,correlationflags_framerate,coarserefverbosity);

end
set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
set(texthandles(currenttexthandleindex),'FontWeight','Bold');
currenttexthandleindex = currenttexthandleindex + 1;
[finereffilename, finerefimage] = makereference_priorref(finalname,...
    coarsereffilename, blinkfilename, 'referenceimage', priorref_inputstruct,correlationflags_priorref,finerefverbosity);

set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
set(texthandles(currenttexthandleindex),'FontWeight','Bold');
currenttexthandleindex = currenttexthandleindex + 1;
analyseddatafilename = analysevideo_priorref(finalname, finereffilename, blinkfilename,...
    'referenceimage', analyse_inputstruct, analyse_programflags,correlationflags_analyse, analyverbosity);

load(analyseddatafilename,'analysedframes','frameshifts_strips_spline','peakratios_strips',...
    'stripidx');

set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
set(texthandles(currenttexthandleindex),'FontWeight','Bold');

[stabilisedvideoname,stabilizedframe,stabilizedframe_full] =...
    makestabilizedvideoandframe(videotoanalyse, analysedframes,...
    frameshifts_strips_spline, peakratios_strips, stripidx, badsamplethreshold,...
    maintaintimerelationships, numlinesperfullframe, blacklineflag, maxsizeincrement,...
    splineflag, stabverbosity);

load(finereffilename,'analysedframes','frameshifts_strips_spline','peakratios_strips','stripidx');

[stabilizedframe_priorref,stabilizedframe_priorref_full] =...
    makestabilizedframe(videotoanalyse,analysedframes,...
    frameshifts_strips_spline,peakratios_strips,stripidx,badsamplethreshold,...
    numlinesperfullframe,maxsizeincrement,splineflag,stabverbosity);

timeelapsed = toc;

save(analyseddatafilename,'blinkframes','goodframesegmentinfo','largemovementframes',...
    'coarsereferimage','finerefimage','stabilizedframe','stabilizedframe_full',...
    'stabilizedframe_priorref','stabilizedframe_priorref_full','-append');

switch formatofstabframe
    case '.jpeg'
        stabimagename = strcat(stabimagename_noext,formatofstabframe);
        imwrite(stabilizedframe(:,:,1) / 256,stabimagename,'Quality',100);
    case '.tiff'
        stabimagename = strcat(stabimagename_noext,'.tiff');
        imwrite(stabilizedframe(:,:,1) / 256,stabimagename,'Compression','none');
    case '.gif'
        stabimagename = strcat(stabimagename_noext,'.gif');
        imwrite(stabilizedframe(:,:,1) / 256,stabimagename);
end

close(userfeedbackfig);

totalstring = ['Total time elapsed ', num2str(round(timeelapsed * 10000) / 100),' seconds'];
framestring = ['Average time per frame ', num2str(round((timeelapsed  * 1000) / numberofframes) / 100),' seconds'];

disp(totalstring);
disp(framestring);