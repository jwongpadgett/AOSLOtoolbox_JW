%Loads a stabilized AOSLO video of the fovea with a blinking stimulus near
%the center of the field and estimates the location of the fixational locus 
%Stabilized AOSLO II images are 672 by 672 pixels.
clear all
close all

T =17;              %Stimulus is less than this threshold pixel value (norm 15)
bOfflineStab =false;

%Load the stabilized image
[fname,pname] = uigetfile('*.avi','Open AVI file');
AVIdetails=aviinfo([pname fname]);

%Establish access to AVI file
AVIdetails = aviinfo([pname '\' fname]);
startframe = 1;
endframe = AVIdetails.NumFrames;
width = AVIdetails.Width;
wBuffer = max(1,floor(width-712)/2);
height = AVIdetails.Height;
hBuffer = max(1,floor(height-712)/2);
if(bOfflineStab)
    sumframe = zeros(min(height,712),min(width,712));
    sumframebinary=ones(min(height,712),min(width,712));
    fixationframe = zeros(min(height,712),min(width,712));
else
    sumframe = zeros(AVIdetails.Height,AVIdetails.Width);
    sumframebinary=ones(AVIdetails.Height,AVIdetails.Width);
    fixationframe = zeros(AVIdetails.Height,AVIdetails.Width);
end

X = nan(endframe,1);
Y = X;
T = T/255;              %Matlab threshold is normalize to [0 1]
ind = 1;
se = strel('disk',1);

for framenum = startframe:endframe
    MovObj = VideoReader([pname '\' fname]);    
    currentframe = double(read(MovObj, framenum));
    if(bOfflineStab)
        
        currentframe = currentframe(hBuffer:min(height,hBuffer+711),wBuffer:min(width,wBuffer+711),3); % For offline stabilized videos
    end
    currentframe = currentframe/(max(max(currentframe)));
    %Extract the stimulus (set to 1) from the background (set to 0);
    currentframebinary = im2bw(currentframe,T);
    sumframe = sumframe+double(currentframe);
    sumframebinary = sumframebinary+currentframebinary; % generate an image to divide by the sum image to generate an average
    currentframefilled = imfill(currentframebinary, 'holes');
    currentstimulus = double(imsubtract(currentframefilled,currentframebinary));
    if(bOfflineStab)
        currentstimulus = imerode(currentstimulus,se);
    end
    imshow(currentframebinary,'InitialMagnification',100);
    imshow(currentframe,'InitialMagnification',100);
    
    %Compute the centroid of the stimulus
    if sum(currentstimulus(:)) > 200
        fprintf('the stimulus is in frame #%g: currentstimulussum is%g\n',framenum, sum(currentstimulus(:)));
        
        stats = regionprops(currentstimulus,'Centroid');
        X(ind) = stats.Centroid(1);         %verified
        Y(ind) = stats.Centroid(2);
        
        
        imshow(currentstimulus,'InitialMagnification',100);hold on
        imshow(sumframe/max(max(sumframe)),'InitialMagnification',100);hold on        
        plot((X(ind)),(Y(ind)),'.g');
        fixationframe((round(Y(ind))-2):1:(round(Y(ind)+2)),(round(X(ind)-2)):1:(round(X(ind)+2)))=1;
        sumframe(round(X(ind)), round(Y(ind)))=0;
        %imshow(fixationframe,[]);
        drawnow;
        ind = ind + 1;
    end
end
%
sumframe = sumframe./sumframebinary;
imshow(sumframe/max(max(sumframe)));hold on
ind_nan = isnan(X);
X(ind_nan) = [];
Y(ind_nan) = [];
plot((X(:)),(Y(:)),'-g');hold on;
plot(mean(X), mean(Y),'or');
set(gcf,'PaperPositionMode','auto');
print([pname '\aoslo_PRL'],'-dtiff','-r0');
fprintf('The average PRL (x,y) is %g , %g\n',mean(X),mean(Y));

figure;imagesc(fixationframe);
imwrite(fixationframe,[pname '\fixation.tif'],'tif');

