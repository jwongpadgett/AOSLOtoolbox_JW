function [retinalstimlocs,framewithstimanalysed] = getretinalstimlocs(rawtraces,...
    analysedframes,stripindices,framesize,peakdiffs,badstripthreshold,...
    frameswithstim,stimuluslocs,timefactor)

if (nargin < 8) || (nargin > 9)
    disp('getretinalstimlocs requires 8/9 input arguments');
    error('Exiting...');
end

if nargin < 9
    timefactor = 1 / (30 * 525);
end

numsamples = size(rawtraces,1);
numstrips = length(stripindices);

if rem(numsamples,numstrips) == 0
    numframes = numsamples / numstrips;
else
    disp('Number of Strips per frame and number of samples in raw traces does match');
    error('Exiting...');
end

videowidth = framesize(1);
videoheight = framesize(2);

videocentre_x = floor(videowidth / 2) + 1;
videocentre_y = floor(videoheight / 2) + 1;

interp_xaxis = [0:((numframes * videoheight)- 1)];
interp_xaxis = reshape(interp_xaxis,videoheight,numframes);
sample_xaxis = interp_xaxis(stripindices,:);

interp_xaxis = interp_xaxis(:);
sample_xaxis = sample_xaxis(:);

peakdiffs_unwraped = reshape(peakdiffs,numstrips,numframes);

rawtraces_unwraped = zeros(numstrips,numframes);
rawtraces_unwraped_spline = zeros(videoheight,numframes);
for directioncounter = 1:2
    tempshifts = rawtraces(:,directioncounter);
    tempshifts = tempshifts(:);
    rawtraces_unwraped(:,:,directioncounter) = reshape(tempshifts,numstrips,numframes);
    interp_yaxis = interp1(sample_xaxis,tempshifts,interp_xaxis);
    rawtraces_unwraped_spline(:,:,directioncounter) = reshape(interp_yaxis,videoheight,numframes);
end

badstripmarker = double(peakdiffs_unwraped > badstripthreshold);
numframeswithstim = length(frameswithstim);

retinalstimlocs = zeros(numframeswithstim,4);
frameindiceswithbadstimlocation = [];
stimprog = waitbar(0,'Getting Retinal Locations of Stimulus');
for framecounter = 1:numframeswithstim
    frameofinterest = frameswithstim(framecounter);
    frameindex = find(analysedframes == frameofinterest);
    
    if isempty(frameindex)
        frameindiceswithbadstimlocation = [frameindiceswithbadstimlocation;framecounter];
        prog = framecounter / numframeswithstim;
        waitbar(prog,stimprog);
        continue;
    end
    
    badstripmarkerofframe = badstripmarker(:,frameindex);
    stimxloc = stimuluslocs(framecounter,1);
    stimyloc = stimuluslocs(framecounter,2);
    stimyframecoord = stimyloc + videocentre_y;
    isprevstripbad = badstripmarkerofframe(max(find(stripindices <= stimyframecoord))); %#ok<MXFND>
    if isempty(isprevstripbad)
        if frameindex == 1
            isprevstripbad = 1;
        else
            badstripmarkerofframe_prev = badstripmarker(:,frameindex - 1);
            isprevstripbad = badstripmarkerofframe_prev(end);
        end
    end
    
    isnextstripbad = badstripmarkerofframe(min(find(stripindices >= stimyframecoord))); %#ok<MXFND>
    if isempty(isnextstripbad)
        if frameindex == size(badstripmarker,2)
            isnextstripbad = 1;
        else
            badstripmarkerofframe_next = badstripmarker(:,frameindex + 1);
            isnextstripbad = badstripmarkerofframe_next(1);
        end
    end
    
    if isprevstripbad || isnextstripbad
        frameindiceswithbadstimlocation = [frameindiceswithbadstimlocation;framecounter];
        prog = framecounter / numframeswithstim;
        waitbar(prog,stimprog);
        continue;
    else
        framemovements = squeeze(rawtraces_unwraped_spline(:,frameindex,:));
        stimloconretina_x = stimuluslocs(framecounter,1) - framemovements(round(stimyframecoord),1);
        stimloconretina_y = stimuluslocs(framecounter,2) - framemovements(round(stimyframecoord),2);
        stimtime = stimuluslocs(framecounter,3) * timefactor;
        retinalstimlocs(framecounter,:) = [stimloconretina_x,stimloconretina_y,...
            frameofinterest,stimtime];
    end
    
    prog = framecounter / numframeswithstim;
    waitbar(prog,stimprog);
end

close(stimprog);
goodstimlocindices = setdiff([1:numframeswithstim]',frameindiceswithbadstimlocation);
retinalstimlocs = retinalstimlocs(goodstimlocindices,:);
framewithstimanalysed = frameswithstim(goodstimlocindices);