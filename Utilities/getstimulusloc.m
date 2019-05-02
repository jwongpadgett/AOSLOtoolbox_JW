function [stimuluslocs varargout] = getstimulusloc(aviname,datafilename,threshold,minimumsize,polarity,numlinesperfullframe)
% Need to edit getstimulusloc.m. This is a utility program designed to find the location of a quadrangle stimulus that is darker than the rest of the video frame.
%
% Usage: [stimuluslocs stimthreshold stimminsize stimsizes frameswithstim] = getstimulusloc(aviname,datafilename,[threshold,minimumsize]);
%
% aviname           - The name of the video that needs to be analysed. If a string is not supplied then the program queries the user with a
%                         dialog box to choose a video. The user can also supply a 3D matrix of the frame data.
% datafilename      - The name of the file that has the blinkframes. The user can also supply a double array that has the frame numbers of the
%                           blink frames
% stimthreshold     - The threshold that demarks the pixels that are present in the stimulus and the pixels in the rest of the frame. If the threshold
%                          is not supplied then a figure window with the first frame is displayed with a threshold of 30 applied is displayed. The user can
%                          then interactive alter the thresold until he is satisfied that the threshold is adequate to properly demark the stimulus
% miniumsize        - The minimum size of the stimulus. Default - 10 pixels.
%
% stimuluslocs      - A m x 3 matrix that has the locations of the stimulus. m being the number of frames. The first column is the horizontal location
%                         of the stimulus. The second column is the vertical location. The third column is the temporal location of the stimulus. This mean
%                         that the number of lines.
% stimthreshold     - The threshold that was used by the program.
% stimminsize       - The minimum size of the stimulus
% stimsizes          - The size of the stimulus in each each frame. The first column is the horizontal size while the second column is the vertical size.
% frameswithstim    - The numbers of the frames that have analysed stimulus.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War
                     

currentdir = pwd;

if nargin < 5 || isempty(polarity)
    polarity = 1;
end

if nargin < 4 || isempty(minimumsize)
    minimumsize = 10;
end
    
if nargin < 1 || isempty(aviname)
[avifilename avipathname] = uigetfile('*.avi','Please enter name of video to analyse');
    if avifilename == 0
        disp('No video to analyse,stoping program');
        error('Type ''help getstimulusloc'' for usage');
    end
    cd(avipathname);
    aviname = strcat(avipathname,avifilename);
else
    if ischar(aviname)
        if ~exist(aviname,'file')
            warning('Video name does not point to a valid file');
            [avifilename avipathname] = uigetfile('*.avi','Please enter filename of video to analyse');
            if avifilename == 0
                disp('No video to analyse,stoping program');
                error('Type ''help getstimulusloc'' for usage');
            end
            aviname = strcat(avipathname,avifilename);
        else
            maxslashindex = 0;
            for charcounter = 1:length(aviname)
                testvariable = strcmp(aviname(charcounter),'\');
                if testvariable
                    maxslashindex = charcounter;
                end
            end
            avifilename = aviname(maxslashindex + 1:end);
        end
    end
end    

if (nargin >= 1) && ~ischar(aviname)
    processfullvideo = 0;
    if (size(aviname,1) < 2) || (size(aviname,2) < 2) || (length(size(aviname)) > 3)
        disp('Provide a video name or a 3 dimensional array of frames');
        error('type ''help getstimulusloc'' for usage');
    end
    aviwidth = size(aviname,2);
    aviheight = size(aviname,1);
    numframes = size(aviname,3);
else
    processfullvideo = 1;
    videoinfo = VideoReader(videoname);
    aviwidth = videoinfo.Width;
    aviheight = videoinfo.Height;
    framerate = round(videoinfo.FrameRate);
    numframes = round(videoinfo.FrameRate*videoinfo.Duration);
end

xcenter = floor(aviwidth / 2) + 1;
ycenter = floor(aviheight / 2) + 1;
framenumbers = [1:numframes]';
maximumpixelsabovethresh = 5;

if nargin < 2 || isempty(datafilename)
    [fname pname] = uigetfile('*.mat','Please enter file name of matfiles with blinkframes');
    if fname == 0
       disp('No blink frames,stopping program');
        error('Type ''help getstimulusloc'' for usage');
    end
    datafilename = strcat(pname,fname);
    load(datafilename,'blinkframes');
end

if (nargin >= 2) && ischar(datafilename)
    if ~exist(datafilename,'file')
        warning('Second input string does not point to a valid mat file');
        [fname pname] = uigetfile('*.mat','Please enter the matfile with the blink frame data');
        if fname == 0
            cd(currentdirectory);
            disp('Need reference data,stopping program');
            error('Type ''help getstimulusloc'' for usage');
        else
            datafilename = strcat(pname,fname);
            load(datafilename,'blinkframes');
        end
    else
        load(datafilename,'blinkframes');
    end
end

if ~ischar(datafilename)
    blinkframes = datafilename;
end

framewithnostim = blinkframes(:);

if nargin < 3 || isempty(threshold)
    prompt = {'Threshold'};
    name = 'Input for Threshold';
    numlines = 1;
    defaultanswer={'30'};
    videoinfo = VideoReader(aviname);
    videoinfo.CurrentTime = (numframes-1)*(1/videoinfo.FrameRate);
    testframe = double(readFrame(videoinfo));
    tocontinue = 0;
    doneonce = 0;

    threshold = 30;
    
    switch polarity
        case 1
            testframe_thresholded = testframe >= threshold;
        case -1
            testframe_thresholded = testframe <= threshold;
    end
    framefigure = figure;
    imagesc(testframe)
    colormap(gray(256));
    axis off;

    threshfigure = figure;
    imagesc(testframe_thresholded)
    colormap(gray(256));
    axis off;
    title('Press Any Key to Continue');
    pause
    title('');

    while ~tocontinue
        thresh = inputdlg(prompt,name,numlines,defaultanswer);
        if isempty(thresh) && doneonce
            tocontinue = 1;
        end
        if ~isempty(thresh)
            threshold = str2num(thresh{1}); %#ok<ST2NM>
            switch polarity
                case 1
                    testframe_thresholded = testframe >= threshold;
                case -1
                    testframe_thresholded = testframe <= threshold;
            end
            figure(threshfigure);
            imagesc(testframe_thresholded)
            colormap(gray(256));
            axis off;
            doneonce = 1;
            defaultanswer= {num2str(threshold)};
        end
    end

    close(framefigure);
    close(threshfigure);
end

locationaddition = [0:minimumsize - 1] - floor(minimumsize / 2);
numlinesperfullframe = 525;

stimuluslocs = zeros(numframes,3);

hsizes = zeros(numframes,1);
vsizes = zeros(numframes,1);

cd(currentdir);

stiminatleastoneframe = 0;

analysisprog = waitbar(0,'Stimulus Analysis');

for framecounter = 1:numframes
    if ~isempty(find(blinkframes == framecounter)) %#ok<EFIND>
        continue;
    end
    
    if processfullvideo
        vidObj = VideoReader(aviname);
        vidObj.CurrentTime = (framecounter-1)*(1/vidObj.FrameRate);
        tempframe = double(readFrame(vidObj));
    else
        tempframe = aviname(:,:,framecounter);
    end
    
    switch polarity
        case 1
            tempframe_thresholded = tempframe >= threshold;
        case -1
            tempframe_thresholded = tempframe <= threshold;
    end
    sumofpixels = sum(tempframe_thresholded(:));
    if sumofpixels < ((minimumsize ^ 2) - 5)
        framewithnostim = [framewithnostim;framecounter];
        continue
    end
    
%     if (framecounter > 1) && stiminatleastoneframe
%         possiblelocation_h = round(stimuluslocs(framecounter - 1,1)) + locationaddition + xcenter;
%         possiblelocation_h = max(possiblelocation_h,1);
%         possiblelocation_h = min(possiblelocation_h,aviwidth);
%         
%         possiblelocation_v = round(stimuluslocs(framecounter - 1,2)) + locationaddition + ycenter;
%         possiblelocation_v = max(possiblelocation_v,1);
%         possiblelocation_v = min(possiblelocation_v,aviheight);        
%         
%         sumofpixelsatloc = sum(tempframe_thresholded(possiblelocation_v,possiblelocation_h));
%         sumofpixelsatloc = sum(sumofpixelsatloc(:));
%         if (sumofpixelsatloc >= (minimumsize .^ 2) - 3) & (sumofpixelsatloc <= (minimumsize .^ 2) + 3)
%             ycoord = stimuluslocs(framecounter - 1,2) + ycenter;
%             stimtime = ((framecounter - 1) * numlinesperfullframe) + ycoord;
%             stimuluslocs(framecounter,:) = [stimuluslocs(framecounter - 1,1:2),stimtime];
%             vsizes(framecounter) = vsizes(framecounter - 1);
%             hsizes(framecounter) = hsizes(framecounter - 1);
%             prog = framecounter/numframes;
%             waitbar(prog,analysisprog);
%             continue
%         end
%     end
    
    rowsums = sum(tempframe_thresholded,2);
    possiblelocs = find(rowsums >= minimumsize);
    if isempty(possiblelocs)
        framewithnostim = [framewithnostim;framecounter];
        continue
    end
    
    lengthofbreaks_all = diff([possiblelocs(1);possiblelocs(:)]);
    breakpoints = find(lengthofbreaks_all > 1);
    lengthofbreaks = lengthofbreaks_all(breakpoints);
    tooshortbreaks = find(lengthofbreaks <= 2);
    if ~isempty(tooshortbreaks)
        tempindices = [];
        for indexcounter = 1:length(tooshortbreaks)
            startindex = possiblelocs(max(tooshortbreaks(indexcounter) - 1,1));
            endindex = possiblelocs(tooshortbreaks(indexcounter));
            tempindices = [tempindices;[startindex:endindex]'];
        end
        possiblelocs = [possiblelocs(:);tempindices];
    end
    
    possiblelocs = unique(possiblelocs);
    if sum(diff(possiblelocs)) == (length(possiblelocs) - 1)
        rownumbers = possiblelocs;
    else
        switch length(breakpoints)
            case 1
                if breakpoints > (length(possiblelocs) / 2)
                    rownumbers = possiblelocs(1:breakpoints - 1);
                else
                    rownumbers = possiblelocs(breakpoints:end);
                end
            otherwise
                if min(breakpoints) ~= 1
                    contiguousindices_startindices = [1;breakpoints];
                else
                    contiguousindices_startindices = [breakpoints];
                end
                contiguousindices_endindices = [breakpoints - 1;length(possiblelocs)];
%                 if max(breakpoints) ~= length(possiblelocs)
%                     contiguousindices_endindices = [breakpoints - 1;length(possiblelocs)];
%                 else
%                     contiguousindices_endindices = [breakpoints - 1];
%                 end
                contiguousindices_length = contiguousindices_endindices -...
                    contiguousindices_startindices + 1;
                max_contiguousindices_length_index = find(contiguousindices_length ==...
                    max(contiguousindices_length(:)));
                rownumbers = [possiblelocs(contiguousindices_startindices(max_contiguousindices_length_index)):...
                    possiblelocs(contiguousindices_endindices(max_contiguousindices_length_index))];
                rownumbers = unique(max(min(rownumbers,aviheight),1));
                
%                 if breakpoints(end) ~= length(possiblelocs)
%                     breakpoints = [breakpoints;length(possiblelocs) - breakpoints(end)];
%                 end
%                 contiguouslengths = diff(breakpoints);
%                 maxcontiguouslength_index = find(contiguouslengths == max(contiguouslengths));
%                 rownumbers = unique(max([possiblelocs(contiguousindices_startindices):...
%                     possiblelocs(contiguousindices_endindices)],1));
%                 rownumbers = unique(min(rownumbers,aviheight));
        end
    end
    
    vsizes(framecounter) = rownumbers(end) - rownumbers(1) + 1;

    ycoord = (rownumbers(1) + rownumbers(end)) / 2;

    colsums = sum(tempframe_thresholded,1);
    possiblelocs = find(colsums >= minimumsize);
    if isempty(possiblelocs)
        framewithnostim = [framewithnostim;framecounter];
        continue
    end

    lengthofbreaks_all = diff([possiblelocs(1);possiblelocs(:)]);
    breakpoints = find(lengthofbreaks_all > 1);
    lengthofbreaks = lengthofbreaks_all(breakpoints); %#ok<FNDSB>
    tooshortbreaks = find(lengthofbreaks <= 2);
    if ~isempty(tooshortbreaks)
        tempindices = [];
        for indexcounter = 1:length(tooshortbreaks)
            startindex = possiblelocs(max(tooshortbreaks(indexcounter) - 1,1));
            endindex = possiblelocs(tooshortbreaks(indexcounter));
            tempindices = [tempindices;[startindex:endindex]'];
        end
        possiblelocs = [possiblelocs(:);tempindices];
    end
    possiblelocs = unique(possiblelocs);
       
    if sum(diff(possiblelocs)) == (length(possiblelocs) - 1)
        colnumbers = possiblelocs;
    else
        breakpoints = find([1;diff(possiblelocs(:))] > 1);
        switch length(breakpoints)
            case 1
                if breakpoints > (length(possiblelocs) / 2)
                    colnumbers = possiblelocs(1:breakpoints - 1);
                else
                    colnumbers = possiblelocs(breakpoints:end);
                end
            otherwise
                if min(breakpoints) ~= 1
                    contiguousindices_startindices = [1;breakpoints];
                else
                    contiguousindices_startindices = breakpoints;
                end
                contiguousindices_endindices = [breakpoints - 1;length(possiblelocs)];
                contiguousindices_length = contiguousindices_endindices -...
                    contiguousindices_startindices + 1;
                contiguousindices_length = contiguousindices_endindices -...
                    contiguousindices_startindices + 1;
                max_contiguousindices_length_index = find(contiguousindices_length ==...
                    max(contiguousindices_length(:)));
                colnumbers = [possiblelocs(contiguousindices_startindices(max_contiguousindices_length_index)):...
                    possiblelocs(contiguousindices_endindices(max_contiguousindices_length_index))];
                colnumbers = unique(max(min(colnumbers,aviheight),1));
                
%                 if breakpoints(end) ~= length(possiblelocs)
%                     breakpoints = [breakpoints;length(possiblelocs) - breakpoints(end)];
%                 end
%                 contiguouslengths = diff(breakpoints);
%                 maxcontiguouslength_index = find(contiguouslengths == max(contiguouslengths));
%                 colnumbers = unique(max([possiblelocs(contiguousindices_startindices):...
%                     possiblelocs(contiguousindices_endindices)],1));
%                 colnumbers = unique(min(colnumbers,aviwidth));
        end
    end
       
    hsizes(framecounter) = colnumbers(end) - colnumbers(1) + 1;
    
    xcoord = (colnumbers(1) + colnumbers(end)) / 2 - xcenter;
    stimtime = ((framecounter - 1) * numlinesperfullframe) + ycoord;
    ycoord = ycoord - ycenter;
    stimuluslocs(framecounter,:) = [xcoord,ycoord,stimtime];
    stiminatleastoneframe = 1;

    prog = framecounter/numframes;
    waitbar(prog,analysisprog);
end

close(analysisprog);


stimthreshold = threshold; 

hsizes_nozeros = hsizes(find(hsizes > 0)); %#ok<FNDSB>
vsizes_nozeros = vsizes(find(vsizes > 0)); %#ok<FNDSB>
minhsize = min(hsizes_nozeros);
minvsize = min(vsizes_nozeros);
stimminsize = round(min(minhsize,minvsize));

stimsizes =[hsizes(:),vsizes(:)];

framewithnostim = sort(unique(framewithnostim));
frameswithstim = setdiff(framenumbers,framewithnostim);

if processfullvideo
    save(datafilename,'stimuluslocs','stimminsize','stimsizes','frameswithstim','-append');
end

if nargout >= 2
    varargout{1} = stimthreshold;
end

if nargout >= 3
    varargout{2} = stimminsize;
end

if nargout >= 4
    varargout{3} = stimsizes;
end

if nargout == 5
    varargout{4} = frameswithstim;
end