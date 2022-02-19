
%% Find stimulus location of each frame
clearvars; close all;
[fname, pname] = uigetfile('*.AVI;*.avi', 'Select stabilized AVI files for adding', 'MultiSelect', 'on');

[sfname, spname] = uigetfile('*.bmp*', 'Select stimulus');
stimulus = rgb2gray(imread([spname,sfname]));
if (iscell(fname)==0)
    a=fname;
    fname=cell(1);
    fname{1}=a;
end
nummovies = size(fname,2);
for movienum = 1:nummovies
    inputVideoPath=[pname, fname{movienum}];
outputPath = [inputVideoPath(1:end-4) '_nostim.tif'];
matFileName = [inputVideoPath(1:end-4) '_stimlocs'];

% Determine dimensions of video.
reader = VideoReader(inputVideoPath);
samplingRate = reader.FrameRate;
width = reader.Width;
height = reader.Height;
numberOfFrames = reader.Framerate * reader.Duration;

% Populate time array
timeArray = (1:numberOfFrames)' / samplingRate;   

stimulusLocationInEachFrame = NaN(numberOfFrames, 2);

for frameNumber = 1:numberOfFrames
        frame = readFrame(reader);
        if ndims(frame) == 3
            frame = rgb2gray(frame);
        end

        correlationMap = normxcorr2(stimulus, frame);

        findPeakParametersStructure.enableGaussianFiltering = false;
        findPeakParametersStructure.stripHeight = height;    
        [xPeak, yPeak, peakValue] = ...
            FindPeak(correlationMap, false);
           %FindPeak(correlationMap, findPeakParametersStructure);
      
        clear findPeakParametersStructure;
    stimulusLocationInEachFrame(frameNumber,:) = [xPeak yPeak];
end
imshow(frame)
hold on; plot(stimulusLocationInEachFrame(:,1),stimulusLocationInEachFrame(:,2),'-g')
end
