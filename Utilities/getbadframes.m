function [goodframesegmentinfo largemovementframes] = getbadframes(videoname,blinkfilename,...
    peakratiothreshold,movementthreshold,verbose)
% getbadframes.m. This is a utility program analyses which frames in the
% video are "good". The definition of "good" frame is that the frame should
% have a good correlation with the frame immediately preceding it and the
% frame movement should be below a certain amount.
% Usage: [goodframesegmentinfo largemovementframes] = getbadframes(videoname,
%        [peakratiothreshold,movementthreshold,verbose]);
% videoname              - The string that is the name of a video/ a 3D
%                          matrix containing a collection of frames. If 
%                          neither type of datatype is supplied the program
%                          will query the user to choose a video.
% peakratiothreshold     - The minimum peak difference in the correlation
%                          between a frame and the the frame immediately
%                          preceding it, that is required for the frame to
%                          be included as a good frame. If the user does not
%                          supply this he will be prompted by a dialog box
% movementthreshold      - The maximum percentage of movement from one frame
%                          to the next that will be tolerated for the frame
%                          to be included as a good frame. Since this is a
%                          percentage threshold, it will mean difference
%                          absolute movements for videos of different size,
%                          for e.g. a 0.01 threshold be a 4.5 pixel
%                          threshold for a framesize of 450 pixels and 6.5
%                          for a framesize of 650 pixels. Again if it is not
%                          supplied the user will be prompted with a dialog
%                          box.
% verbose                - If the user wants a plot of the peakdifferences
%                          obtained from the video with the frames that were
%                          tagged as bad marked verbose should 1. Default is
%                          0.
%
% goodframesegmentinfo   - This matrix a m x 3 matrix, where m is the number
%                          of segments of contiguous good frames in the
%                          video. The first column is the start frame of the
%                          segment, the second column is the end frame of he
%                          segment and the third is the number of frames in
%                          the segment.
% largemovementframes    - The frame numbers that were tagged as "bad" by
%                          the analysis.
%
%
% Program Creator: Girish Kumar


currentdirectory = pwd;

% Error check the input arguments and ask the user for additional input if
% required

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
        error('type ''help getbadframes'' for usage');
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
            error('Type ''help getbadframes'' for usage');
        end
        toloadblinkframedata = 0;
    end
end

cd(currentdirectory);

if (nargin < 3) || isempty(peakratiothreshold)
    togetpeakratiothreshold = 1;
else
    togetpeakratiothreshold = 0;
end

if (nargin < 4) || isempty(movementthreshold)
    togetmovementthreshold = 1;
else
    togetmovementthreshold = 0;
end

if (nargin < 5) || isempty(verbose)
    verbose = 0;
end

if processfullvideo
    vid_obj = VideoReader(videoname); % Get important info of the avifile
    numbervideoframes = round(vid_obj.FrameRate*vid_obj.Duration);
    framewidth = vid_obj.Width; % The width of the video (in pixels)
    frameheight = vid_obj.Height; % The height of the video (in pixels)
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

if togetpeakratiothreshold || togetmovementthreshold
    name = 'Input for getbadframes.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};
    
    if togetpeakratiothreshold
        prompt = {'Normalized Peak Difference Threshold'};
        defaultanswer{end + 1} = num2str(0.15);
    end
    
    if togetmovementthreshold
        prompt{end + 1} = 'Maximum Percentage Movement';
        defaultanswer{end + 1} = num2str(0.1);
    end
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(userresponse)
        if togetpeakratiothreshold
            warning('Using default peak ratio of 0.15');
            peakratiothreshold = 0.15;
        end
        
        if togetmovementthreshold
            warning('Using default maximum movment of 0.1');
            movementthreshold = 0.1;
        end
    else
        index = 1;
        if togetpeakratiothreshold
            if ~isempty(userresponse{index})
                peakratiothreshold = str2double(userresponse{index});
            else
                warning('You have not entered peak ratio threshold,using default of 0.15');
                peakratiothreshold = 0.15;
            end
            index = index + 1;
        end
        
        if togetmovementthreshold
            if ~isempty(userresponse{index})
                movementthreshold = str2double(userresponse{index});
            else
                warning('You have not entered a movement theshold, using default of 0.1'); 
                movementthreshold = 0.1;
            end
        end
    end
end

if peakratiothreshold > 1
    disp('Normalized Peak Difference threshold too high!!');
    warning('Using normalized peak difference of 0.5');
    peakratiothreshold = 0.5;
end
if peakratiothreshold < 0.01
    disp('Normalized Peak Difference threshold too low!!');
    warning('Using normalized peak difference of 0.01');
    peakratiothreshold = 0.01;
end

if movementthreshold > 0.5
    disp('Movement threshold too high!!');
    warning('Using movement threshold of 0.5');
    movementthreshold = 0.5;
end
if movementthreshold < 0.001
    disp('Movement threshold too low!!');
    warning('Using movement threshold of 0.001');
    movementthreshold = 0.001;
end


% Set values for variables that will be used later on  in the program
framenumbers = [1:numbervideoframes]; % Just the range of frame numbers.
% This will be used later on to pick out good and bad frames
usefulframenumbers = setdiff(framenumbers,blinkframes); % The frames that are going to be used
numusefulframes = length(usefulframenumbers); %The number fo useful frames
thumbnailfactor = round(min(1 / movementthreshold,5)); % The factor by which the frames are reduced. Larger
% factors will speed up the process but we then lose resolution on the
% minimum movement that can be detected
maxmovementsize = repmat([framewidth * movementthreshold,frameheight * movementthreshold],...
    numusefulframes,1); % We can calculate the maximum movement that is permissible.

% Allocate memory for the array that will be populated during the main
% program loop
frameshifts = zeros(numbervideoframes,2);
peakratios = zeros(numbervideoframes,1);

% The main program loop. The logic of this program is to correlate adjacent
% frames. If there was a large enough movement that caused a distortion in
% the frame it would reduce the normalized peak difference. Also the
% adjacent frame correlation will give us the extent of interframe motion,
% which can be used to test for our movement threshold

analysisprog = waitbar(0, 'Correlating Thumbnails');
oldposition = get(analysisprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(analysisprog,'Position',newposition);
for framecounter = 2:numusefulframes
    refframeindex = usefulframenumbers(framecounter - 1);
    testframeindex = usefulframenumbers(framecounter);
    
    indexintomatrix = testframeindex;
    if processfullvideo        
        vidObject2 = VideoReader(videoname);
        vidObject2.CurrentTime = (refframeindex-1)*(1/vidObject2.FrameRate);
        refframe = makethumbnail(double(readFrame(vidObject2)),thumbnailfactor,thumbnailfactor);        
        vidObject2.CurrentTime = (testframeindex-1)*(1/vidObject2.FrameRate);
        testframe = makethumbnail(double(readFrame(vidObject2)),thumbnailfactor,thumbnailfactor);
    else
        refframe = makethumbnail(videoname(:,:,refframeindex),thumbnailfactor,thumbnailfactor);
        testframe = makethumbnail(videoname(:,:,testframeindex),thumbnailfactor,thumbnailfactor);
    end
    
    [correlation shifts peaks_noise] = corr2d(refframe,testframe);
    
    frameshifts(indexintomatrix,:) = shifts * thumbnailfactor;
    peakratios(indexintomatrix) = peaks_noise(2) / peaks_noise(1);
    
    waitbar(((framecounter - 1)/ (numusefulframes - 1)),analysisprog)
end

close(analysisprog);

peakratios(usefulframenumbers(1)) = peakratios(usefulframenumbers(2));
diffinpeakratios = diff(peakratios(usefulframenumbers));

% Get the frames that have a motion above our set threshold
isabovemovementthresh = abs(frameshifts(usefulframenumbers,:)) >= maxmovementsize;
frameindicesabovemovementthresh = find(isabovemovementthresh(:,1) | isabovemovementthresh(:,2));

% Get the framesthat have a large enough distortion that reduces the peak
% difference to below the threshold we set
badcorrelframeindices = find(abs(diffinpeakratios) >= peakratiothreshold) + 1;
badcorrelframeindices = badcorrelframeindices(:);


% Now that we have the frames that are most likely
possiblelargemovementframeindices = sort(unique([badcorrelframeindices;frameindicesabovemovementthresh(:)]));
numpossiblelargemovementframes = length(possiblelargemovementframeindices);
frameindicesafterlargemovement = min(possiblelargemovementframeindices + 2,numusefulframes);
frameindicesafterlargemovement = frameindicesafterlargemovement(:);

% Since motion could start int the extremes of frames it is possible that
% frame immediately adjacent to the ones found as "bad" could be "bad" as
% well, so we need to mark these as well just to be on the safe side.
largemovementframeindices = repmat([-1 0 1],numpossiblelargemovementframes,1)...
    + repmat(possiblelargemovementframeindices,1,3);
largemovementframeindices = sort(unique(min(max(largemovementframeindices,1),numusefulframes)));
largemovementframeindices = largemovementframeindices(:);

goodframeindicesforrefanalysis = setdiff([1:numusefulframes]',largemovementframeindices);
frameindicesafterlargemovement = setdiff(frameindicesafterlargemovement,largemovementframeindices);

goodframesforrefanalysis = usefulframenumbers(goodframeindicesforrefanalysis);
largemovementframes = usefulframenumbers(largemovementframeindices);
framesafterlargemovement = usefulframenumbers(frameindicesafterlargemovement);

goodframesforrefanalysis = goodframesforrefanalysis(:);
largemovementframes = largemovementframes(:);
framesafterlargemovement = framesafterlargemovement(:);

% Show the results if required
if verbose
    figure;
    plot(peakratios);
    hold on;
    plot(largemovementframes,peakratios(largemovementframes),'r*');
    hold off;
    title('Peak Ratios');
end


% Divide the video into segments of good frames in case this is required
% for analysis

% First we need to find there is a break in the sequence of "good" frames.
% Each break then defines the end of one segment and the start of the next.
% Of course if there are no breaks we have a lovely video don't we!!.

frameindexdifference = [1;diff(goodframesforrefanalysis(:))];
framebreakpoints = find(frameindexdifference > 1);
framebreakpoints = framebreakpoints(:);

if ~isempty(framebreakpoints)
    segmentstartframes = [goodframesforrefanalysis(1);goodframesforrefanalysis(framebreakpoints)];
    segmentendframes = [goodframesforrefanalysis(framebreakpoints - 1);goodframesforrefanalysis(end)];
else
    segmentstartframes = goodframesforrefanalysis(1);
    segmentendframes = goodframesforrefanalysis(end);
    disp('No Large Movement, Great Video!!');
end

% Now that we have the start and end frame for each segment we can make one
% matrix that holds all the information. The arrangement that we decided
% was a m  X 3 matrix, where m is the number of segments. The first coloumn
% is the start frame, the second column is the end frame, while the third
% column is the number of frames in that segment.
goodframesegmentinfo = [segmentstartframes(:),segmentendframes(:),segmentendframes(:) - segmentstartframes(:) + 1];

% If a video was supplied then save the data into a MAT file.
if toloadblinkframedata
    save(blinkfilename,'largemovementframes','goodframesforrefanalysis',...
        'framesafterlargemovement','goodframesegmentinfo','peakratiothreshold','movementthreshold',...
        'peakratios','frameshifts','maxmovementsize','usefulframenumbers','-append');

    if processfullvideo
        videoname_check = avifilename;
        save(blinkfilename,'videoname_check','-append');
    end
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