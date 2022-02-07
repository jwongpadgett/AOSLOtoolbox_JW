%CropAndScaleAll will display all confocal images in Cropping window. 
%Will crop and scale all channels into folder AutoCrop_PPDxPPD
%Input final PPD, and initial X and Y PPD.
%Double click after creating rectangle for cropping
function [] = CropAndScaleAll(finalPPD,initXPPD,initYPPD)
    perX=100*finalPPD/initXPPD;
    perY=100*finalPPD/initYPPD;
    finalPPD = int2str(finalPPD);
    pname = uigetdir;
    %a= dir([pname '\ch1vid*_confocal.tif*']);
    a= dir([pname '\ch1vid*.tif*']);
    [numCh1 junk] = size(a);
    if(exist([pname '\AutoCrop_' finalPPD 'PPD'])~=7)
       mkdir([pname '\AutoCrop_' finalPPD 'PPD']); 
    end
    f = fopen([pname '\AutoCrop_' finalPPD 'PPD\ScaledBy' num2str(floor(perX)) 'x' num2str(floor(perY)) '.txt'],'w');
    fclose(f);
    for ch1Num = 1:numCh1
        disp(['Preparing tif' int2str(ch1Num) '/' int2str(numCh1)]); 
        fileName = a(ch1Num).name;
        origIm = imread([pname '/' fileName]);

        i = sscanf(fileName,'ch1vid_%04d.tiff');
        %i = sscanf(fileName,'ch1vid_%04d_confocal.tif');
        newtifName=[pname '/' sprintf(['AutoCrop_' finalPPD 'PPD/v%03d_confocal.tif'],i)];
        newtifName_darkfield=[pname '/' sprintf(['AutoCrop_' finalPPD 'PPD/v%03d_darkfield.tif'],i)];
        newtifName_splitimage=[pname '/' sprintf(['AutoCrop_' finalPPD 'PPD/v%03d_splitimage.tif'],i)];
        [croppedIm, rect] =imcrop(origIm);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.01,0.95]);
        
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
        imwrite(croppedIm, newtifName);

        im_darkfield=[pname '/' sprintf('ch2vid_%04d_darkfield.tiff',i)];
        %im_darkfield=[pname '/' sprintf('ch1vid_%04d_darkfield.tif',i)];
        im=imread(im_darkfield);
        croppedIm=imcrop(im,rect);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.01,0.95]);
        
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
        imwrite(croppedIm,newtifName_darkfield);

        im_splitimage=[pname '/' sprintf('ch2vid_%04d_splitimage.tiff',i)];
        %im_splitimage=[pname '/' sprintf('ch1vid_%04d_split.tif',i)];
        im=imread(im_splitimage);
        croppedIm=imcrop(im,rect);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.01,0.95]);
       
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
         imwrite(croppedIm,newtifName_splitimage);
    end
end