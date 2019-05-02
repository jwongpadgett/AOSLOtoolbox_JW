
% Get the video to analyse to extract motion
[fname pname] = uigetfile('*.avi','Please enter filename of the video you want stabilized');
videofile= strcat(pname,fname);

videoObject = VideoReader(videofile);
frameheight = videoObject.Height;
framewidth = videoObject.Width;
framerate = round(videoObject.FrameRate);
numberofframes = round(videoObject.FrameRate*videoObject.Duration);

videoMatrix = zeros(frameheight, framewidth, numberofframes);
successiveCrossCorrelations = zeros(numberofframes,1);

for framecounter=1:numberofframes
    videoMatrix(:,:,framecounter) = double(readFrame(videoObject));
end

for framecounter=2:numberofframes-1
    successiveCrossCorrelations(framecounter) = corr2(videoMatrix(:,:,framecounter),videoMatrix(:,:,framecounter-1));
end

goodframesindices = find(successiveCrossCorrelations>mean(successiveCrossCorrelations));
goodframes = videoMatrix(:,:,goodframesindices);

goodvideofile = strcat(videofile(1:end-4),'_goodvideo.avi');
v = VideoWriter(goodvideofile,'Indexed AVI');
v.Colormap = gray(256);
open(v);
writeVideo(v,goodframes);
close(v);



%%
% formatofstabframe = strcat('.tiff');
% 
% 
% blinkthreshold = 25;
% minimummeanlevel = 15;
% blinkverbosity = 1;
% blinkframes = getblinkframes(videofile, blinkthreshold, minimummeanlevel,blinkverbosity);
% 
% 
% [goodframesegmentinfo largemovementframes] = getbadframes(videofile,blinkfilename, peakratiodiff, maxmotionthreshold, badframeverbosity);

