function paramdatafile = getmontageparameters(datafilenames,varnametoload,thumbnailfactor,...
    badcorrelthreshold,datafiletosave,verbose)

if (nargin < 1) || isempty(datafilenames) || ~iscell(datafilenames)
    currentdir = pwd;
    dirname = uigetdir(currentdir,'Please choose a single folder with data files');

    filelist = {};
    listboxstrings = {};
    dirstucture = dir(dirname);
    for structurecounter = 1:length(dirstucture)
        if ~(dirstucture(structurecounter).isdir)
            tempname = dirstucture(structurecounter).name;
            fileextension = upper(tempname(end-2:end));
            if strcmp(fileextension,'MAT')
                filelist{end + 1} = strcat(dirname,'\',tempname);
                listboxstrings{end + 1} = tempname;
            end
        end
    end

    if isempty(listboxstrings)
        disp('No .mat data files in selected folders, exiting....');
        error('Type ''help getmontageparameters'' usage');
    end

    selection = listdlg('ListString',listboxstrings,'InitialValue',[],'Name',...
        'File Select','PromptString','Please select data files with refrence images');

    if isempty(selection)
        disp('You did not select any mat data files');
        error('Type ''help getmontageparameters'' usage');
    end
    datafilenames = filelist(selection);
    toloaddatafiles = 1;

    cd(currentdir);
else
    if ischar(datafilenames{1})
        toloaddatafiles = 1;
    else
        if isnumeric(datafilenames{1})
            toloaddatafiles = 0;
        else
            disp('You need to provide either a cell array of strings/2D numeric image matrices');
            error('Type ''help getmontageparameters'' usage');
        end
    end
end

if toloaddatafiles && ((nargin < 2) || isempty(varnametoload))
    disp('The function requires the name of the variable to load from data files');
    warning('You need to choose the variable that is the reference image');

    toexit = 0;
    filecounter = 1;
    while ~toexit
        if exist(datafilenames{filecounter},'file')
            toexit = 1;
            filewithvar = datafilenames{filecounter};
        else
            filecounter = filecounter + 1;
        end
    end

    varsinfile = who('-file',filewithvar);

    varselection = listdlg('ListString',varsinfile,'InitialValue',[],'Name',...
        'Variable Selection','PromptString','Please select variable that is the reference image');

    if isempty(varselection)
        disp('You did not select any variable');
        error('Type ''help getmontageparameters'' usage');
    else
        if length(varselection) >= 2
            disp('Program can only load one variable');
            warning('Loading only the first variable name selecting');
            varselection = varselection(1);
        end

        varnametoload = varsinfile{varselection};
    end
end

if (nargin < 3) || isempty(thumbnailfactor)
    thumbnailfactor = 5;
end

if (nargin < 4) || isempty(badcorrelthreshold)
    badcorrelthreshold = 0.6;
end

if (nargin < 6) || isempty(verbose)
    verbose = 0;
end

numberofrefstoanalyse = length(datafilenames);

isvargoodforanalysis = zeros(numberofrefstoanalyse,1);
for counter = 1:numberofrefstoanalyse
    if toloaddatafiles
        if ~exist(datafilenames{counter},'file')
            continue
        else
            varsinfile = who('-file',datafilenames{counter});

            if sum(strcmp(varsinfile,varnametoload))
                isvargoodforanalysis(counter) = 1;
            end
        end
    else
        tempvariable = datafilenames{counter};
        if isnumeric(tempvariable)
            isvargoodforanalysis(counter) = 1;
        end
    end
end

datafilenames = datafilenames(isvargoodforanalysis == 1);
datafilenames = datafilenames(:);
numberofrefstoanalyse = length(datafilenames);

interrefimageshifts_thumbnails = zeros(numberofrefstoanalyse,numberofrefstoanalyse,2);
interrefimagemaxvals_thumbnails = ones(numberofrefstoanalyse,numberofrefstoanalyse);
interrefimagesecondpeaks_thumbnails = ones(numberofrefstoanalyse,numberofrefstoanalyse);
interrefimagenoises_thumbnails = ones(numberofrefstoanalyse,numberofrefstoanalyse);
correlationqueueindex = zeros(numberofrefstoanalyse,numberofrefstoanalyse);
probablememoryusage = zeros(numberofrefstoanalyse,numberofrefstoanalyse,2);

refsstitchedinthisloop = [];

thumbnailprog = waitbar(0,'Correlating Thumbnails');
oldposition = get(thumbnailprog,'Position');
newstartindex = round(oldposition(1) - (oldposition(3) / 2));
newposition = [newstartindex (oldposition(4) + 20)...
    oldposition(3) oldposition(4)];
set(thumbnailprog,'Position',newposition);

for counter = 1:numberofrefstoanalyse
    currentindexintomatrix = 1;

    if toloaddatafiles
        load(datafilenames{counter},varnametoload);
        renamestring = strcat('referenceimage =',varnametoload,';');
        eval(renamestring);
    else
        referenceimage = datafilenames{counter};
    end

    referenceimage_thumbnail = makethumbnail(referenceimage,thumbnailfactor,thumbnailfactor);
    indiceswithpixeldata = find(referenceimage_thumbnail(:) >= 2);
    indiceswithnopixeldata = find(referenceimage_thumbnail(:) <= 1);
    randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
    referenceimage_thumbnail(indiceswithnopixeldata) = referenceimage_thumbnail(randpixeldataindcies);
    
    correlationqueueindex(counter,counter) = 1;
    correlationqueueindex_number = 2;
    refstostitch = setdiff([1:numberofrefstoanalyse]',[1:counter]');

    if isempty(refstostitch)
        continue;
    end

    analysisprog = waitbar(0,'Stitching Segments Together');
    oldposition = get(analysisprog,'Position');
    newstartindex = round(oldposition(1) + (oldposition(3) / 2));
    newposition = [newstartindex (oldposition(4) + 20)...
        oldposition(3) oldposition(4)];
    set(analysisprog,'Position',newposition);

    while 1
        if currentindexintomatrix == 1
            waitbar(0,analysisprog,'Stitching Segments Together');
        end

        indexintomatrix = refstostitch(currentindexintomatrix);

        if toloaddatafiles
            filenametoload = datafilenames{indexintomatrix};
            load(filenametoload,varnametoload);
            renamestring = strcat('testimage =',varnametoload,';');
            eval(renamestring);
        else
            testimage = datafilenames{indexintomatrix};
        end

        if ~isempty(testimage)
            testimage_thumbnail = makethumbnail(testimage,thumbnailfactor,thumbnailfactor);
            indiceswithpixeldata = find(testimage_thumbnail(:) >= 2);
            indiceswithnopixeldata = find(testimage_thumbnail(:) <= 1);
            randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
            testimage_thumbnail(indiceswithnopixeldata) = testimage_thumbnail(randpixeldataindcies);
    
            [correlation shifts peaks_noise] = corr2d(referenceimage_thumbnail,testimage_thumbnail,1);

            peakratio = peaks_noise(2) / peaks_noise(1);
        end

        if peakratio <= badcorrelthreshold
            currentrefsize = [size(referenceimage_thumbnail,2),size(referenceimage_thumbnail,1)];
            currenttestsize = [size(testimage_thumbnail,2),size(testimage_thumbnail,1)];

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

            memorysizeofrefimage_mb = (((newrefsize_h * newrefsize_v) * (thumbnailfactor ^ 2)) * 8) / (2 ^ 20);
            memorysizeofrefimage_gb = (((newrefsize_h * newrefsize_v) * (thumbnailfactor ^ 2)) * 8) / (2 ^ 30);

            interrefimageshifts_thumbnails(indexintomatrix,counter,:) = reshape(shifts,[1 1 2]);
            interrefimagemaxvals_thumbnails(indexintomatrix,counter) = peaks_noise(1);
            interrefimagesecondpeaks_thumbnails(indexintomatrix,counter) = peaks_noise(2);
            interrefimagenoises_thumbnails(indexintomatrix,counter) = peaks_noise(3);
            correlationqueueindex(indexintomatrix,counter) = correlationqueueindex_number;
            probablememoryusage(indexintomatrix,counter,:) = cat(3,memorysizeofrefimage_mb,memorysizeofrefimage_gb);

            correlationqueueindex_number = correlationqueueindex_number + 1;
            refsstitchedinthisloop = [refsstitchedinthisloop;refstostitch(currentindexintomatrix)];

            newreferenceimage = zeros(newrefsize_v,newrefsize_h);
            refsummatrix = zeros(newrefsize_v,newrefsize_h);
            testsummatrix = zeros(newrefsize_v,newrefsize_h);

            newreferenceimage(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = referenceimage_thumbnail;
            pixelswithrefimagedata = ones(size(referenceimage_thumbnail));
            pixelswithrefimagedata(referenceimage_thumbnail == 0) = 0;
            refsummatrix(indicestoputrefmatrix_v,indicestoputrefmatrix_h) = pixelswithrefimagedata;

            newreferenceimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) =...
                newreferenceimage(indicestoputtestmatrix_v,indicestoputtestmatrix_h) + testimage_thumbnail;
            pixelswithtestimagedata = ones(size(testimage_thumbnail));
            pixelswithtestimagedata (testimage_thumbnail == 0) = 0;
            testsummatrix(indicestoputtestmatrix_v,indicestoputtestmatrix_h) = pixelswithtestimagedata ;

            summatrix = refsummatrix + testsummatrix;
            summatrix(summatrix == 0) = 1;
            newreferenceimage = newreferenceimage ./ summatrix;
            
            indiceswithpixeldata = find(newreferenceimage(:) >= 2);
            indiceswithnopixeldata = find(newreferenceimage(:) <= 1);
            randpixeldataindcies = floor(rand(length(indiceswithnopixeldata),1) * length(indiceswithpixeldata)) + 1;
            newreferenceimage(indiceswithnopixeldata) = newreferenceimage(randpixeldataindcies);

            referenceimage_thumbnail = newreferenceimage;
        else
            interrefimageshifts_thumbnails(indexintomatrix,counter,:) = reshape([0 0],[1 1 2]);
            interrefimagemaxvals_thumbnails(indexintomatrix,counter) = 0;
            interrefimagesecondpeaks_thumbnails(indexintomatrix,counter) = 0;
            interrefimagenoises_thumbnails(indexintomatrix,counter) = 0;
        end

        currentindexintomatrix = currentindexintomatrix + 1;

        if currentindexintomatrix > length(refstostitch)
            currentindexintomatrix = 1;
            refstostitch = setdiff(refstostitch,refsstitchedinthisloop);
            if isempty(refstostitch) || isempty(refsstitchedinthisloop)
                refsnotstitched = sort(refstostitch);
                break;
            end

            refsstitchedinthisloop = [];
            waitbar(0,analysisprog,'Temp');
        end

        prog = currentindexintomatrix ./ length(refstostitch);
        waitbar(prog,analysisprog);
    end
    close(analysisprog);

    prog = counter / numberofrefstoanalyse;
    waitbar(prog,thumbnailprog);
end

close(thumbnailprog);

indicesofunstitchedrefs = find(sum(interrefimagemaxvals_thumbnails,2) == 0);
indicesofstitchedrefs = setdiff([1:numberofrefstoanalyse]',indicesofunstitchedrefs(:));
datafilenames_all = datafilenames;
datafilenames = datafilenames(indicesofstitchedrefs);
interrefimageshifts_thumbnails = interrefimageshifts_thumbnails(:,indicesofstitchedrefs,:);
interrefimagemaxvals_thumbnails = interrefimagemaxvals_thumbnails(:,indicesofstitchedrefs);
interrefimagesecondpeaks_thumbnails = interrefimagesecondpeaks_thumbnails(:,indicesofstitchedrefs);
interrefimagenoises_thumbnails = interrefimagenoises_thumbnails(:,indicesofstitchedrefs);
correlationqueueindex = correlationqueueindex(:,indicesofstitchedrefs);
probablememoryusage = probablememoryusage(:,indicesofstitchedrefs,:);

if (nargin < 5) || isempty(datafiletosave) || ~ischar(datafiletosave)
    [fname pname] = uiputfile('*.mat','Please enter file name to save data');
    paramdatafile = strcat(pname,fname);
else
    paramdatafile = datafiletosave;
end

save(paramdatafile,'datafilenames','interrefimageshifts_thumbnails','interrefimagemaxvals_thumbnails',...
    'interrefimagesecondpeaks_thumbnails','interrefimagenoises_thumbnails','correlationqueueindex',...
    'probablememoryusage','datafilenames_all','indicesofunstitchedrefs',...
    'thumbnailfactor','badcorrelthreshold','indicesofstitchedrefs');

if verbose
    mymap = repmat([0:255]' / 255,1,3);

    figure;
    image(referenceimage_thumbnail);
    colormap(mymap);
    axis off;
    truesize;
end