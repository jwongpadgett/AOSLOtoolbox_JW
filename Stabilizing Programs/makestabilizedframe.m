function [stabilisedframe,stabilisedframe_full] = ...
    makestabilizedframe(videoname,framestostabilize,frameshifts,peakratios,...
    stripindices,badsamplethreshold,numlinesperfullframe,maxsizeincrement,splineflag,verbose)
% makestabilizedframe.m: This program is designed to make a stabilized average frame from a video/collection of 2D images when given the
% intra and inter frame/image shifts.
%
% Uasge: [stabilisedframe,stabilisedframe_full] = makestabilizedframe(videoname,framestostabilize,frameshifts,peakratios,stripidices,
%                                                               badsamplethreshold,numlinesperfullframe,maxsizeincrement, splineflag,verbose)
%
% videoname                 - A string that contains the full path to video/3D matrix consisting of multiple 2D images. The program will query the user to
%                                   provide a video path and name if this variable is not provided.
% framestostabilize        - The frame numbers/indices in the video whose intra frame shifts are known. Only these frames can be averaged. If a 3D
%                                   matrix of images is provided the program assumes that all the images are too be stabilized.
% frameshifts                - The X x 2 array of the intra-frame shifts. The first column is the horizontal shifts while the second column is the vertical shifts.
%                                 The number of rows in this array i dependant on the sampling rate of the frame shifts extraction as well as the number of frames.
%                                 Positive numbers indicate rightward and downward shifts.
% peakratios                 - A one coulmn array that contains the  metric that is used to determine the accuracy of the intra-frame shift. The array's length
%                                  should be equal to the length of the frameshifts array.
% stripindices                - The indices within each frame that the frameshifts were calculated at.
% badsamplethreshold     - The threshold that demarcates good samples from bad samples. Only if the value in the peakratios array is lower that this threshold
%                                   is the sample considered "good". Default value is 0.65
% numlinesperfullframe    - The raw AOSLO video is typically has more pixel lines that the analysed video, since the pixel lines are par of the mirror flyback are
%                                  not analysed. however when stabilizing the time that is taken for the flyback is required and therefore the user must provide the total
%                                  number of pixels lines are present in the raw video. This should be a value greater than the height of the frame. If the user provides a
%                                  collection of 2D images then this value need not be provided, but instead an empty array should be passed to the program. Default
%                                  value is 525 lines
% maxsizeincrement       - To ensure that the program does not crash due to excessive memory usage, a cap has to be placed on the maximum size of the final
%                                  stabilized frame. This value determines the maximum permissable size in terms of multiples of the frame size. Default value is 4.
% splineflag                  - While calculating the spline of frame shifts, the program gives the user two options. First calculate splines for individual frames and
%                                  second to calculate a spline to fit over all the frames. The first option (flag value of 1) should be used when the individual frames
%                                  are collected far apart in time, as when reference frames are made, while the second option (flag value of 0) should be used when
%                                  the entire video is being sbatilized. Default value is 0.
% verbose                   - If the user want feedback on the stabilizing process, then this flag should be set to 1 otherwise set to 0. Default value is 0.
%
% stabilisedframe          - a X x Y x 3 matrix that is the stabilized average frame that is cropped to include the maximum image data. The first layer is the
%                                 stabilized frame with the non-image pixels filled with the mean pixel value of the pixels that have image data. The second layer is the
%                                 same image but with thenon-image pixels filled with random image data collected from the pixels with data. The last layer has zeros in
%                                 pixels that have no image data.
% stabilisedframe_full     - a XxYx3 matrix that is the stabilized average frame similar to stabilisedframe but not cropped.
%
%
% Note this program alter the seed used by rand.
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War


rand('state',sum(100 * clock));
if ispc
    pathslash = '\';
else
    pathslash = '/';
end
toanalysevideo = 1;

if (nargin < 1) || isempty(videoname)
    [videoname,videofilename,videopath] = getvideoname;
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
        end
    else
        if ~isnumeric(videoname)
            disp('Supplied video name must be a string');
            [videoname,videofilename,videopath] = getvideoname;
        else
            if length(size(videoname)) < 3
                disp('Frame data is not a 3D matrix');
                error('Type ''help makestabilizedframe'' for usage');
            else
                toanalysevideo = 0;
            end
        end
    end
end

errorexitflag = 0;
if (nargin < 2) || isempty(framestostabilize)
    if toanalysevideo
        errorexitflag = 1;
        disp('You have not provided the array that has the frame numbers to stabilize');
    end
end

if (nargin < 3) || isempty(frameshifts)
    errorexitflag = 1;
    disp('You have not provided the intra-frame motion matrix');
end

if (nargin < 4) || isempty(peakratios)
    errorexitflag = 1;
    disp('You have not provided the peak ratio array');
end

if (nargin < 5)  || isempty(stripindices)
    errorexitflag = 1;
    disp('You have not provided the strip index array');
end

if errorexitflag
    error('Type ''help makestabilizedframe'' for usage');
end


if (nargin < 6) || isempty(badsamplethreshold)
    togetbadsamplethreshold = 1;
else
    togetbadsamplethreshold = 0;
end

if ((nargin < 7) || isempty(numlinesperfullframe)) && toanalysevideo
    togetnumlinesperfullframe = 1;
else
    togetnumlinesperfullframe = 0;
end

if (nargin < 8) || (isempty(maxsizeincrement))
    togetmaxsizeincrement = 1;
else
    togetmaxsizeincrement = 0;
end

if (nargin < 9) || (isempty(splineflag))
    togetsplineflag = 1;
else
    togetsplineflag = 0;
end

if (nargin < 10) || (isempty(verbose))
    verbose = 0;
end

if togetbadsamplethreshold || togetnumlinesperfullframe || togetmaxsizeincrement ||...
        togetsplineflag
    name = 'Input for makestabilizedframe.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};
    
    if togetbadsamplethreshold
        prompt = {'Bad Sample Threshold'};
        defaultanswer{end + 1} = num2str(0.65);
    end
    
    if togetnumlinesperfullframe
        prompt{end + 1} = 'Number of Pixel Line in Full Frame';
        defaultanswer{end + 1} = num2str(525);
    end
    
    if togetmaxsizeincrement
        prompt{end + 1} = 'Max. Size Multiplier';
        defaultanswer{end + 1} = num2str(4);
    end
    
    if togetsplineflag
        prompt{end + 1} = 'Type of Spline Calculated';
        defaultanswer{end + 1} = num2str(0);
    end
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(userresponse)
        if togetbadsamplethreshold
            warning('Using default bad sample threshold of 0.65');
            badsamplethreshold = 0.65;
        end
        
        if togetnumlinesperfullframe
            warning('Using default pixel lines of 525');
            numlinesperfullframe = 525;
        end
        
        if togetmaxsizeincrement
            warning('Using default max. size multiplier of 4');
            maxsizeincrement = 4;
        end

        if togetsplineflag
            warning('Calculating spline across all frames');
            splineflag = 0;
        end        
    else
        index = 1;
        if togetbadsamplethreshold
            if ~isempty(userresponse{index})
                badsamplethreshold = str2double(userresponse{index});
            else
                warning('You have not entered bad sample threshold,using default of 0.65');
                badsamplethreshold = 0.65;
            end
            index = index + 1;
        end
        
        if togetnumlinesperfullframe
            if ~isempty(userresponse{index})
                numlinesperfullframe = str2double(userresponse{index});
            else
                warning('You have not entered the no. pixels lines per full frame, using default of 525'); 
                numlinesperfullframe = 525;
            end
            index = index + 1;
        end
        
        if togetmaxsizeincrement
            if ~isempty(userresponse{index})
                maxsizeincrement = str2double(userresponse{index});
            else
                warning('You have not entered the max. size multipler, using default of 4'); 
                maxsizeincrement = 4;
            end
            index = index + 1;
        end
        
        if togetsplineflag
            if ~isempty(userresponse{index})
                splineflag = str2double(userresponse{index});
            else
                warning('You have not entered the type of spline to calculate, using default of 0'); 
                splineflag = 0;
            end
        end
    end
end

if toanalysevideo
    videoinfo = VideoReader(videoname);
    framewidth = videoinfo.Width;
    frameheight = videoinfo.Height;
    videotype = videoinfo.VideoFormat;
    framesizes = [framewidth,frameheight];
    
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
    framesizes = [framewidth,frameheight];
    numlinesperfullframe = frameheight + 1;
    framestostabilize = [1:size(videoname,3)];
end

numframestostabilize = length(framestostabilize);
numsamplesperframe = length(stripindices);
numsamplesintrace = size(frameshifts,1);

if (size(frameshifts,1) ~= size(peakratios,1))
    disp('Shifts and Peakratio matrix sizes are not equal');
    error('Type ''help makestabilizedframe'' for usage');
end

if numlinesperfullframe < frameheight
    disp('Number of lines in full frame cannot be smaller than the number of lines in video frame');
    error('Type ''help makestabilizedframe'' for usage');
end

if ((numsamplesintrace / numsamplesperframe) ~= numframestostabilize)
    disp('Number of frames supplied does not correspond to size of shift matrix');
    error('Type ''help makestabilizedframe'' for usage');
end

numindicestoignore = 5;
indexaddition = [0:numindicestoignore - 1] - floor(numindicestoignore / 2);

badmatches_initial = find(peakratios(:) >= badsamplethreshold);
numinitialbadmatches = length(badmatches_initial);


if (numinitialbadmatches > 0)
    badmatches = repmat(badmatches_initial,1,numindicestoignore) +...
        repmat(indexaddition,numinitialbadmatches,1);
    badmatches = unique(max(min(badmatches(:),numsamplesintrace),1));
else
    badmatches = [];
end

goodmatches = setdiff([1:numsamplesintrace]',badmatches);
if length(goodmatches) == numsamplesintrace
    frameshiftstouse = frameshifts;
else
    frameshiftstouse = zeros(size(frameshifts));
    interp_xaxis = [1:numsamplesintrace];
    sample_xaxis = interp_xaxis(goodmatches);

    for directioncounter = 1:2
        sample_yaxis = frameshifts(goodmatches,directioncounter);
        interp_yaxis = interp1(sample_xaxis,sample_yaxis,interp_xaxis,'linear','extrap');
        frameshiftstouse(:,directioncounter) = interp_yaxis;
    end
end

if max(badmatches(:)) == size(peakratios,1)
    lastgoodsample = max(goodmatches(:));
    for directioncounter = 1:2
        frameshiftstouse(lastgoodsample + 1,directioncounter) =...
            frameshiftstouse(lastgoodsample,directioncounter);
    end
end

if min(badmatches(:)) == 1
    firstgoodsample = min(goodmatches(:));
    for directioncounter = 1:2
        frameshiftstouse(1:firstgoodsample - 1,directioncounter) =...
            frameshiftstouse(firstgoodsample,directioncounter);
    end
end

[sizeincrement,stabilizedsize,imageborders] = getstabilizedparams(frameshiftstouse,framesizes,maxsizeincrement);

sizeincrement = min(sizeincrement,maxsizeincrement);
stabilizedsize = round([framewidth frameheight] * sizeincrement);
imageborders(1) = max(imageborders(1),1);
imageborders(2) = min(imageborders(2),stabilizedsize(1));
imageborders(3) = max(imageborders(3),1);
imageborders(4) = min(imageborders(4),stabilizedsize(2));

splineshiftstouse = zeros(frameheight,numframestostabilize,2);

if numsamplesperframe > 1
    if splineflag
        interp_xaxis = [1:frameheight]';
        sample_xaxis = stripindices;
        firstsample = sample_xaxis(1);
        lastsample = sample_xaxis(end);
        for directioncounter = 1:2
            tempshifts = frameshiftstouse(:,directioncounter);
            sample_yaxis_full(:,:,directioncounter) = reshape(tempshifts,numsamplesperframe,numframestostabilize);
        end
        for framecounter = 1:numframestostabilize
            for directioncounter = 1:2
                sample_yaxis = sample_yaxis_full(:,framecounter,directioncounter);
                interp_yaxis = interp1(sample_xaxis,sample_yaxis,interp_xaxis,'linear','extrap');
                interp_yaxis(1:firstsample - 1) = interp_yaxis(firstsample);
                interp_yaxis(lastsample + 1:end) = interp_yaxis(lastsample);
                splineshiftstouse(:,framecounter,directioncounter) = interp_yaxis * -1.0;
            end
        end
    else
        interp_xaxis = [0:(numlinesperfullframe * numframestostabilize) - 1];
        interp_xaxis = reshape(interp_xaxis,numlinesperfullframe,numframestostabilize);
        sample_axis = interp_xaxis(stripindices,:);

        interp_xaxis = interp_xaxis(1:frameheight,:);
        interp_xaxis = interp_xaxis(:);
        sample_xaxis = sample_axis(:);
        interp_xaxis = min(interp_xaxis,max(sample_xaxis));

        for directioncounter = 1:2
            sample_yaxis = frameshiftstouse(:,directioncounter);
            interp_yaxis = interp1(sample_xaxis,sample_yaxis,interp_xaxis,'linear','extrap');
            splineshiftstouse(:,:,directioncounter) = ...
                reshape(interp_yaxis,frameheight,numframestostabilize) * -1.0;
        end
    end
    numinitalindices = stripindices(1) - 1;
    numlastindices = frameheight - stripindices(end);
    splineshiftstouse(1:(stripindices(1) - 1),1,:) =...
        repmat(splineshiftstouse(stripindices(1),1,:),[numinitalindices 1 1]);
    splineshiftstouse((stripindices(end) + 1):frameheight,numframestostabilize,:) =...
        repmat(splineshiftstouse(stripindices(end),numframestostabilize,:),[numlastindices 1 1]);
else
    for directioncounter = 1:2
        tempshifts = frameshiftstouse(:,directioncounter) * -1.0;
        splineshiftstouse(:,:,directioncounter) = repmat(tempshifts(:)',frameheight,1);
    end
end

stabilisedframe = zeros(stabilizedsize(2),stabilizedsize(1));
sumstabilisedframe = zeros(stabilizedsize(2),stabilizedsize(1));

columnaddition = ceil((stabilizedsize(1) - framewidth) / 2) + [0:framewidth - 1];
rowaddition = ceil((stabilizedsize(2) - frameheight) / 2);
sumrow = ones(1,framewidth);
summatrix = ones(frameheight,framewidth);

if verbose
    mymap = repmat([0:255]' / 256,1,3);
    stabfighandle = figure;
    stabimghandle = image(stabilisedframe);
    colormap(mymap);
    truesize;
    
    set(stabimghandle,'erasemode','none');
    stabimgtitlehandle = title('Stabilized Image');
    
    namestring = ['Stabilized Figure: 0 frames done, ',num2str(numframestostabilize),...
        ' frames to go'];
    set(stabfighandle,'Name',namestring);
end

stabprog = waitbar(0,'Making a Stabilised Frame');
oldwaitbarposition = get(stabprog,'Position');
newstartindex = round(oldwaitbarposition(1) + (oldwaitbarposition(3) / 2));
newwaitbarposition = [newstartindex,((2 * oldwaitbarposition(4)) + 50),...
    oldwaitbarposition(3),oldwaitbarposition(4)];
set(stabprog,'Position',newwaitbarposition);

vidObj = VideoReader(videoname);    
for framecounter = 1:numframestostabilize
    framenumbertoadd = framestostabilize(framecounter);
    
    if toanalysevideo        
        vidObj.CurrentTime = (framenumbertoadd-1)*(1/vidObj.FrameRate);
        frametoadd = double(readFrame(vidObj));
        
        if istruecolor
            frametoadd = frametoadd(:,:,1);
        end
    else
        frametoadd = videoname(:,:,framenumbertoadd);
    end
    
    frameshifttouse = squeeze(splineshiftstouse(:,framecounter,:));
    
    for rowcounter = 1:frameheight
        rowtoadd = frametoadd(rowcounter,:);
        shifttouse = round(frameshifttouse(rowcounter,:));

        targetcolumns = round(columnaddition + shifttouse(1));
        targetcolumns = max(targetcolumns,1);
        targetcolumns = min(targetcolumns,stabilizedsize(1));

        targetrow = round(rowaddition + shifttouse(2)) + rowcounter - 1;
        targetrow = max(targetrow,1);
        targetrow = min(targetrow,stabilizedsize(2));

        stabilisedframe(targetrow,targetcolumns) = ...
            stabilisedframe(targetrow,targetcolumns) + rowtoadd;
        sumstabilisedframe(targetrow,targetcolumns) = ...
            sumstabilisedframe(targetrow,targetcolumns) + sumrow;
    end
    
    if verbose
        tempimage = stabilisedframe;
        tempsumimage = sumstabilisedframe;
        indiceswithimagedata = find(tempsumimage >= 1);
        tempimage(indiceswithimagedata) = tempimage(indiceswithimagedata) ./...
            tempsumimage(indiceswithimagedata);
        
        remainingframes = numframestostabilize - framecounter;
        namestring = ['Stabilized Figure: ',num2str(framecounter),' frames done, ',...
            num2str(remainingframes),' frames to go'];
        set(stabfighandle,'Name',namestring);
        set(stabimghandle,'cdata',tempimage);
        title(['Current Frame Number: ',num2str(framenumbertoadd)]);
    end 
    
    prog = framecounter / numframestostabilize;
    waitbar(prog,stabprog);
end

close(stabprog);

if verbose
    close(stabfighandle);
end

indiceswithimagedata = find(sumstabilisedframe >= 1);
indiceswithnoimagedata = find(sumstabilisedframe < 1);

sumstabilisedframe(indiceswithnoimagedata) = 1;

stabilisedframe = stabilisedframe ./ sumstabilisedframe;

stabilisedframe_withmeanval = stabilisedframe;
stabilisedframe_withmeanval(indiceswithnoimagedata) = mean(stabilisedframe(indiceswithimagedata));

stabilisedframe_withrandvals = stabilisedframe;
randpixelindices = floor(rand(length(indiceswithnoimagedata),1) * length(indiceswithimagedata)) + 1;
randpixelvalues = stabilisedframe(indiceswithimagedata(randpixelindices));
stabilisedframe_withrandvals(indiceswithnoimagedata) = randpixelvalues;

stabilisedframe_withzerovals = stabilisedframe;
stabilisedframe_withzerovals(indiceswithnoimagedata) = 0;

stabilisedframe_full = cat(3,stabilisedframe_withmeanval,stabilisedframe_withrandvals,...
    stabilisedframe_withzerovals);
stabilisedframe = stabilisedframe_full(imageborders(3):imageborders(4),imageborders(1):imageborders(2),:);


%--------------------------------------------------------------------------
function [fullvideoname,videofilename,videopath] = getvideoname()

[videofilename,videopath] = uigetfile('*.avi','Please enter filename of video to analyse');
if videofilename == 0
    disp('No video to filter,stoping program');
    error('Type ''help makestabilizedframe'' for usage');
end
cd(videopath);
fullvideoname = strcat(videopath,videofilename);
%--------------------------------------------------------------------------