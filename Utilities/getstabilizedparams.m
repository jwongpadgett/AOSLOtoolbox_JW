function [sizeincrement,stabilizedsize,imageborders] = getstabilizedparams(shifts,framesize,maxsizeincrement)
% getstabilizedparams.m. This is a utility program gets the increment in
% size, the size of the stabilized frame and the borders of the
% full stabilized image from which the stabilized frame is taken from.
% Basically since it is easier to place frames into a matrix that is
% symmetric we increase the size of a frame by a specific amount and then
% once we have placed all the frames we use the imageborders to crop the
% image to an appropriate size
% Usage: [sizeincrement,stabilizedsize,imageborders] =
%                    getstabilizedparams(shifts,framesize,maxsizeincrement)
% shifts            - The frameshifts that will used to stabilize the
%                     frames.
% framesize         - The size of the frame, the first element is the width
%                     and second is the height of the frame.
% maxsizeincrement  - The maximum size increment that the user that
%                     determined that the computer is capable of handling
%                     without crashing due to lack of memory. Default size
%                     is 2.
%
% sizeincrement     - The multiple in size that will encompass the entire
%                     stabilized frame.
% stabilizedsize    - The full size of the stabilized frame.
% imageborders      - The indices from the full stabilized frame that has
%                     the maximum amount of image data
%
%
% Program Creator: Girish Kumar
% Date of Completion: 11/06/07


if (nargin < 2) || isempty(shifts) || isempty(framesize)
    disp('You need to provided atleast two input arguments');
    error('Type ''help getstabilizedparams'' for usage');
end

if (nargin < 3) || isempty(maxsizeincrement)
    maxsizeincrement = 3;
end

maxhorimovement = max(abs(shifts(:,1)));
maxvertmovement = max(abs(shifts(:,2)));

if maxhorimovement > maxvertmovement
    sizeincrement = ceil((framesize(1) + (2 * maxhorimovement)) / framesize(1));
else
    sizeincrement = ceil((framesize(2) + (2 * maxvertmovement)) / framesize(2));
end


sizeincrement = min(max(sizeincrement,1.5),maxsizeincrement);

stabilizedsize(1) = round(framesize(1) * sizeincrement);
stabilizedsize(2) = round(framesize(2) * sizeincrement);

leftmovements_indices = find(shifts(:,1) < 0);
if ~isempty(leftmovements_indices)
    leftmovements = abs(shifts(leftmovements_indices,1));
    maxleftmovement = max(leftmovements(:));
else
    maxleftmovement = 0;
end

rightmovements_indices = find(shifts(:,1) > 0);
if ~isempty(rightmovements_indices)
    rightmovements = shifts(rightmovements_indices,1);
    maxrightmovement = max(rightmovements(:));
else
    maxrightmovement = 0;
end

upmovements_indices = find(shifts(:,2) < 0);
if ~isempty(upmovements_indices)
    upmovements = abs(shifts(upmovements_indices,2));
    maxupmovement = max(upmovements(:));
else
    maxupmovement = 0;
end

downmovements_indices = find(shifts(:,2) > 0);
if ~isempty(downmovements_indices)
    downmovements = shifts(downmovements_indices,2);
    maxdownmovement = max(downmovements(:));
else
    maxdownmovement = 0;
end

horizontalcentre = floor(stabilizedsize(1) / 2) + 1;
verticalcentre = floor(stabilizedsize(2) / 2) + 1;

horizontalsize = ceil(framesize(1) + maxrightmovement + maxleftmovement);
verticalsize = ceil(framesize(2) + maxupmovement + maxdownmovement);

leftborder = max(round(horizontalcentre - ((framesize(1) / 2) + maxrightmovement)) - 4,1);
rightborder = min(leftborder + horizontalsize + 7,stabilizedsize(1));

topborder = max(round(verticalcentre - ((framesize(2) / 2) + maxdownmovement)) - 4,1);
bottomborder = min(topborder + verticalsize + 7,stabilizedsize(2));

imageborders = [leftborder;rightborder;topborder;bottomborder];