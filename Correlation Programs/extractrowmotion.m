function [newframe varargout] = extractrowmotion(oldframe);

if nargin < 1
    disp('You need to provide a input matrix')
    error('type ''help extractrowmotion'' for usage');
end

frameheight = size(oldframe,1);
framewidth = size(oldframe,2);

refframe_full = oldframe - repmat(mean(oldframe,2),1,framewidth);

framecenter_x = floor(framewidth / 2) + 1;

refindices = [1:frameheight - 1]';
testindices = [2:frameheight]';

refframe = refframe_full(refindices,:);
testframe = refframe_full(testindices,:);

scalefactor = repmat(sqrt((sum((refframe .^ 2),2)) .* (sum(testframe .^ 2,2))),1,framewidth);

correlation = fftshift(ifft(fft(refframe,[],2) .* conj(fft(testframe,[],2)),[],2),2) ./ scalefactor;

rowmotion_seq = zeros(frameheight,1);
rowaddition = [-3:3];


for rowindex = 1:frameheight - 1
    temprow = correlation(rowindex,:);
    maxcorrelinrow = max(temprow);
    maxloc = find(temprow == maxcorrelinrow);
    rowtofit = (rowaddition .* (temprow(maxloc + rowaddition))) / (temprow(maxloc + rowaddition));
    rowmotion_seq(rowindex + 1) = (framecenter_x - maxloc) + rowtofit;
end

rowmotion = cumsum(rowmotion_seq);

sizeincrement = ceil((framewidth + (2 * max(abs(rowmotion)))) / framewidth);
leftmovements_indices = find(rowmotion < 0);
if ~isempty(leftmovements_indices)
    leftmovements = abs(rowmotion(leftmovements_indices));
    maxleftmovement = max(leftmovements(:));
else
    maxleftmovement = 0;
end
rightmovements_indices = find(rowmotion > 0);
if ~isempty(rightmovements_indices)
    rightmovements = rowmotion(rightmovements_indices);
    maxrightmovement = max(rightmovements(:));
else
    maxrightmovement = 0;
end

newframewidth = framewidth * sizeincrement;
newframe_full = zeros(frameheight,newframewidth);

newcolumnindex = min(max(round(repmat([0:framewidth - 1] +...
    ceil((newframewidth - framewidth) / 2),frameheight,1) -...
    repmat(rowmotion,1,framewidth)),1),newframewidth);
oldcolumnindex = repmat([1:framewidth],frameheight,1);
rowindex = repmat([1:frameheight]',1,framewidth);

oldindices = sub2ind(size(oldframe),rowindex,oldcolumnindex);
newindices = sub2ind(size(newframe_full),rowindex,newcolumnindex);

leftborder = max((floor(((newframewidth - framewidth) / 2) - maxrightmovement) + 5),1);
rightborder = min((ceil(((newframewidth + framewidth) / 2) + maxleftmovement) - 5),newframewidth);

newframe_full(newindices) = oldframe(oldindices);

pixelswithimagedata = find(newframe_full > 0);
pixelswithnoimagedata = find(newframe_full == 0);

randpixelindices = ceil(rand(length(pixelswithnoimagedata),1) * (length(pixelswithimagedata) - 1)) + 1;
newframe_full(pixelswithnoimagedata) = newframe_full(pixelswithimagedata(randpixelindices));
newframe = newframe_full(:,leftborder:rightborder);

if nargout > 1
    varargout{1} = rowmotion;
end