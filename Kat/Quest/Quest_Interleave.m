%code to perform interleaved QUEST experiments
%written by W. Tuten, July 8th, 2010

clear all, close all;

bmpimage = zeros(256,256);  %For use in FPGA; does not need to equal AOSLO field size!
[x,y] = size(bmpimage);

xcenter = x/2; %stimulus is centered in this program
ycenter = x/2;

stimdiam = [2.7 3.1 6.4 13 21 28 33 60];        %stimulus diameters in minutes, from Inui JOSA 1981
fieldsize = 2.2;                                %fieldsize in degrees
fieldpix = 512;                                 %fieldsize in pixels
stims = (stimdiam/60)*(fieldpix/fieldsize);     %stimuli in pixels
halfstims = round(stims/2);                     %stimuli half-lengths
stimnum = size(halfstims,2);                    %number of stimuli

pathname = [pwd '\BMP_files'];
n = 1;
button = 'Quest_Circles';
mkdir(pathname,button)
cdir = [pathname '\' button '\'];
name2 = 'Quest_mapping.map';
mapname = [cdir name2];
fid = fopen(mapname,'wt');

for col = 1:stimnum
    for radius = 1:halfstims(1,col)
        theta = [0:0.001:2*pi];
        xcircle = radius*cos(theta)+ xcenter; ycircle = radius*sin(theta)+ ycenter;
        xcircle = round(xcircle); ycircle = round(ycircle);
        nn = size(xcircle); nn = nn(2);
        xymat = [xcircle' ycircle'];
        for point = 1:nn
            row = xymat(point,2); col2 = xymat(point,1);
            bmpimage(row,col2)= 1;
        end
    end
    bmpimage(ycenter,xcenter)=1;
    fname = [cdir '\analog' num2str(n+1) '.bmp'];
    imwrite(bmpimage,fname,'bmp');
    fprintf(fid,'%g\t %.2f\n',n+1,stimdiam(1,col));
    n = n+1;
end

fclose(fid);

figure, imshow(bmpimage)

trialsperQUEST = 10;
numstimuli = size(stimdiam,2);
[framenum radius] = textread(mapname, '%d %.2f');
imagenum = framenum+1;

tGuess=0.05;
tGuessSd=1;
pThreshold=0.82;
beta=3.5;delta=0.01;gamma=0.5; %grain = 0.01;


name3 = 'Quest_psyfile.txt';
psyfilename = [cdir name3]; 
fid2 = fopen(psyfilename,'w');

randorder = randperm(numstimuli);
for iteration = 1:numstimuli
    q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
    q.normalizePdf=1;
    whichstim = randorder(iteration);
    imname = [cdir 'analog' num2str(whichstim+1) '.bmp'];
    RefIm = imread(imname);
    stimsize = stimdiam(whichstim);
    for trial = 1:trialsperQUEST
        randorder = randperm(numstimuli);
        tTest=QuestQuantile(q);
        TestIm = RefIm.*tTest;
        imshow(TestIm);
        response = input('Do you see the circle? Y = 1; N = 0: ');
        q=QuestUpdate(q,tTest,response);
    end
    
    t=QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
    sd=QuestSd(q);
    fprintf(fid2,'Final threshold estimate (mean±sd) is %.3f ± %.3f\t Stimulus Size: %.2f\n',t,sd, stimsize);
    %q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma);
    clear q
end
  fclose(fid2)
  



% theThreshold(trial,1) = QuestMean(q);
% figure;
% plot(theThreshold);
% xlabel('Trial number');
% ylabel('Min Vis Spot Intensity');
% title('Threshold estimate vs. Trial Number');

