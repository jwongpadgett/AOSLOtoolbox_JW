function choppedimage = chopupimage(oldimage)
% chopupimage.m. This is a utility program that can be used to carve out areas within a image. Typically this program can
% be used to delete areas that might be distorted within stabilised images to prevent their adverse effects when large montages
% are being made.
%
% Usage: choppedimage = chopupimage(oldimage)
% oldimage          - This is the original image/s. Images can be passed either as a 3D(2D if only a single image is passed) double
%                         matrix or a cell array of 2D matrices.
%
% choppedimage  - The carved out image/s. The variable type returned is the same type that was passed to the function.
%
%
% Program Creator: Girish Kumar
% Make Peaceful Love Not War

% Error check if the user has provided a image to chop up
if (nargin < 1) || isempty(oldimage)
    disp('No image/s provided');
    error('Type ''help chopupimage'' for help');
end

if ischar(oldimage) || isstruct(oldimage)
    disp('chopupimage.m requires a cell array of images/3D matrix of 2D images');
    error('Type ''help chopupimage'' for help');
end

if iscell(oldimage)
    inputargiscellarray = 1;
else
    inputargiscellarray = 0;
end

if inputargiscellarray
    tempimage = oldimage{1};
    if ~isnumeric(tempimage)
        disp('chopupimage.m requires a cell array of images/3D matrix of 2D images');
        error('Type ''help chopupimage'' for help');
    end
    numimages = length(oldimage);
    choppedimage = cell(numimages,1);
else
    tempimage = oldimage(:,:,1);
    
    imagewidth = size(tempimage,2);
    imageheight = size(tempimage,1);
    numimages = size(oldimage,3);
    
    choppedimage = zeros(imageheight,imagewidth,numimages);
end


mymap = repmat([0:255]' / 256,1,3);
fighandle = figure;
imagehandle = image(tempimage);
colormap(mymap);
axis off
truesize;

for imagecounter = 1:numimages
    if inputargiscellarray
        tempimage = oldimage{imagecounter};
        if ~isnumeric(tempimage)
            warning(['Data at ',num2str(imagecounter),' is not numeric!!, Skipping']);
            continue;
        end
    else
        tempimage = oldimage(:,:,imagecounter);
    end

    indiceswithnoimagedata = find(tempimage <= 0);
    if ~isempty(indiceswithnoimagedata)
        indiceswithnoimagedata = indiceswithnoimagedata(:);
    end

    toexit = 0;

    while ~toexit
        xs = zeros(4,1);
        ys = zeros(4,1);

        figure(fighandle);
        set(gcf,'Name','Click outside the image to exit');
        pause(0.25);

        for pointcounter = 1:4
            switch pointcounter
                case 1
                    set(fighandle,'Name','Left Border');
                    title('Left Border');
                case 2
                    set(fighandle,'Name','Right Border');
                    title('Right Border');
                case 3
                    set(fighandle,'Name','Top Border');
                    title('Top Border');
                case 4
                    set(fighandle,'Name','Bottom Border');
                    title('Bottom Border');
            end

            [x y] = ginput(1);

            xs(pointcounter) = round(x);
            ys(pointcounter) = round(y);
        end

        x_start = xs(1);
        x_end = xs(2);

        if x_start > x_end
            disp('Left border cannot be greater than right border');
            warning('Interchanging border indices');
            temp = x_start;
            x_start = x_end;
            x_end = temp;
        end

        y_start = ys(3);
        y_end = ys(4);

        if y_start > y_end
            disp('Top border cannot be greater than bottom border');
            warning('Interchanging border indices');
            temp = y_start;
            y_start = y_end;
            y_end = temp;
        end

        if (x_start > 1) && (x_end < imagewidth) &&...
                (y_start > 1) && (y_end < imageheight)
            tempimage(y_start:y_end,x_start:x_end) = 0;

            indiceswithnoimagedata = find(tempimage <= 0);
            if ~isempty(indiceswithnoimagedata)
                indiceswithnoimagedata = indiceswithnoimagedata(:);
            end
            set(imagehandle,'CData',tempimage);
        else
            toexit = 1;
        end
    end
    
    tempimage(indiceswithnoimagedata) = 0;
    tempchoppedimage = tempimage;

    if inputargiscellarray
        choppedimage{imagecounter} = tempchoppedimage;
    else
        choppedimage(:,:,imagecounter) = tempchoppedimage;
    end
end

close(fighandle);