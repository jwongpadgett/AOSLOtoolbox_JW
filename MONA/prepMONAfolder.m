%%Prep MONA folder for Automontager

%select folder
currentdir =pwd;
prevdir = currentdir;

tempdirname = uigetdir(prevdir,'Please choose a single folder with video files');

prevdir = tempdirname;
cd(tempdirname);
reflectFileList= dir('*reflect.raw');
splitFileList = dir('*phaseContrast.raw');

mkdir('Tiff');
%Save all raw images to Tif
%json?
for i = 1:size(reflectFileList,1)
    currFileName = reflectFileList(i).name;
    imwrite(readMONA(currFileName),['Tiff/', currFileName(1:size(currFileName,2)-4),'.tiff']);
end

for i = 1:size(splitFileList,1)
    currFileName = splitFileList(i).name;
    imwrite(readMONA(currFileName),['Tiff/', currFileName(1:size(currFileName,2)-4),'.tiff']);
end

%createLUT





cd(prevdir);


