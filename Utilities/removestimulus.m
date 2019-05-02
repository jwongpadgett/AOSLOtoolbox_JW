function removestimulus(videoname,frameswithstim,stimcentres,stimsizes)


currentdir = pwd;

if nargin < 1 || isempty(videoname)
    [fname pname] = uigetfile('*.avi','Please enter name of video from which to remove stimulus');
    if fname == 0
        error('No video to analyse,stoping program, Type ''help getandremovestimulus'' for usage');
    end
    cd(pname);
    videoname = strcat(pname,fname);
end

vid_obj = VideoReader(videoname); % Get important info of the avifile
numframes = round(vid_obj.FrameRate*vid_obj.Duration);
aviwidth = vid_obj.Width;
aviheight = vid_obj.Height;
xcenter = floor(aviwidth / 2) + 1;
ycenter = floor(aviheight / 2) + 1;
framerate = round(vid_obj.FrameRate);

newvideoname = strcat(videoname(1:end-4),'_nostim.avi');
newmovie = VideoWriter(newvideoname,'Grayscale AVI');
newmovie.FrameRate = framerate;
open(newmovie);

framenumbers = [1:numframes]';

removeprog = waitbar(0,'Removing Stimulus');
oldposition = get(removeprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20) ...
    oldposition(3) oldposition(4)];
set(removeprog,'Position',newposition);

for framecounter = 1:numframes
    if isempty(find(frameswithstim == framenumbers(framecounter),1))
        frametoadd = readFrame(vid_obj);
    else
        videoframe = double(readFrame(vid_obj));
        indexinmatrix = find(frameswithstim == framenumbers(framecounter),1);
        
        stimcentreinframe = stimcentres(indexinmatrix,:);
        
        stimsizeinframe = stimsizes(indexinmatrix,:);
        %keyboard;
%         leftindex_stim = max(floor(stimcentreinframe(1) - floor(stimsizeinframe(1) / 2)) + xcenter,1);
%         rightindex_stim = min(leftindex_stim + stimsizeinframe(1),aviwidth);
        leftindex_stim = floor(stimcentreinframe(1) - floor(stimsizeinframe(1) / 2));
        rightindex_stim = leftindex_stim + stimsizeinframe(1);

        topindex_stim = floor(stimcentreinframe(2) - floor(stimsizeinframe(2) / 2));
        bottomindex_stim = topindex_stim + stimsizeinframe(2);
%         topindex_stim = max(topindex_stim,1);
%         bottomindex_stim = min(bottomindex_stim,aviheight);leftindex_stim + stimsizeinframe(1)
        
        leftindex = max(leftindex_stim - 10,1);
        rightindex = min(rightindex_stim + 10,aviwidth);
        topindex = max(topindex_stim - 10,1);
        bottomindex = min(bottomindex_stim + 10,aviheight);
        
        colnumbers = [leftindex:rightindex];
        rownumbers = [topindex:bottomindex];
        
        numcols = length(colnumbers);
        numrows = length(rownumbers);
        
        colmatrix = zeros(numrows,numcols);
        rowmatrix = zeros(numrows,numcols);
        
        for colcounter = 1:numcols
            toppixelval = videoframe(topindex,colnumbers(colcounter));
            bottompixelval = videoframe(bottomindex,colnumbers(colcounter));
            linetoadd = linspace(toppixelval,bottompixelval,numrows);
            linetoadd = linetoadd(:);
            colmatrix(:,colcounter) = linetoadd;
        end
        
        for rowcounter = 1:numrows
            leftpixelval = videoframe(rownumbers(rowcounter),leftindex);
            rightpixelval = videoframe(rownumbers(rowcounter),rightindex);
            linetoadd = linspace(leftpixelval,rightpixelval,numcols);
            rowmatrix(rowcounter,:) = linetoadd;
        end
        
        sizeofmatrix = prod(size(rowmatrix)); %#ok<PSIZE>
        randindices = floor(rand(sizeofmatrix,1) * ((aviwidth * aviheight) - 1)) + 1;
        randmatrix = reshape(videoframe(randindices),size(rowmatrix,1),size(rowmatrix,2));
        %keyboard;
        matrixtoadd = smoothimage((rowmatrix + colmatrix + randmatrix) / 3,2);
        %matrixtoadd = (rowmatrix + colmatrix + randmatrix) / 3;
        newvideoframe = videoframe;
        
        newvideoframe(rownumbers,colnumbers) = matrixtoadd;
        frametoadd = mat2gray(newvideoframe);
    end
    %keyboard;
    writeVideo(newmovie, frametoadd);
    waitbar((framecounter/ numframes),removeprog);
    
end

close(removeprog);
close(newmovie); %#ok<NASGU>
cd(currentdir);