function montageimage = makemontage(montageparamfile,varnametoload,secondaryvartoload,badcorrelthreshold,verbose)

if (nargin < 1) || isempty(montageparamfile) ||...
        ~ischar(montageparamfile) || ~exist(montageparamfile,'file')
    disp('You need to provide a mat data file that has the parameters that will be used by makemontage.m');
    warning('Querying user to select a file');

    [fname pname] = uigetfile('*.mat','Please choose the mat file that has the parameters for makemontage.m');
    montageparamfile = strcat(pname,fname);
end

load(montageparamfile,'datafilenames','correlationqueueindex');

if ischar(datafilenames{1}) %#ok<USENS>
    toloaddatfiles = 1;
else
    toloaddatfiles = 0;
end

if toloaddatfiles && ((nargin < 2) || isempty(varnametoload))
    disp('You need to provide the name of the variable to load from the data files');
    warning('You need to choose the variable that is the reference image');

    filewithvar = datafilenames{1};

    varsinfile = who('-file',filewithvar);

    varselection = listdlg('ListString',varsinfile,'InitialValue',[],'Name',...
        'Variable Selection','PromptString','Please select variable that is the reference image');

    if isempty(varselection)
        disp('You did not select any variable');
        error('Type ''help makemontage'' usage');
    else
        if length(varselection) >= 2
            disp('Program can only load one variable');
            warning('Loading only the first variable name selecting');
            varselection = varselection(1);
        end

        varnametoload = varsinfile{varselection};
    end
end

if (nargin < 3) || isempty(secondaryvartoload)
    secondaryvartoload = [];
    toloadsecondaryimage = 0;
    istheresecondayvariable = 0;
else
    if isscalar(secondaryvartoload) || iscell(secondaryvartoload) || ischar(secondaryvartoload)
        istheresecondayvariable = 1;
        if isscalar(secondaryvartoload) && (secondaryvartoload == 1)
            toloadsecondaryimage = 1;
            disp('You have selected the option of choosing the secondary image variable name');

            filewithvar = datafilenames{1};

            varsinfile = who('-file',filewithvar);

            varselection = listdlg('ListString',varsinfile,'InitialValue',[],'Name',...
                'Variable Selection','PromptString','Please select variable that is the reference image');

            if isempty(varselection)
                disp('You did not select any variable');
                error('Type ''help makemontage'' usage');
            else
                if length(varselection) >= 2
                    disp('Program can only load one variable');
                    warning('Loading only the first variable name selecting');
                    varselection = varselection(1);
                end

                secondaryvartoload = varsinfile{varselection};
            end
        end

        if ischar(secondaryvartoload)
            toloadsecondaryimage = 1;
        end

        if iscell(secondaryvartoload)
            toloadsecondaryimage = 0;
        end
    else
        istheresecondayvariable = 0;
        toloadsecondaryimage = 0;
    end
end


if (nargin < 4) || isempty(badcorrelthreshold)
    badcorrelthreshold = 0.6;
end

if (nargin < 5) || isempty(verbose)
    verbose = 0;
end

numberofrefstoanalyse = length(datafilenames);

interrefimageshifts = zeros(numberofrefstoanalyse,2);
interrefimagemaxvals = zeros(numberofrefstoanalyse);
interrefimagesecondpeaks = zeros(numberofrefstoanalyse);
interrefimagenoises = zeros(numberofrefstoanalyse);
maxmemmultiplier = 0.75;

if toloaddatfiles
    load(datafilenames{1},varnametoload);
    renamestring = strcat('montageimage =',varnametoload,';');
    eval(renamestring);
else
    montageimage = datafilenames{1};
end

indiceswithpixeldata = find(montageimage(:) >= 2);
indiceswithnopixeldata = find(montageimage(:) <= 1);
randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
montageimage(indiceswithnopixeldata) = montageimage(randpixeldataindcies);
            
if istheresecondayvariable
    if toloadsecondaryimage
        load(datafilenames{1},secondaryvartoload);
        renamestring = strcat('secondarymontageimage =',secondaryvartoload,';');
        eval(renamestring);
        maxmemmultiplier = 0.4;
    else
        secondarymontageimage = secondaryvartoload{1};
    end
end

orderofcorrelation = correlationqueueindex(:,1); %#ok<COLND>

currentnumbertocorrelate = 2;
imagecounter = 2;
currentmontagenumber = 1;

if toloaddatfiles
    renamestring = strcat('testimage =',varnametoload,';');
end

analysisprog = waitbar(0,'Correlating Thumbnails');
oldposition = get(analysisprog,'Position');
newstartindex = round(oldposition(1) + (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20)...
    oldposition(3) oldposition(4)];
set(analysisprog,'Position',newposition);

while 1
    if isempty(find(orderofcorrelation == currentnumbertocorrelate,1))
        break
    end
    
    if toloaddatfiles
        load(datafilenames{orderofcorrelation == currentnumbertocorrelate},varnametoload);
        eval(renamestring);
    else
        testimage = datafilenames{[orderofcorrelation == currentnumbertocorrelate]};
    end

    if ~isempty(testimage)
        indiceswithpixeldata = find(testimage (:) >= 2);
        indiceswithnopixeldata = find(testimage (:) <= 1);
        randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
        testimage(indiceswithnopixeldata) = testimage (randpixeldataindcies);

        [correlation shifts peaks_noise] = corr2d(montageimage,testimage,1);
        peakratio = peaks_noise(2) / peaks_noise(1);
    end

    if peakratio <= badcorrelthreshold
        clear correlation;
        currentrefsize = [size(montageimage,2),size(montageimage,1)];
        currenttestsize = [size(testimage,2),size(testimage,1)];

        indicestoputrefmatrix_h = [1:currentrefsize(1)];
        indicestoputrefmatrix_v = [1:currentrefsize(2)];

        indicestoputtestmatrix_h = (floor((currentrefsize(1) - currenttestsize(1)) / 2) -...
            round(shifts(1))) + [0:currenttestsize(1) - 1];
        if indicestoputtestmatrix_h(1) < 1
            diffinhoriindex = 1 - indicestoputtestmatrix_h(1);
            indicestoputtestmatrix_h = indicestoputtestmatrix_h + diffinhoriindex;
            indicestoputrefmatrix_h = indicestoputrefmatrix_h + diffinhoriindex;
        end
        newrefsize_h = max(indicestoputtestmatrix_h(end),indicestoputrefmatrix_h(end));

        indicestoputtestmatrix_v = (floor((currentrefsize(2) - currenttestsize(2)) / 2) -...
            round(shifts(2))) + [0:currenttestsize(2) - 1];
        if indicestoputtestmatrix_v(1) < 1
            diffinvertindex = 1 - indicestoputtestmatrix_v(1);
            indicestoputtestmatrix_v = indicestoputtestmatrix_v + diffinvertindex;
            indicestoputrefmatrix_v = indicestoputrefmatrix_v + diffinvertindex;
        end
        newrefsize_v = max(indicestoputtestmatrix_v(end),indicestoputrefmatrix_v(end));

        [largestblockofmem unitofmemory] = getmemorystatus();

        switch lower(unitofmemory)
            case 'kb'
                memdivisor = 2 ^ 10;
            case 'mb'
                memdivisor = 2 ^ 20;
            case 'gb'
                memdivisor = 2 ^ 30;
        end

        memorysizeofrefimage = (newrefsize_h * newrefsize_v * 8) / memdivisor;

        if memorysizeofrefimage < (maxmemmultiplier * largestblockofmem)
            newmontageimage = zeros(newrefsize_v,newrefsize_h);

            refsummatrix = zeros(newrefsize_v,newrefsize_h);
            testsummatrix = zeros(newrefsize_v,newrefsize_h);

            newmontageimage(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = montageimage;
            pixelswithrefimagedata = ones(size(montageimage));
            pixelswithrefimagedata(montageimage == 0) = 0;
            refsummatrix(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = pixelswithrefimagedata;

            newmontageimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) =...
                newmontageimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) + testimage;
            pixelswithtestimagedata = ones(size(testimage));
            pixelswithtestimagedata(testimage == 0) = 0;
            testsummatrix(indicestoputtestmatrix_v,indicestoputtestmatrix_h) = pixelswithtestimagedata ;

            summatrix = refsummatrix + testsummatrix;
            summatrix(summatrix < 1) = 1;

            newmontageimage = newmontageimage ./ summatrix;
            indiceswithpixeldata = find(newmontageimage(:) >= 2);
            indiceswithnopixeldata = find(newmontageimage(:) <= 1);
            randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
            newmontageimage(indiceswithnopixeldata) = newmontageimage(randpixeldataindcies);
            
            montageimage = newmontageimage;

            if istheresecondayvariable
                if toloadsecondaryimage
                    load(datafilenames{orderofcorrelation == currentnumbertocorrelate},secondaryvartoload);
                    eval(['secondarytestimage = ', secondaryvartoload,';']);
                else
                    secondarytestimage = secondaryvartoload{orderofcorrelation == currentnumbertocorrelate};
                end

                newsecondarymontageimage = zeros(newrefsize_v,newrefsize_h);

                newsecondarymontageimage(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = secondarymontageimage;
                newsecondarymontageimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) =...
                    newsecondarymontageimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) + secondarytestimage;
                newsecondarymontageimage = newsecondarymontageimage ./ summatrix;
                secondarymontageimage = newsecondarymontageimage;
            end
        else
            nameofmontageimage = [montageimage,'_',num2str(currentmontagenumber)];

            if ~istheresecondayvariable
                eval(nameofmontageimage,'= montageimage;');
            else
                eval(nameofmontageimage,'= secondarymontageimage;');
            end

            save(montageparamfile,nameofmontageimage);

            montageimage = testimage;

            orderofcorrelation = correlationqueueindex(:,imagecounter); %#ok<COLND>

            currentnumbertocorrelate = 2;
            currentmontagenumber = currentmontagenumber + 1;
        end

    end

    imagecounter = imagecounter + 1;
    currentnumbertocorrelate = currentnumbertocorrelate + 1;

    if (imagecounter > numberofrefstoanalyse) || (currentnumbertocorrelate >= numberofrefstoanalyse) ||...
            isempty(find(orderofcorrelation == currentnumbertocorrelate)) %#ok<EFIND>
        break;
    end

    prog = (imagecounter - 1) ./ (numberofrefstoanalyse - 1);
    waitbar(prog,analysisprog);
end

close(analysisprog);

if istheresecondayvariable
    montageimage = secondarymontageimage;
end

if verbose
    mymap = repmat([0:255]' / 256,1,3);

    figure;
    image(montageimage);
    colormap(mymap);
    axis off;
    truesize
end


%--------------------------------------------------------------------------

function [largestmemblock unit] = getmemorystatus()

memorystrings = evalc('feature(''memstats'')');
memorystrings = regexp(memorystrings,'\n','split');
memorystrings = memorystrings(:);
for stringcounter = 1:length(memorystrings)
    memorystrings(stringcounter) = strtrim(memorystrings(stringcounter));
end
largestblocksizestringindex = find(strcmp('Largest Contiguous Free Blocks:',memorystrings));
stringwithlargestmemblock = char(memorystrings(largestblocksizestringindex + 1));
blankspaceindices = strfind(stringwithlargestmemblock,' ');
blankspaceindices = blankspaceindices(:);
startofwhitespaces = blankspaceindices(find(diff([blankspaceindices(1);blankspaceindices]) > 1) - 1) + 1;
endofwhitespaces = blankspaceindices(diff([blankspaceindices(1);blankspaceindices]) > 1) - 1;
bracketindex = strfind(stringwithlargestmemblock,']');
bracketindex = bracketindex(:);

startindexofblocksize = min(startofwhitespaces(startofwhitespaces > bracketindex));
endindexofblocksize = min(endofwhitespaces(endofwhitespaces > bracketindex));

largestmemblock = str2double(stringwithlargestmemblock(startindexofblocksize:endindexofblocksize));

startindexofunitstring = min(endofwhitespaces(endofwhitespaces > endindexofblocksize)) - 1;
endindexofunitstring = min(endofwhitespaces(endofwhitespaces > startindexofunitstring));

unit = stringwithlargestmemblock(startindexofunitstring:endindexofunitstring);

%--------------------------------------------------------------------------