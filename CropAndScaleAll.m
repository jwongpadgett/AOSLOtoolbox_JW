%CropAndScaleAll will display all confocal images in Cropping window. 
%Will crop and scale all channels into folder AutoCrop_420x420
%Input scaling factor from scale calculations percentX and percentY
%Double click after selecting all 
function [] = CropAndScaleAll(perX,perY)
    
    pname = uigetdir;
    a= dir([pname '\ch1vid*.tif*']);
    [numCh1 junk] = size(a);
    if(exist([pname '\AutoCrop_420x420'])~=7)
       mkdir([pname '\AutoCrop_420x420']); 
    end
    f = fopen([pname '\AutoCrop_420x420\ScaledBy' num2str(floor(perX)) 'x' num2str(floor(perY)) '.txt'],'w');
    fclose(f);
    for ch1Num = 1:numCh1
        disp(['Preparing tif' int2str(ch1Num) '/' int2str(numCh1)]); 
        fileName = a(ch1Num).name;
        origIm = imread([pname '/' fileName]);

        i = sscanf(fileName,'ch1vid_%04d.tiff');
        newtifName=[pname '/' sprintf('AutoCrop_420x420/v%03d_confocal.tif',i)];
        newtifName_darkfield=[pname '/' sprintf('AutoCrop_420x420/v%03d_darkfield.tif',i)];
        newtifName_splitimage=[pname '/' sprintf('AutoCrop_420x420/v%03d_splitimage.tif',i)];
        [croppedIm, rect] =imcrop(origIm);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.1,0.9]);
        
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
        imwrite(croppedIm, newtifName);

        im_darkfield=[pname '/' sprintf('ch2vid_%04d_darkfield.tiff',i)];
        im=imread(im_darkfield);
        croppedIm=imcrop(im,rect);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.1,0.9]);
        
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
        imwrite(croppedIm,newtifName_darkfield);

        im_splitimage=[pname '/' sprintf('ch2vid_%04d_splitimage.tiff',i)];
        im=imread(im_splitimage);
        croppedIm=imcrop(im,rect);
        croppedIm=imadjust(croppedIm,stretchlim(croppedIm,0),[0.1,0.9]);
       
        croppedIm = imresize(croppedIm, [ floor(rect(4)*perY/100) floor(rect(3)*perX/100)]);
         imwrite(croppedIm,newtifName_splitimage);
    end
end