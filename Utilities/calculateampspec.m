function [averageampspec allampspecs ampspecfitparams ampspecstats shiftstats] = ...
    calculateampspec(videoname,tracetoanalyse,analysedframes,samplerate,...
    durationofanalysedtrace,numlinesperfullframe,velocitythresh,toremoveave,verbose)

if (nargin < 9) || isempty(verbose)
    verbose = 0;
end

if (nargin < 8) || isempty(toremoveave)
    toremoveave = 0;
end

if nargin < 6
    disp('Need more parameters');
    return
end

if ~exist(videoname,'file') || isempty(videoname)
    warning('Need a proper video name')
    [fname pname] = uigetfile('*.avi','Please choose a video');
    videoname = strcat(pname,fname);
end

vid_obj = VideoReader(videoname);
aviheight = vid_obj.Height;
framerate = round(vid_obj.FrameRate);

timediffbetsamples = 1 / samplerate;
numindicestoaverage = 7;
aveindexaddition = [0:(numindicestoaverage - 1)] - floor(numindicestoaverage / 2);

numindicestoignore = 7;
ignoreindexaddition = [0:(numindicestoignore - 1)] - floor(numindicestoignore / 2);

numstrips = round(samplerate / framerate);
stripseparation = round(numlinesperfullframe/ numstrips);

stripidx(1) = round(stripseparation / 2); % The location of the first strip
if numstrips > 1
    for stripcounter = 2:numstrips
        stripidx(stripcounter) = stripidx(stripcounter - 1) + stripseparation;
    end
end

stripidx = stripidx(:);
stripidx_reduced = stripidx(find(stripidx <= aviheight)); %#ok<FNDSB>

numframespertrace = ceil(durationofanalysedtrace * framerate);
numsamplesperinterpedtrace = numframespertrace * length(stripidx);
spectrumcentre = floor(numsamplesperinterpedtrace / 2) + 1;
maxfreq_cpt = numsamplesperinterpedtrace - spectrumcentre;
maxfreq_cps = maxfreq_cpt / durationofanalysedtrace;

averageampspec = zeros(maxfreq_cpt,2);
plot_xaxis = [1:maxfreq_cpt]' / durationofanalysedtrace;

numframes = length(analysedframes);
lastframe = max(analysedframes(:));

numsamplesinfulluninterpedtrace = length(tracetoanalyse);
numsamplesinfullinterpedtrace = length(stripidx) * numframes;

interp_xaxis = [0:(numlinesperfullframe * lastframe) - 1];
interp_xaxis = reshape(interp_xaxis,numlinesperfullframe,lastframe);
sample_xaxis = interp_xaxis(stripidx_reduced,analysedframes);
interp_xaxis = interp_xaxis(stripidx,analysedframes);

interp_xaxis = interp_xaxis(:);
sample_xaxis = sample_xaxis(:);
sample_timeaxis = sample_xaxis / (numlinesperfullframe * framerate);
sampletimediff = diff(sample_timeaxis);
lastsampleindex = find(interp_xaxis == sample_xaxis(end));

numsamples = length(interp_xaxis);
interpedtracetoanalyse = zeros(numsamples,2);
averagedshifts = zeros(numsamples,2);
indicestoaverage = min(max(repmat([1:numsamples]',1,numindicestoaverage) +...
    repmat(aveindexaddition,numsamples,1),1),numsamples);

for directioncounter = 1:2
    sample_yaxis = tracetoanalyse(:,directioncounter);
    interp_yaxis = interp1(sample_xaxis,sample_yaxis,interp_xaxis,'pchip','extrap');
    interp_yaxis(lastsampleindex + 1:end) = interp_yaxis(lastsampleindex);
    interpedtracetoanalyse(:,directioncounter) = interp_yaxis;

    tempshifts = interp_yaxis;
    tempshifts_averaged = mean(tempshifts(indicestoaverage),2);
    averagedshifts(:,directioncounter) = tempshifts_averaged(:);
end
% maxvelocity = max(abs(diff(averagedshifts,1,1)) * samplerate,[],2);
maxvelocity = max(abs(diff(averagedshifts,1,1)),[],2);

indicesaboverthresh_initial = find(maxvelocity(:) >= velocitythresh);
numindicesaboverthresh = length(indicesaboverthresh_initial);

numsamplespertrace = numframespertrace * length(stripidx);
tracexaxis = [0:numsamplespertrace - 1]  * 1000 / samplerate;

rmsesofanalysedtraces = [];
stdsofanalysedtraces = [];

if numindicesaboverthresh >= 1
    indicesaboverthresh = repmat(indicesaboverthresh_initial,1,numindicestoignore) +...
        repmat(ignoreindexaddition,numindicesaboverthresh,1);
    indicesaboverthresh = unique(max(min(indicesaboverthresh(:),numsamples),1));
    lengthofbreaks = diff([indicesaboverthresh(1);indicesaboverthresh]);
    breaklocations = find(diff([indicesaboverthresh(1);indicesaboverthresh]) >= numsamplespertrace);
    if ~isempty(breaklocations)
        tracestartindices = indicesaboverthresh(breaklocations - 1) + 1;
    else
        if min(indicesaboverthresh(:)) > 1
            temppresacc = [1:numsamplespertrace:indicesaboverthresh(1) - numsamplespertrace]';
            temppostsacc = [indicesaboverthresh(end) + 1:...
                numsamplespertrace:numsamples - numsamplespertrace]';
            tracestartindices = [temppresacc;temppostsacc];
        else
            tracestartindices = [indicesaboverthresh(end) + 1:...
                numsamplespertrace:numsamples - numsamplespertrace]';
        end
    end    
    
    if ~isempty(indicesaboverthresh) && (max(indicesaboverthresh(:)) < (numsamples - numsamplespertrace))
        tempaddition = [max(indicesaboverthresh(:)) + 1:numsamplespertrace:numsamples - numsamplespertrace]';
        tracestartindices = [tracestartindices(:);tempaddition(:)];
    end
else
    tracestartindices = [1:numsamplespertrace:numsamples - numsamplespertrace]';
end

traceendindices = tracestartindices + numsamplespertrace - 1;

numtemptraces = length(tracestartindices);

if (numtemptraces == 0) || isempty(tracestartindices)
    averageampspec = [];
    allampspecs = [];
    ampspecfitparams = struct('XAxis',[],'YAxis',[],...
        'Slopes',[],'Intercepts',[],'BestFitLines',[],...
        'ChiSquared',[],'SSResiduals',[],'RSquared',[]);
    ampspecstats = struct('XAxis',[],'MeanAmpSpectrum',[],...
        'STDofAmpSpectra',[],'SEofAmpSpectra',[]);
    shiftstats = struct('StdDev',[],'RMS',[]);
    return
end
allampspecs = zeros(maxfreq_cpt,2,numtemptraces);

for temptracecounter = 1:numtemptraces
    startindex = tracestartindices(temptracecounter);
    endindex = traceendindices(temptracecounter);
    clippedtracetoanalyse = interpedtracetoanalyse(startindex:endindex,:);
    
    if verbose
        if exist('clippedtracefig','var')
            figure(clippedtracefig)
        else
            clippedtracefig = figure;
        end
        
        plot(clippedtracetoanalyse);
        drawnow
        pause(0.5);
    end

    meansqdev = sum(sum((clippedtracetoanalyse - repmat(mean(clippedtracetoanalyse,1),...
        numsamplespertrace,1)) .^ 2,1),2);
    rmsesofanalysedtraces = [rmsesofanalysedtraces;sqrt(meansqdev ./ (2 * (numsamplespertrace - 1)))];
    stdsofanalysedtraces = [stdsofanalysedtraces;std(clippedtracetoanalyse,0,1)];

    if toremoveave
        for directioncounter = 1:2
            tempshifts = reshape(clippedtracetoanalyse(:,directioncounter),length(stripidx),numframespertrace);
            tempshift_nomean = tempshifts - repmat(mean(tempshifts,1),length(stripidx),1);
            meanshift = repmat(mean(tempshift_nomean,2),1,numframespertrace);

            oldshifts = clippedtracetoanalyse(:,directioncounter);

            clippedtracetoanalyse(:,directioncounter) = clippedtracetoanalyse(:,directioncounter) -...
                meanshift(:);
        end
    end

    traceforfft = clippedtracetoanalyse -...
        repmat(mean(clippedtracetoanalyse,1),numsamplespertrace,1);
    singletrace_absspectrum_fullmatrix = abs(fft(traceforfft,[],1)) / (numsamplespertrace / 2);
    singletrace_absspectrum = singletrace_absspectrum_fullmatrix(2:maxfreq_cpt + 1,:);

    allampspecs(:,:,temptracecounter) = singletrace_absspectrum;
end

if exist('clippedtracefig','var')
    close(clippedtracefig);
end

shiftstats = struct('StdDev',stdsofanalysedtraces,'RMS',rmsesofanalysedtraces);

averageampspec = mean(allampspecs,3);
ampspec_std = std(allampspecs,0,3);
ampspec_se = ampspec_std / numtemptraces;
ampspecstats = struct('XAxis',plot_xaxis,'MeanAmpSpectrum',averageampspec,...
    'STDofAmpSpectra',ampspec_std,'SEofAmpSpectra',ampspec_se);


fit_xaxis = log10(plot_xaxis);
fit_yaxis = log10(averageampspec);

covariancemat_hori = cov(fit_xaxis,fit_yaxis(:,1));
slopeofhoriline = covariancemat_hori(2) /  var(fit_xaxis,1);
interceptofhoriline = mean(fit_yaxis(:,1)) - (slopeofhoriline * mean(fit_xaxis(:,1)));
horiline = (fit_xaxis * slopeofhoriline) + interceptofhoriline;

covariancemat_vert = cov(fit_xaxis,fit_yaxis(:,2));
slopeofvertline = covariancemat_vert(2) /  var(fit_xaxis,1);
interceptofvertline = mean(fit_yaxis(:,2)) - (slopeofvertline * mean(fit_xaxis));
vertline = (fit_xaxis * slopeofvertline) + interceptofvertline;

chisqed_hori = sum((((horiline - fit_yaxis(:,1)) .^ 2) ./ (horiline .^ 2)),1);
chisqed_vert = sum((((vertline - fit_yaxis(:,2)) .^ 2) ./ (vertline .^ 2)),1);

ssresidual_hori = sum((fit_yaxis(:,1) - horiline) .^ 2,1);
ssresidual_vert = sum((fit_yaxis(:,2) - vertline) .^ 2,1);

sstotal_hori = sum((fit_yaxis(:,1) - mean(fit_yaxis(:,1))) .^ 2,1);
sstotal_vert = sum((fit_yaxis(:,2) - mean(fit_yaxis(:,2))) .^ 2,1);

ssfit_hori = sum((mean(fit_yaxis(:,1)) - horiline) .^ 2,1);
ssfit_vert = sum((mean(fit_yaxis(:,2)) - vertline) .^ 2,1);

rsqed_hori = ssfit_hori / sstotal_hori;
rsqed_vert = ssfit_vert / sstotal_vert;

slopes = [slopeofhoriline,slopeofvertline];
intercept = [interceptofhoriline,interceptofvertline];
bestfitlines = 10 .^ ([horiline,vertline]);
chisqed = [chisqed_hori,chisqed_vert];
ssresidual = [ssresidual_hori,ssresidual_vert];
rsqed = [rsqed_hori,rsqed_vert];


ampspecfitparams = struct('XAxis',plot_xaxis,'YAxis',averageampspec,...
    'Slopes',slopes,'Intercepts',intercept,'BestFitLines',bestfitlines,...
    'ChiSquared',chisqed,'SSResiduals',ssresidual,'RSquared',rsqed);

if verbose
    figure
    subplot(2,1,1)
    loglog(10 .^ fit_xaxis,10 .^ fit_yaxis(:,1),'b')
    hold on;
    linetofit = (fit_xaxis * slopeofhoriline) + interceptofhoriline;
    loglog(10 .^ fit_xaxis,10 .^ linetofit,'k');
    xlabel('Tempral Frequency (cps)')
    ylabel('Horizontal Amplitude')
    hold off;
    subplot(2,1,2)
    loglog(10 .^ fit_xaxis,10 .^ fit_yaxis(:,2),'b')
    hold on;
    linetofit = (fit_xaxis * slopeofvertline) + interceptofvertline;
    loglog(10 .^ fit_xaxis,10 .^ linetofit,'k');
    xlabel('Tempral Frequency (cps)')
    ylabel('Vertical Amplitude')
    hold off;
end