%% Stabilize from raw video
% (c) 2009 SBStevenson@uh.edu and GKR
%
% This script creates a stabilized version of multiple raw AVI format videos.
% It is designed to work with AOSLO retinal images and will not work very
% well with conventional SLO images.
% This script is essentially a macro that calls a series of functions to
% carry out the analysis steps. These functions should be in
% ~\MatlabXXXX\toolbox\AOSLO\

% NB: this code was modified to register split detection videos. It takes
% the motion of the confocal video and applies it to the raw videos of the
% split detection PMTs. It generates a split detection and a dark field
% image. The user should only select the confocal videos to process and the
% software will automatically process the confocal and split videos.

params.minimummeanlevel = 45; %Use survey videos to judge.%Descriptions at line 115;
params.blinkthreshold =10;
params.coarseframeincrement =17;
params.peakratiodiff = 0.2;
params.maxmotionthreshold=0.3;
params.badsamplethreshold=0.6;


rand('state',sum(100 * clock));
randn('state',sum(100 * clock));

currentdir = pwd;
screensize = get(0,'ScreenSize');
if ispc
    pathslash = '\';
else
    pathslash = '/';
end

videosnotanalysed = {};
thrownexceptions = {};

% Get info from the user regarding the directories where the videos are
% present and then load the video names into a .

prompt={'How many directories are your videos in?'};
name='Directory Query';
numlines=1;
defaultanswer={'1'};

answer = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(answer)
    disp('You need to supply the number of directories where you have placed videos,Exiting...');
    return;
end
numdirectories = str2double(answer{1});

directorynames = cell(numdirectories,1);
listboxstrings = {};
filelist = {};

prevdir = currentdir;
for directorycounter = 1:numdirectories
    tempdirname = uigetdir(prevdir,'Please choose a single folder with video files');
    if tempdirname == 0
        disp('You pressed cancel instead of choosing a driectory');
        warning('Continuing...');
        continue
    end
    directorynames{directorycounter} = tempdirname;
    dirstucture = dir(tempdirname);
    for structurecounter = 1:length(dirstucture)
        if ~(dirstucture(structurecounter).isdir)
            tempname = dirstucture(structurecounter).name;
            fileextension = upper(tempname(end-2:end));
            if strcmp(fileextension,'AVI')
                filelist{end + 1} = strcat(tempdirname,pathslash,tempname);
                listboxstrings{end + 1} = tempname;
            end
        end
    end
    prevdir = tempdirname;
    cd(tempdirname);
end

% If the directory has no video, exit
if isempty(listboxstrings)
    error('No AVI videos in selected folders, exiting....');
end

selection = listdlg('ListString',listboxstrings,'InitialValue',[],'Name',...
    'File Select','PromptString','Please select videos to stabilize');

% If the user does not choose any video, exit
if isempty(selection)
    disp('You have not selected any video, Exiting...');
    return;
end
numfiletoanalyse = length(selection);

% Get the image format in which to save the stabilised image from the user
formatofstabframe = questdlg('In what image format do you want to save the stabilized frame',...
    'Image Format','JPEG','TIFF','GIF','JPEG');
formatofstabframe = strcat('.',lower(formatofstabframe));

% tomakemontage = lower(questdlg('Do you want to make a montage of the individual stablised frames',...
%     'Montage Query','Yes','No','Yes'));
% tomakemontage = strcmp(tomakemontage(1),'y');
tomakemontage = 0; % Currently the make montage program is a bit buggy - better not to use until otherwise informed

if tomakemontage
    allstabframes_unfiltered = {};
    allstabframes = {};
end

cd(currentdir);

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
meanlumverbosity = 0;               % Set to 1 if you want feedback from the removemeanlum.m
% function, otherwise set to 0.
badframeverbosity = 1;              % Set to 1 if you want feedback from the getbadframes.m
% function, otherwise set to 0.
coarserefverbosity = [0 0];         % The verbose array used by the makereference_framerate.m
% function.           - A 2 element array that determines the type of feedback that is given to the user. If the first element is set
%                                  to 1, then the program plots the cross-correlation function everytime the program conducts a cross-correlation.
%                                  If the second element isset to 1 then the program draws the image of the reference image once the prgram is done with its analyses.

finerefverbosity = [0 0 0 1];       % The verbose array used by the makereference_priorref.m
% function.
analyverbosity = [0 0 0 0];         % The verbose array used by the analysevideo_priorref.m
% function.
stabverbosity = 0;                  % Set to 1 if you want feedback from the makestabilizedvideo.m
% function, otherwise set to 0.

totalnumofframesanalysed = 0;

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

analysesprogstring = ['Progress of Analyses: 0/',num2str(numfiletoanalyse),' Files Done'];
userfeedbackfig = figure;
oldfigposition = get(userfeedbackfig,'Position');
newfigposition = [1 1 round(screensize(3) / 3) round(2 * screensize(4) / 3)];
set(userfeedbackfig,'Position',newfigposition,'Toolbar','none','Name',...
    analysesprogstring,'Units','Normalized');
textaxes = axes('Position',[0 0 1 1],'Visible','off','Units','Normalized');
for textcounter = 1:numstringstoshow
    texthandles(textcounter) = text(0.1,indicestoputtext(textcounter),stringstoshow{textcounter});
end

tic
processprog = waitbar(0,'Processing Videos');
oldposition = get(processprog,'Position');
newstartindex = round(oldposition(1) - (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(processprog,'Position',newposition);

for filecounter = 1:numfiletoanalyse
    try
        
        currenttexthandleindex = 1;
        if filecounter > 1
            set(texthandles(end),'FontWeight','Normal');
        end
        videotoanalyse = filelist{selection(filecounter)};
        
        currentvideoinfo = VideoReader(videotoanalyse);
        frameheight = currentvideoinfo.Height;
        framewidth = currentvideoinfo.Width;
        framerate = round(currentvideoinfo.FrameRate);
        numberofframes = round(currentvideoinfo.FrameRate*currentvideoinfo.Duration);
        
        totalnumofframesanalysed = totalnumofframesanalysed + numberofframes;
        
        priorref_inputstruct.samplerate = round(framerate * samplerateincrement_priorref);
        analyse_inputstruct.samplerate = round(framerate * samplerateincrement);
        analyse_inputstruct.horisearchzone = (3 * framewidth) / 4;
        
        
        blinkfilename = strcat(videotoanalyse(1:end - 4),'_blinkframes.mat');
        
        if tofilter
            filteredname = strcat(videotoanalyse(1:end - 4),'_bandfilt.avi');
        else
            filteredname = videotoanalyse;
        end
        
        if toremmeanlum
            finalname =  strcat(filteredname(1:end-4),'_meanrem.avi');
        else
            finalname = filteredname;
        end
        
        stabimagename_noext = videotoanalyse(1:end - 4);
        
        set(texthandles(currenttexthandleindex),'FontWeight','Bold');
        currenttexthandleindex = currenttexthandleindex + 1;
        blinkframes = getblinkframes(videotoanalyse, blinkthreshold, minimummeanlevel,blinkverbosity);
        
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
        
        set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
        set(texthandles(currenttexthandleindex),'FontWeight','Bold');
        currenttexthandleindex = currenttexthandleindex + 1;
        [coarsereffilename, coarsereferimage] = makereference_framerate(finalname,...
            blinkfilename, coarseframeincrement, badsamplethreshold,correlationflags_framerate,coarserefverbosity);
         
        set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
        set(texthandles(currenttexthandleindex),'FontWeight','Bold');
        currenttexthandleindex = currenttexthandleindex + 1;
        [finereffilename, finerefimage] = makereference_priorref(finalname,...
            coarsereffilename,blinkfilename, 'referenceimage', priorref_inputstruct,correlationflags_priorref,...
            finerefverbosity);
        
        set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
        set(texthandles(currenttexthandleindex),'FontWeight','Bold');
        currenttexthandleindex = currenttexthandleindex + 1;
        analyseddatafilename = analysevideo_priorref(finalname, finereffilename, blinkfilename,...
            'referenceimage', analyse_inputstruct, analyse_programflags,correlationflags_analyse, analyverbosity);
        
        load(analyseddatafilename,'analysedframes','frameshifts_strips_spline','peakratios_strips',...
            'stripidx','referenceimage');
        
        set(texthandles(currenttexthandleindex - 1),'FontWeight','Normal');
        set(texthandles(currenttexthandleindex),'FontWeight','Bold');
        
        [stabilisedvideoname,stabilizedmatrix,stabilizedmatrix_full] =...
            makestabilizedvideoandframe(videotoanalyse, analysedframes,...
            frameshifts_strips_spline, peakratios_strips, stripidx, badsamplethreshold,...
            maintaintimerelationships, numlinesperfullframe, blacklineflag, maxsizeincrement,...
            splineflag, stabverbosity);

        videotoanalyse_split1 = strcat(videotoanalyse(1:end-13),'2',videotoanalyse(end-11:end));
        videotoanalyse_split2 = strcat(videotoanalyse(1:end-13),'3',videotoanalyse(end-11:end));
        
        [stabilisedvideoname_split1,stabilizedmatrix_split1,stabilizedmatrix_full_split1] =...
            makestabilizedvideoandframe(videotoanalyse_split1, analysedframes,...
            frameshifts_strips_spline, peakratios_strips, stripidx, badsamplethreshold,...
            maintaintimerelationships, numlinesperfullframe, blacklineflag, maxsizeincrement,...
            splineflag, stabverbosity);
        
        [stabilisedvideoname_split2,stabilizedmatrix_split2,stabilizedmatrix_full_split2] =...
            makestabilizedvideoandframe(videotoanalyse_split2, analysedframes,...
            frameshifts_strips_spline, peakratios_strips, stripidx, badsamplethreshold,...
            maintaintimerelationships, numlinesperfullframe, blacklineflag, maxsizeincrement,...
            splineflag, stabverbosity);        
        
        stabilizedframe = stabilizedmatrix(:,:,3);
        stabilizedframe_split1 = stabilizedmatrix_split1(:,:,3);
        stabilizedframe_split2 = stabilizedmatrix_split2(:,:,3);
        
        
        if tomakemontage
            allstabframes_unfiltered{end + 1} = stabilizedmatrix(:,:,3);
            allstabframes{end + 1} = referenceimage;
        end
        
        save(analyseddatafilename,'blinkframes','goodframesegmentinfo','largemovementframes',...
            'coarsereferimage','finerefimage','stabilizedframe','stabilizedmatrix','stabilizedmatrix_full','-append');
        
        switch formatofstabframe
            case '.jpeg'
                stabimagename = strcat(stabimagename_noext,formatofstabframe);
                imwrite(stabilizedmatrix(:,:,3) / 256,stabimagename,'Quality',100);
            case '.tiff'
                stabimagename = strcat(stabimagename_noext,'.tiff');
                imwrite(stabilizedmatrix(:,:,3) / 256,stabimagename,'Compression','none');
                stabimagename_split1 = strcat(videotoanalyse_split1(1:end-4),'.tiff');
                imwrite(stabilizedmatrix_split1(:,:,3) / 256,stabimagename_split1,'Compression','none');
                stabimagename_split2 = strcat(videotoanalyse_split2(1:end-4),'.tiff');
                imwrite(stabilizedmatrix_split2(:,:,3) / 256,stabimagename_split2,'Compression','none');   
                
                PMT2Im = stabilizedmatrix_split1(:,:,3) / 256;
                PMT3Im = stabilizedmatrix_split2(:,:,3) / 256;
                
                splitIm = ( (PMT2Im-PMT3Im)./(PMT2Im+PMT3Im) + 1 ) ./ 2; 
                darkFieldIm = (PMT2Im+PMT3Im) ./ max(max(PMT2Im+PMT3Im));

                imwrite(splitIm,strcat(stabimagename_split1(1:end-5),'_splitimage.tiff'),'Compression','none');   
                imwrite(darkFieldIm,strcat(stabimagename_split1(1:end-5),'_darkfield.tiff'),'Compression','none');   
                
            case '.gif'
                stabimagename = strcat(stabimagename_noext,'.gif');
                imwrite(stabilizedmatrix(:,:,3) / 256,stabimagename);
        end
        
        prog = filecounter / numfiletoanalyse;
        waitbar(prog,processprog);
        
        analysesprogstring = ['Progress of Analyses: ', num2str(filecounter),'/',num2str(numfiletoanalyse),' Files Done'];
        set(userfeedbackfig,'Name',analysesprogstring);
    catch exception_object
        disp(exception_object.identifier);
        disp(videotoanalyse);
        videosnotanalysed{end + 1} = videotoanalyse;
        thrownexceptions{end + 1} = exception_object;
        
        prog = filecounter / numfiletoanalyse;
        waitbar(prog,processprog);
        
        analysesprogstring = ['Progress of Analyses: ', num2str(filecounter),'/',num2str(numfiletoanalyse),' Files Done'];
        set(userfeedbackfig,'Name',analysesprogstring);
        continue;
    end
end

timeelapsed = toc;
close(processprog);
close(userfeedbackfig);

averagetime = round((timeelapsed / numfiletoanalyse) * 10000) / 100 ;
frametime = round((timeelapsed / totalnumofframesanalysed) * 10000) / 100;

totalstring = ['Total time elapsed ', num2str(round(timeelapsed * 10000) / 100),' seconds'];
avestring = ['Average time per video ', num2str(averagetime),' seconds'];
framestring = ['Average time per frame ', num2str(frametime),' seconds'];

disp(totalstring);
disp(avestring);
disp(framestring);

if tomakemontage
    getmontageparameters(allstabframes,[],3,0.6,'montagedata.mat',0);
    montageimage = makemontage('montagedata.mat',allstabframes,allstabframes_unfiltered,0.6,0);
    randstring = num2str(min(ceil(rand(1) * 10000),9999));
    montagestring = ['montagedimage_',randstring];
    
    switch formatofstabframe
        case '.jpeg'
            stabimagename = strcat(montagestring,formatofstabframe);
            imwrite(montageimage / 256,stabimagename,'Quality',100);
        case '.tiff'
            stabimagename = strcat(montagestring,'.tiff');
            imwrite(montageimage / 256,stabimagename,'Compression','none');
        case '.gif'
            stabimagename = strcat(montagestring,'.gif');
            imwrite(montageimage / 256,stabimagename);
    end
end

if ~isempty(videosnotanalysed)
    disp('There were errors in the analyses');
    disp('Files That Had Errors: ');
    for errorcounter = 1:length(videosnotanalysed)
        currentexception = thrownexceptions{errorcounter};
        disp(videosnotanalysed{errorcounter});
        disp(currentexception.identifier);
        disp('Matfile throwing the exception: ');
        disp(currentexception.stack(1).file);
        disp('Line of Error: ');
        disp(currentexception.stack(1).line);
    end
end 