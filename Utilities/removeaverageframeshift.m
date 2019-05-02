function [shiftswithaverageremoved,meanframeshift] = removeaverageframeshift(oldshiftswithaverage,numsamplesperframe,numframes,...
    numframestoaverage,gaussianstddev,interframevelocitythreshold,verbose)

if (nargin < 1) || isempty(oldshiftswithaverage)
    disp('I can''t remove average frameshift from non-existant frameshifts, exiting');
    error('Type ''help removemeanframeshift'' for usage');
end

if (nargin < 2) || isempty(numsamplesperframe)
    disp('I need the number of shift samples per frame, exiting');
    error('Type ''help removemeanframeshift'' for usage');
end

if (nargin < 3) || isempty(numframes)
    disp('I need the number of video frames analysed, exiting');
    error('Type ''help removemeanframeshift'' for usage');
end

if size(oldshiftswithaverage,1) ~= (numframes * numsamplesperframe)
    disp('Length of frame shifts array is is inconsistent with number of frames and number of samples per frame, exiting');
    error('Type ''help removemeanframeshift'' for usage');
end

if (nargin < 4) || isempty(numframestoaverage)
    togetnumframestoaverage = 1;
else
    togetnumframestoaverage = 0;
end

if (nargin < 5) || isempty(gaussianstddev)
    togetgaussianstddev = 1;
else
    togetgaussianstddev = 0;
end

if (nargin < 6) || isempty(interframevelocitythreshold)
    togetinterframevelocitythreshold = 1;
else
    togetinterframevelocitythreshold = 0;
end

if (nargin < 7) || isempty(verbose)
    verbose = 0;
end

if any([togetnumframestoaverage,togetgaussianstddev,togetinterframevelocitythreshold])
    name = 'Input for removeaverageframeshift.m';
    numlines = 1;
    prompt = {};
    defaultanswer = {};
    
    if togetnumframestoaverage
        prompt = {'Number of Frames to Average'};
        defaultanswer = {'20'};
    end
    
    if togetgaussianstddev
        prompt{end + 1} = 'Gaussian Std. Deviation';
        defaultanswer{end + 1} = '5';
    end
    
    if togetinterframevelocitythreshold
        prompt{end + 1} = {'Inter-Frame Velocity Threshold'};
        defaultanswer{end + 1} = '2';
    end
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(userresponse)
        if togetnumframestoaverage
            warning('You have not entered a value for the number of frames to average,using default of 20')
            numframestoaverage = 20;
        end
        if togetgaussianstddev
            warning('You have not entered a value for gaussian std. deviation,using default of 5')
            gaussianstddev = 5;
        end
        if togetinterframevelocitythreshold
            warning('You have not entered a value for inter-frame velocity threshold,using default of 2')
            interframevelocitythreshold = 2;
        end
    else
        index = 1;
        
        if togetnumframestoaverage
            if ~isempty(userresponse{index})
                numframestoaverage = str2double(userresponse{index});
            else
                warning('You have not entered a value for the number of frames to average,using default of 20')
                numframestoaverage = 20;
            end
            index = index + 1;
        end
        
        if togetgaussianstddev
            if ~isempty(userresponse{index})
                gaussianstddev = str2double(userresponse{index});
            else
                warning('You have not entered a value for gaussian std. deviation,using default of 5')
                gaussianstddev = 5;
            end
            index = index + 1;
        end
        
        if togetinterframevelocitythreshold
            if ~isempty(userresponse{index})
                interframevelocitythreshold = str2double(userresponse{index});
            else
                warning('You have not entered a value for inter-frame velocity threshold,using default of 2')
                interframevelocitythreshold = 2;
            end
        end
    end
end

if numframestoaverage < 0
    numframestoaverage = abs(numframestoaverage);
end
if (numframestoaverage < 3) || (numframestoaverage > size(oldshiftswithaverage,1))
    numframestoaverage = min(max(numframestoaverage,3),size(oldshiftswithaverage,1));
end
if numframestoaverage == size(oldshiftswithaverage,1)
    gaussianstddev = 0;
end

if gaussianstddev < 0
    gaussianstddev = abs(gaussianstddev);
end
if gaussianstddev  > 20
    gaussianstddev = 20;
end

if interframevelocitythreshold < 0
    interframevelocitythreshold = abs(interframevelocitythreshold);
end


frameindices = [1:numframes]';

oldshifts_unwraped = zeros(numsamplesperframe,numframes,2);

for directioncounter = 1:2
    oldshifts_unwraped(:,:,directioncounter) = reshape(oldshiftswithaverage(:,directioncounter),numsamplesperframe,numframes);
end

interframevelocity = abs([zeros(numsamplesperframe,1,2),diff(oldshifts_unwraped,1,2)]);
interframevelocity_maxinframe = max(squeeze(max(interframevelocity,[],1)),[],2);

badframeindices = find(interframevelocity_maxinframe > interframevelocitythreshold);
badframeindices = badframeindices(:);
goodframeindices = setdiff(frameindices,badframeindices);

numgoodframeindices = length(goodframeindices);
numbadframeindices = length(badframeindices);

prevgoodframeindex = zeros(numbadframeindices,1);
for badframeindexcounter = 1:numbadframeindices
    currentbadframeindex = badframeindices(badframeindexcounter);
    prevgoodframeindex(badframeindexcounter) = goodframeindices(find(goodframeindices < currentbadframeindex, 1, 'last' ));
end

oldshifts_unwraped_onlygoodframes = oldshifts_unwraped(:,goodframeindices,:);

meanpositioninframe = mean(oldshifts_unwraped_onlygoodframes,1);
oldshifts_unwraped_onlygoodframes_zeroposition = oldshifts_unwraped_onlygoodframes -...
    repmat(meanpositioninframe,[numsamplesperframe 1 1]);

meanframeshift_unwraped = zeros(numsamplesperframe,numframes,2);

if (numframestoaverage < size(oldshiftswithaverage,1))
    gaussianaxis = [1:numgoodframeindices];
    indexaddition = [0:(numframestoaverage - 1)] - floor(numframestoaverage / 2);
    for framecounter = 1:numgoodframeindices
        
        indextoputdata = find(frameindices == goodframeindices(framecounter));
        
        if gaussianstddev > 0
            meanlocation = framecounter;
            gaussianaxis_touse_initial = gaussianaxis - meanlocation;
            signofgaussianaxis = sign(gaussianaxis_touse_initial);
            gaussianaxis_touse = max(abs(gaussianaxis_touse_initial) - (numframestoaverage / 2),0) .* signofgaussianaxis;
            
            weightstouse = repmat(exp(-1.0 * ((gaussianaxis_touse .^ 2) ./ (2 * (gaussianstddev .^ 2)))),[numsamplesperframe,1,2]);
        else
            weightstouseinitial = zeros(1,numgoodframeindices);
            indicesofones = unique(min(max(indexaddition + framecounter,1),numgoodframeindices));
            weightstouseinitial(indicesofones) = ones(1,length(indicesofones));
            
            weightstouse = repmat(weightstouseinitial,[numsamplesperframe,1,2]);
        end
        
        currentmeanshift = sum(oldshifts_unwraped_onlygoodframes_zeroposition .* weightstouse,2) ./...
            sum(weightstouse,2);
        
        meanframeshift_unwraped(:,indextoputdata,:) = currentmeanshift; %#ok<FNDSB>
    end
else
    meanframeshift_unwraped = repmat(mean(oldshifts_unwraped_onlygoodframes_zeroposition,2),[1,numframes,1]);
end

meanframeshift_unwraped(:,badframeindices,:) = meanframeshift_unwraped(:,prevgoodframeindex,:);
meanframeshift = zeros(numsamplesperframe * numframes,2);

for directioncounter = 1:2
    tempshifts = meanframeshift_unwraped(:,:,directioncounter);
    meanframeshift(:,directioncounter) = tempshifts(:);
end

shiftswithaverageremoved = oldshiftswithaverage - meanframeshift;

if verbose
    figure;
    intialposition = get(gcf,'Position');
    newposition = intialposition;
    newposition(4) = round(newposition(4) * 3 / 2);
    newposition(1:2) = 0;
    set(gcf,'Position',newposition);
    
    subplot(2,1,1);
    plot(oldshiftswithaverage(:,1),'r','LineWidth',5);
    hold on;
    plot(shiftswithaverageremoved(:,1),'b','LineWidth',2.5);
    hold off;
    title('Horizontal Shifts');
    xlabel('Sample No.');
    ylabel('Ocular Position');
    
    subplot(2,1,2);
    plot(oldshiftswithaverage(:,2),'r','LineWidth',5);
    hold on;
    plot(shiftswithaverageremoved(:,2),'b','LineWidth',2.5);
    hold off;
    title('Vertical Shifts');
    xlabel('Sample No.');
    ylabel('Ocular Position');
        
    figure;
    plot(meanframeshift);
    title('Mean Shifts');
    xlabel('Sample No.');
    ylabel('Mean Ocular Shift');
end