function [highvelocitydatapoints, highvelocityframes,directionaldata] =...
    findhighvelocitypoints(rawvelocity,analysedframes,numsamplesperframe,threshold,numsamplestosmooth,verbose)
% findhighvelocitypoints.m. This is a utility function to identify indices in the ocular motion trace that have high velocity.The function first
% smooths the velocity trace and then applies the threshold.
%
% Usage: [highvelocitydatapoints, highvelocityframes,directionaldata] =
%        findhighvelocitypoints(rawvelocity,analysedframes,numsamplesperframe,
%        [threshold,numsamplestosmooth,verbose])
%
% rawvelocity                       - The a two column array that contains velocity of the ocular motion in the video. By default the first column
%                                          is the horizontal velocity and the second column is the vertical velocity.  The number of rows in this vector
%                                          has to be equal to numsamplesperframe * number of rows in the analysedframes.
% analysedframes                  - The numbers of the frames that were analysed to obtain the velocity. This array has to have atleast 3 rows 
%                                          for the function to accept it.
% numsamplesperframe           - The number of strips that were used during the analyses of the video that produced the velocity trace.
% threshold                          - The velocity threshold that divides the low and high threshold data points.
% numsamplestosmooth          - The number of samples that are averaged to obtained the smoothed velocity.
% verbose                            - The feedback flag. If set to 1 then the program plots the velocity provided along with the data points that were
%                                          determined to have high velocity. if set 0 no feedback is provided. Default is 0.
%
% highvelocitydatapoints         - The data points whose velocity exceed the threshold.
% highvelocityframes              - The frames that contains the data points that are tagged as the high velocity. The first column is the index within
%                                          the analysedframes vector and the second column is the frame number.
% directionaldata                   - A cell array that contains the high velocity data points and frames for each individual direction meridian.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War


if (nargin < 3)
    disp('Inadequate number of input arguments');
    error('Exiting...');
end

if (nargin < 4) || isempty(threshold)
    togetthreshold = 1;
else
    togetthreshold = 0;
end

if (nargin < 5) || isempty(numsamplestosmooth)
    togetnumsamplestosmooth = 1;
else
    togetnumsamplestosmooth = 0;
end

if (nargin < 6) || isempty(verbose)
    verbose = 0;
end


if togetthreshold || togetnumsamplestosmooth
    name = 'Input for findhighvelocitypoints function';
    numlines = 1;
    prompt = {};
    defaultanswer = {};
    
    if togetthreshold
        prompt = {'Velocity Threshold'};
        defaultanswer = {'10'};
    end
    
    if togetnumsamplestosmooth
        prompt{end + 1} = 'Num. Smooth Samples';
        defaultanswer{end + 1} = '15';
    end
    
    userresponse = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(userresponse)
        if togetthreshold
            warning('Using default velocity threshold of 10 /sample');
            threshold = 10;
        end
        
        if togetnumsamplestosmooth
            warning('Smoothing over default 12 samples')
            numsamplestosmooth = 12;
        end
    else
        index = 1;
        
        if togetthreshold
            if ~isempty(userresponse{index})
                threshold = str2double(userresponse{index});
            else
                disp('User has not entered any value for the velocity threshold');
                warning('Using default value of 10 /sample');
                threshold = 10;
            end
            index = index + 1;
        end
        
        if togetnumsamplestosmooth
            if ~isempty(userresponse{index})
                numsamplestosmooth = str2double(userresponse{index});
            else
                disp('User has not entered any value for the num samples to smooth over');
                warning('Using default of 12');
                numsamplestosmooth = 12;
            end
        end
    end
end


if (size(rawvelocity,2) < 2) || (size(rawvelocity,1) <= 2)
    disp('Input argument "rawvelocity" has incorrect size');
    error('Type ''help findhighvelocitydatapoints'' for usage');
end
if rem(size(rawvelocity,1),numsamplesperframe)
    disp('Number of samples per frame does not match the total number of samples in velocity data');
    error('type ''help findhighvelocitydatapoints for usage');
end

if length(analysedframes) ~= ceil(size(rawvelocity,1) / numsamplesperframe)
    disp('Lengh of frame vector does not match the total number of samples in velocity data');
    error('type ''help findhighvelocitydatapoints for usage');
end

if threshold < 0
    disp('Threshold cannot be negative');
    warning('Using absolute value')
    threshold = abs(threshold);
end

if numsamplestosmooth > 50
    disp('Smoothing Factor is too high')
    warning('Reducing to 50')
    numsamplestosmooth = 50;
end
if numsamplestosmooth < 0
    disp('Smoothing Factor is too low')
    warning('Increasing to 1')
    numsamplestosmooth = 1;
end


numsamples = size(rawvelocity,1);
if size(rawvelocity,2) == 3
    timetrace = repmat(rawvelocity(:,3),1,2);
else
    timetrace = ones(size(rawvelocity));
end

if numsamplestosmooth >= 1
    smoothaddition = [0:numsamplestosmooth - 1] - floor(numsamplestosmooth / 2);
    indicestosmooth = max(min(repmat([1:numsamples]',1,numsamplestosmooth) +...
        repmat(smoothaddition,numsamples,1),numsamples),1);
else
    indicestosmooth = [1:numsamples]';
end

highvelocitydatapoints = [];
directionaldata = cell(2,1);

highvelocitydatapoints_directional = cell(2,1);
highvelocityframes_directional = cell(2,1);

for directioncounter = 1:2
    tempvel_unsmoothed = rawvelocity(:,directioncounter);
    tempvel = mean(tempvel_unsmoothed(indicestosmooth),2);
%     figure
%     plot(abs(tempvel_unsmoothed));
%     figure
%     plot(abs(tempvel));
%     tempvel = tempvel_unsmoothed;
    temphighvelocitydatapoints = find(abs(tempvel(:)) > threshold);
    
    highvelocitydatapoints = [highvelocitydatapoints;temphighvelocitydatapoints(:)];
    highvelocitydatapoints_directional{directioncounter} = temphighvelocitydatapoints(:);
    highframevelocityindex = unique(ceil(temphighvelocitydatapoints / numsamplesperframe));
    highframevelocityindex = highframevelocityindex(:);
    highvelocityframes_directional{directioncounter} = [highframevelocityindex,analysedframes(highframevelocityindex)];
end

highvelocitydatapoints = unique(highvelocitydatapoints);
highframevelocityindex = unique(ceil(highvelocitydatapoints / numsamplesperframe));
highframevelocityindex = highframevelocityindex(:);
highvelocityframes = [highframevelocityindex,analysedframes(highframevelocityindex)];
directionaldata{1} = highvelocitydatapoints_directional;
directionaldata{2} = highvelocityframes_directional;

if verbose
    positiondata = cumsum(rawvelocity(:,1:2) .* timetrace,1);
    
    figure;
    plot(positiondata);
    hold on;
    plot(highvelocitydatapoints,positiondata(highvelocitydatapoints,:),'r*');
    hold off
end