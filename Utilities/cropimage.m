function [croppedimage,varargout] = cropimage(uncroppedimage,sameborder,verbose)
% cropimage.m. This file is a utility program written to crop image/s to a desired size.
%
% Usage: [croppedimage,[imageborders]] = cropimage(uncroppedimage,[verbose]);
% uncroppedimage   - The original image that needs to be croppped.
% sameborder         - If multiple images are provided, this flag determines if the program uses the same crop
%                            borders for all the images (1) or different borders for the images.
% verbose              - If verbose is set to one then the program displays the cropped image. Default is zero.
%
% croppedimage      - The croppped image.
% imageborders       - This arrays stores the borders of the original image in case they are needed.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

% Error check the input arguments
if (nargin < 1) || isempty(uncroppedimage)
    disp('cropimage.m requires atleast one input argument');
    error('Type ''help filterframe'' for usage');
end

if ischar(uncroppedimage) || isstruct(uncroppedimage)
    disp('cropimage.m requires a cell array of images/3D matrix of 2D images');
    error('Type ''help chopupimage'' for help');
end

if (nargin < 2) || isempty(sameborder)
    togetsameborder = 1;
else
    togetsameborder = 0;
end

if (nargin < 3) || isempty(verbose)
    verbose = 0;
end

if iscell(uncroppedimage)
    inputargiscellarray = 1;
else
    inputargiscellarray = 0;
end

% Get the size of the original image
if inputargiscellarray
    tempimage = uncroppedimage{1};
    if ~isnumeric(tempimage)
        disp('Cell array does not contain numeric data');
        error('Exiting...')
    end

    origimagesize = fliplr(size(tempimage));
    numimages = size(uncroppedimage(:),1);
else
    origimagesize = size(uncroppedimage);
    origimagesize = fliplr(origimagesize(1:2));
    numimages = size(uncroppedimage,3);
end

if (numimages > 1) && togetsameborder
    cropquestion = questdlg('Do you want to apply the same crop borders to all images','Crop Question','Yes','No','Yes');
    if isempty(cropquestion)
        disp('You have not made a valid selection');
        warning('Using the same crop border for all images');
        sameborder = 1;
    else
        switch upper(cropquestion(1))
            case 'Y'

                sameborder = 1;
            case 'N'
                sameborder = 0;
        end
    end
end


borders = zeros(numimages,4);
if inputargiscellarray || ~sameborder
    croppedimage = cell(numimages,1);
end

for imagecounter = 1:numimages
    if inputargiscellarray
        imagetocrop = uncroppedimage{imagecounter};
    else
        imagetocrop = uncroppedimage(:,:,imagecounter);
    end

    if (imagecounter == 1) || ~sameborder
        [croppedsize croppedborders] = croptheimage(imagetocrop);
        if sameborder && ~inputargiscellarray
            croppedimage = zeros(croppedsize(2),croppedsize(1),numimages);
        end
    end

    tempimage = imagetocrop(croppedborders(3):croppedborders(4),...
        croppedborders(1):croppedborders(2));

    borders(imagecounter,:) = croppedborders;


    if inputargiscellarray || ~sameborder
        croppedimage{imagecounter} =  tempimage;
    else
        croppedimage(:,:,imagecounter) = tempimage;
    end
end


% Return the borders if asked for
if nargout == 2
    varargout{1} = borders;
end

% Show the original image with the cropped border marked if asked for
% otherwise close the figure window

if verbose
    if inputargiscellarray
        tempimage_uncr = uncroppedimage{1};
    else
        tempimage_uncr = uncroppedimage(:,:,1);
    end

    if inputargiscellarray || ~sameborder
        tempimage_cr = croppedimage{1};
    else
        tempimage_cr = croppedimage(:,:,1);
    end

    croppedimagesize = fliplr(size(tempimage_cr));
    mymap = repmat([0:255]' / 256,1,3);

    imagefigure = figure;
    image(tempimage_uncr);
    colormap(mymap);
    truesize
    hold on;
    title('Cropped Border');

    plot([borders(1,1):borders(1,2)],zeros(croppedimagesize(1),1) + borders(1,3),'r');
    plot([borders(1,1):borders(1,2)],zeros(croppedimagesize(1),1) + borders(1,4),'r');
    plot(zeros(croppedimagesize(1,2),1) + borders(1,1),[borders(1,3):borders(1,4)],'r');
    plot(zeros(croppedimagesize(1,2),1) + borders(1,2),[borders(1,3):borders(1,4)],'r');
    hold off;
end


%--------------------------------------------------------------------------
function [imagesize,imageborders] = croptheimage(fullimage)
% Go through s loop that asks thr user to select the appropriate border,
% the name in the figure window as well as the title of the image informs
% the user what is the current border that need to be selected

fullimage = fullimage(:,:,1);
origimagesize = fliplr(size(fullimage));
mymap = repmat([0:255]' / 256,1,3);

imagefigure = figure;
colormap(mymap);
image(fullimage);
truesize;

imageborders = zeros(4,1);
for bordercounter = 1:4
    switch bordercounter
        case 1
            figure(imagefigure);
            set(imagefigure,'Name','Left Border');
            title('Left Border');
        case 2
            figure(imagefigure);
            set(imagefigure,'Name','Right Border');
            title('Right Border');
        case 3
            figure(imagefigure);
            set(imagefigure,'Name','Top Border');
            title('Top Border');
        case 4
            figure(imagefigure);
            set(imagefigure,'Name','Bottom Border');
            title('Bottom Border');
    end

    [x y] = ginput(1);
    if bordercounter <= 2
        x = round(x);
        imageborders(bordercounter) = x;
    end

    if bordercounter > 2
        y = round(y);
        imageborders(bordercounter) = y;
    end
end

close(imagefigure)

% Error Check the borders to ensure we do look for funny image indices
if imageborders(1) > imageborders(2)
    warning('Left Border cannot smaller than Right border, interchanging values');
    temp = imageborders(1);
    imageborders(1) = imageborders(2);
    imageborders(2) = temp;
end

if imageborders(3) > imageborders(4)
    warning('Top Border cannot smaller than Bottom border, interchanging values');
    temp = imageborders(3);
    imageborders(3) = imageborders(4);
    imageborders(4) = temp;
end

imageborders(1) = max(imageborders(1),1);
imageborders(2) = min(imageborders(2),origimagesize(1));

imageborders(3) = max(imageborders(3),1);
imageborders(4) = min(imageborders(4),origimagesize(2));

imagesize = zeros(1,2);
imagesize(1) = imageborders(2) - imageborders(1) + 1;
imagesize(2) = imageborders(4) - imageborders(3) + 1;


%--------------------------------------------------------------------------