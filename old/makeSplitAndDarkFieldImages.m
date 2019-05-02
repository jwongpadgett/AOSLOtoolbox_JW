function makeSplitAndDarkFieldImages

    %substract two raw split (.tiff) images already registered
    [filename, pathname] = uigetfile('*.tiff','Select PMT2 and PMT3 images','MultiSelect', 'on');
    PMT2Im = double(imread([pathname filename{1}]));
    PMT3Im = double(imread([pathname filename{2}]));

    figure; imagesc(PMT2Im); colormap gray
    figure; imagesc(PMT3Im); colormap gray

    splitIm = (PMT2Im-PMT3Im)./(PMT2Im+PMT3Im); 
    darkFieldIm = (PMT2Im+PMT3Im);

    splitImSc = (splitIm+1)./2;
    darkFieldImSc = darkFieldIm./max(max(darkFieldIm));

    figure; imagesc(splitIm); colormap gray
    splitimagename = strcat([pathname filename{1}(1:end-4)],'_splitimage.tiff');
    imwrite(splitImSc,splitimagename,'Compression','none');

    figure; imagesc(darkFieldIm); colormap gray
    DFimagename = strcat([pathname filename{1}(1:end-4)],'_darkfieldimage.tiff');
    imwrite(darkFieldImSc, DFimagename,'Compression','none');
end

