function [datafilename,referenceimage] = makereference_manual(videoname,badframefilename,frameincrement,...
    badcorrelthreshold,verbose)
% makereference_manual.m. This program is designed to create a reference image. The program conducts a cross-correlation
% of thumbnails of frames and then allows the user to manually correct the correlation.
%
% Usage: [datafilename,referenceimage] = makereference_manual(videoname,badframefilename,frameincrement,badcorrelthreshold,verbose)
% videoname                 - A string that contains the full path to video/3D matrix consisting of multiple 2D images. The
%                                  program will query the user to provide a video path and name if this variable is not provided.
% badframefilename        - A string that contains the full path to a mat file that contains bad frame infomation in a format that is the same
%                                  as created by getbadframes.m/a one column array containing the "good" frames all of which that can be used to
%                                  create a referenceimage.
% frameincrement           - If a matfile is passed as the second input argument, then only a subset of "good" frames will be used to create
%                                    a reference image. If this is the case then the number of frames that are skipped needs to be passed to the program.
%                                    If a numeric array is passed then this argument is ignored.
% badcorrelthreshold       - A metric is needed to determine if the automatic cross-correlation has returned a accurate result. The current metric
%                                   we use the ratio between the second and first peaks of the cross-correlation function. The smaller this ratio, the more
%                                   confident we are about the accuracy of the returned values.
% verbose                     - If this flag is set to 1, then the program draws the image of the reference image created using the analyses.
%
% datafilename              - The name of the matfile into which the reference image and related data are written into.
% referenceimage           - The reference image created after the analyses. The reference image is a cropped image that has the maximum image data.
%                                   Pixels that have no information are filled with randomly pixel information taken from those pixels that have information.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

rand('state',sum(100 * clock));

currentdirectory = pwd;

toanalysevideo = 1;
if (nargin < 1) || isempty(videoname)
    [videoname,videofilename,videopath] = getvideoname;
else
    if ischar(videoname)
        if exist(videoname,'file')
            maxslashindex = 0;
            for charcounter = 1:length(videoname)
                testvariable = strcmp(videoname(charcounter),'\');
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
        end
    else
        if ~isnumeric(videoname)
            disp('Supplied video name must be a string');
            [videoname,videofilename,videopath] = getvideoname;
        else
            if length(size(videoname)) < 3
                disp('Frame data is not a 3D matrix');
                error('Type ''help makereference_manual'' for help');
            else
                toanalysevideo = 0;
            end
        end
    end
end


if (nargin < 3) || isempty(badframefilename)
    badframefilename = getbadframefilename(currentdirectory);
    toloadframenumbers = 1;
else
    if ischar(badframefilename)
        if exist(badframefilename,'file')
            toloadframenumbers = 1;
        else
            disp('Third input string does point to a valid mat file');
            badframefilename = getbadframefilename(currentdirectory);
            toloadframenumbers = 1;
        end
    else
        if isnumeric(badframefilename)
            toloadframenumbers = 0;
        else
            disp('Third input argument must be either a string or numeric array');
            badframefilename = getbadframefilename(currentdirectory);
            toloadframenumbers = 1;
        end
    end
end

if ((nargin < 3) || isempty(frameincrement)) && toloadframenumbers
    togetframeincrement = 1;
else
    togetframeincrement = 0;
end

if (nargin < 4) || isempty(badcorrelthreshold)
    togetbadcorrelthreshold = 1;
else
    togetbadcorrelthreshold = 0;
end

if (nargin < 5) || isempty(verbose)
    verbose = 0;
end

if togetframeincrement || togetbadcorrelthreshold
    name = 'Input for makereference_manual.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};

    if togetframeincrement
        prompt = {'Frame Increment'};
        defaultanswer{end + 1} = num2str(15);
    end

    if togetbadcorrelthreshold
        prompt{end + 1} = 'Bad Correlation Threshold';
        defaultanswer{end + 1} = num2str(0.65);
    end

    userresponse = inputdlg(prompt,name,numlines,defaultanswer);

    if isempty(userresponse)
        if togetframeincrement
            warning('Using default frame increment of 15');
            frameincrement = 15;
        end

        if togetbadcorrelthreshold
            warning('Using bad correlation threshold of 0.65');
            badcorrelthreshold = 0.65;
        end
    else
        index = 1;
        if togetframeincrement
            if ~isempty(userresponse{index})
                frameincrement = str2double(userresponse{index});
            else
                warning('You have not entered frame increment,using default of 15');
                frameincrement = 15;
            end
            index = index + 1;
        end

        if togetbadcorrelthreshold
            if ~isempty(userresponse{index})
                badcorrelthreshold = str2double(userresponse{index});
            else
                warning('You have not entered a theshold to indicate  bad correlation, using default of 0.65');
                badcorrelthreshold = 0.65;
            end
        end
    end
end

if toanalysevideo
    videoinfo = VideoReader(videoname); % Get important info of the avifile
    numbervideoframes = round(videoinfo.FrameRate*video.Duration);
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
else
    framewidth = size(videoname,2); % The width of the video (in pixels)
    frameheight = size(videoname,1); % The height of the video (in pixels)
    numbervideoframes = size(videoname,3);
end

if frameincrement <= 4
    disp('Frame increment is too low, increasing to 5');
    frameincrement = 5;
end
if frameincrement > (numbervideoframes / 5)
    disp('Frame increment is too high, Reducing to 1/5th number of video frames');
    frameincrement = (numbervideoframes / 5);
end
    
if toloadframenumbers
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
    
    if toanalysevideo
        if ((exist('videoname_check','var')) && isempty(videoname_check) ||...
                (strcmp(videoname_check,videofilename) == 0))%#ok<NODEF>
            disp('Problem with video name in bad frame MAT file')
            warning('Bad frame info was obtained from different video / Video info was in matlab data file is empty');
        end
    end
    if isempty(goodframesforrefanalysis)
        disp('Problem with good frame info');
        error('MATLAB data file does not have any good frame info');
    end

    framesforreference_indices = [1:frameincrement:length(goodframesforrefanalysis)];
    framesforreference = goodframesforrefanalysis(framesforreference_indices);
else
    framesforreference = unique(min(max(sort(badframefilename(:),'ascend'),1),numbervideoframes));
end

cd(currentdirectory);

numframesforreference = length(framesforreference);
thumbnailfactor = 5;
maxsizeincrement = 3;
stabsplineflag = 1;
stabverbose = 0;
stripidx = floor(frameheight / 2) + 1;

isgoodthumbnailmatch = ones(numframesforreference,1);
frameshifts_thumbnails = zeros(numframesforreference,2);
frameshifts_thumbnails_actual = zeros(numframesforreference,2);
peakratios_thumbnails = ones(numframesforreference,1);
maxvals_thumbnails = ones(numframesforreference,1);
secondpeaks_thumbnails = ones(numframesforreference,1);
noises_thumbnails = ones(numframesforreference,1);

isgoodmatch = ones(numframesforreference,1);
frameshifts = zeros(numframesforreference,2);
peakratios = ones(numframesforreference,1) * (badcorrelthreshold / 2);

if toanalysevideo
    videoinfo.CurrentTime = (framesforreference(1)-1)*(1/videoinfo.FrameRate);
    prevframe = double(frame2im(readFrame(videoinfo))) / 256;    
else
    prevframe = videoname(:,:,framesforreference(1)) / 256;
end
prevframe = cat(3,prevframe,zeros(size(prevframe)),prevframe);

framefigurehandle = figure;
frameimagehandle = image(prevframe);
frameaxishandle = gca;
frametitlehandle = get(frameaxishandle,'Title');
axis off;
truesize;

set(framefigurehandle,'WindowButtonDownFcn',@buttonpress,'UserData',[]);
set(frameimagehandle,'Erasemode','none');

figureposition = get(framefigurehandle,'Position');
middleoffig = mean(cumsum(reshape(figureposition,2,2),2),2)';
set(0,'PointerLocation',middleoffig);
set(framefigurehandle,'UserData',[0,0]);

baseindices_x = [1:framewidth];
baseindices_y = [1:frameheight];

for framecounter = 2:numframesforreference
    toexit = 0;
    indexaddtion = [0 0];
    set(0,'PointerLocation',middleoffig);
    set(framefigurehandle,'UserData',[0,0]);

    currframenumbertoimage = framesforreference(framecounter);
    prevframenumbertoimage = framesforreference(framecounter - 1);
    
    if toanalysevideo
        videoinfo.CurrentTime = (currframenumbertoimage-1)*(1/videoinfo.FrameRate);
        currframetoimage = scale(double(frame2im(readFrame(videoinfo))));
        videoinfo.CurrentTime = (prevframenumbertoimage-1)*(1/videoinfo.FrameRate);
        prevframetoimage = scale(double(frame2im(readFrame(videoinfo))));
        
        if istruecolor
            currframetoimage = currframetoimage(:,:,1);
            prevframetoimage = prevframetoimage(:,:,1);
        end
    else
        currframetoimage = scale(videoname(:,:,currframenumbertoimage));
        prevframetoimage = scale(videoname(:,:,prevframenumbertoimage));
    end
    
    currframetoimage_thumbnail = makethumbnail(currframetoimage,thumbnailfactor,thumbnailfactor);
    prevframetoimage_thumbnail = makethumbnail(prevframetoimage,thumbnailfactor,thumbnailfactor);

    [correlation thumbnailshifts thumbnailpeaks_noise] = corr2d(prevframetoimage_thumbnail,currframetoimage_thumbnail);

    peakratio = thumbnailpeaks_noise(2) / thumbnailpeaks_noise(1);
    
    frameshifts_thumbnails_actual(framecounter,:) = thumbnailshifts * thumbnailfactor;
    frameshifts_thumbnails(framecounter,:) = [0 0];
    peakratios_thumbnails(framecounter) = peakratio;
    maxvals_thumbnails(framecounter) = thumbnailpeaks_noise(1);
    secondpeaks_thumbnails(framecounter) = thumbnailpeaks_noise(2);
    noises_thumbnails(framecounter) = thumbnailpeaks_noise(3);
    isgoodthumbnailmatch(framecounter) = peakratio < badcorrelthreshold;
    
    indicestoputtestimage_x = round(min(max(baseindices_x,1),framewidth));
    indicestoputtestimage_y = round(min(max(baseindices_y,1),frameheight));

%     indicestoputtestimage_x = round(min(max(baseindices_x - (thumbnailshifts(1) * thumbnailfactor),1),framewidth));
%     indicestoputtestimage_y = round(min(max(baseindices_y - (thumbnailshifts(2) * thumbnailfactor),1),frameheight));

    baseframe = cat(3,prevframetoimage,zeros(size(prevframetoimage)),zeros(size(prevframetoimage)));
    imagetitle = ['Reference Frame: ',num2str(prevframenumbertoimage),' Test Frame: ',...
        num2str(currframenumbertoimage)];

    imagetoshow = baseframe;
    imagetoshow(indicestoputtestimage_y,indicestoputtestimage_x,2:3) = repmat(currframetoimage,[1 1 2]);
    
    set(frametitlehandle,'String',imagetitle);
    set(frameimagehandle,'CData',imagetoshow);
    drawnow;

    while ~toexit
        datafromfig = get(framefigurehandle,'UserData');
        currentmouseloc = get(0,'PointerLocation');

        exitflags = datafromfig;
        indexaddition = round(currentmouseloc - middleoffig);

        indicestoputimage_x = min(max(indicestoputtestimage_x + indexaddition(1),1),framewidth);
        indicestoputimage_y = min(max(indicestoputtestimage_y - indexaddition(2),1),frameheight);

        imagetoshow = baseframe;
        imagetoshow(indicestoputimage_y,indicestoputimage_x,2:3) = repmat(currframetoimage,[1 1 2]);

        set(frameimagehandle,'CData',imagetoshow);
        drawnow;

        if exitflags(1) == 1
            toexit = 1;
        end
    end
    frameshifts(framecounter,:) = frameshifts_thumbnails(framecounter,:) + [indexaddition(1),indexaddition(2)];
    
end

close(framefigurehandle);

[referencematrix,referencematrix_full] = ...
    makestabilizedframe(videoname,framesforreference,frameshifts,peakratios,...
    stripidx,badcorrelthreshold,frameheight,maxsizeincrement,stabsplineflag,stabverbose);

referenceimage = referencematrix(:,:,2);
analysedframes = framesforreference;

randstring = num2str(min(ceil(rand(1) * 10000),9999));
fullstring = strcat('_manualrefdata_',num2str(frameincrement),'_',randstring,'.mat');
if toanalysevideo
    datafilename = strcat(videoname(1:end - 4),fullstring);
else
    datafilename = fullstring(2:end);
end

save(datafilename,'referenceimage','referencematrix','referencematrix_full',...
    'analysedframes','isgoodthumbnailmatch','frameshifts_thumbnails','peakratios_thumbnails',...
    'maxvals_thumbnails','secondpeaks_thumbnails','noises_thumbnails','frameshifts',...
    'frameincrement','badcorrelthreshold');

if verbose
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
function buttonpress(src,eventdata) %#ok<INUSD>

datafromfig = get(src,'UserData');
exitflags = [0,0];

if strcmp(get(src,'SelectionType'),'normal')
    exitflags = [1 1];
else
    if strcmp(get(src,'SelectionType'),'alt')
        exitflags = [1 -1];
    end
end

datatoputinfig = exitflags;

set(src,'UserData',datatoputinfig);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help makereference_manual'' for usage');
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
    error('Type ''help getbadframes'' for usage');
else
    filename = strcat(pname,fname);
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix / max(newmatrix(:));
%--------------------------------------------------------------------------