%Survey videos,

blinkthreshold =10;
minimummeanlevel = 90;
currentdir = pwd;
screensize = get(0,'ScreenSize');
if ispc
    pathslash = '\';
else
    pathslash = '/';
end

videosnotanalysed = {};
thrownexceptions = {};

% Get info from the user regarding the directories where the videos are
% present and then load the video names into a .

prompt={'How many directories are your videos in?'};
name='Directory Query';
numlines=1;
defaultanswer={'1'};

answer = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(answer)
    disp('You need to supply the number of directories where you have placed videos,Exiting...');
    return;
end
numdirectories = str2double(answer{1});

directorynames = cell(numdirectories,1);
listboxstrings = {};
filelist = {};

prevdir = currentdir;
for directorycounter = 1:numdirectories
    tempdirname = uigetdir(prevdir,'Please choose a single folder with video files');
    if tempdirname == 0
        disp('You pressed cancel instead of choosing a driectory');
        warning('Continuing...');
        continue
    end
    directorynames{directorycounter} = tempdirname;
    dirstucture = dir(tempdirname);
    for structurecounter = 1:length(dirstucture)
        if ~(dirstucture(structurecounter).isdir)
            tempname = dirstucture(structurecounter).name;
            fileextension = upper(tempname(end-2:end));
            if strcmp(fileextension,'AVI')
                filelist{end + 1} = strcat(tempdirname,pathslash,tempname);
                listboxstrings{end + 1} = tempname;
            end
        end
    end
    prevdir = tempdirname;
    cd(tempdirname);
end

% If the directory has no video, exit
if isempty(listboxstrings)
    error('No AVI videos in selected folders, exiting....');
end

selection = listdlg('ListString',listboxstrings,'InitialValue',[],'Name',...
    'File Select','PromptString','Please select videos to stabilize');

% If the user does not choose any video, exit
if isempty(selection)
    disp('You have not selected any video, Exiting...');
    return;
end
numfiletoanalyse = length(selection);


for i =1:5
    videotoanalyse = filelist{selection(ceil(rand()*numfiletoanalyse))}; 
    getblinkframes(videotoanalyse, blinkthreshold, minimummeanlevel,1,0);
end
