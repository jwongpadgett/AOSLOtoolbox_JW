function [correlation varargout] = findthestrip(frame,strip,subpixelflag,windowflag)
% findthestrip.m
% This function performs a 2D correlation function (scaled to provide a
% maximum value of one at zero lag with a autocorrelation) and returns the
% shift between refmatrix and correlstrip in pixels
% usage: [correlation,[xshift,yshift,maxval,noise,secondpeak]] =
%               findthestrip(frame,strip,[windowflag]);
% frame         - The 2D matrix that will be used as the reference.
% strip         - The 2D matrix that will be test for a shift. It need to
%                 have a lesser number of rows than the frame
%
% correlation   - The 2D cross-correlation function.
% shifts        - Shift.(If correlmatrix has moved to the
%                 left when compared to refmatrix xshift is negative.
%                 If correlmatrix has moved to up when compared to
%                 refmatrix yshift is negative)
% peaks_noise   - The values of the first peak, second peak and noise
%                 respectively
%
%
% Program Author: Girish Kumar
% Date of Completion: 10/17/07


if (nargin < 2) || (nargin > 4)
    disp('findthestrip.m requires 2/3 input arguments');
    error('Type ''help findthestrip'' for usage');
end

if (nargout < 1) || (nargout > 3)
    disp('findthestrip.m requires 1 to 3 output arguments');
    error('Type ''help findthestrip'' for usage');
end

if (nargin < 3) || isempty(subpixelflag)
    subpixelflag = 1;
end

if (nargin < 4) || isempty(windowflag)
    windowflag = 0;
end

if (length(size(frame)) > 2) || (length(size(strip)) > 2)
    disp('corr2d.m works only with 2-D matricies')
    warning('Using only the first layer of the input matrices')
    if length(size(frame)) > 2
        frame = frame(:,:,1);
    end
    if length(size(strip)) > 2
        strip = strip(:,:,1);
    end
end

frame = double(frame);
strip = double(strip);

framewidth = size(frame,2);
frameheight = size(frame,1);
framexcenter = floor(framewidth / 2) + 1;
frameycenter = floor(frameheight / 2) + 1;

stripwidth = size(strip,2);
stripheight = size(strip,1);
stripxcenter = floor(stripwidth / 2) + 1;
stripycenter = floor(stripheight / 2) + 1;

if frameheight <= stripheight
    disp('The frame should have greater number of rows than the strip');
    error('Type ''help findthestrip'' for usage');
end

if (rem(stripheight,2) ~= 0) && (rem(frameheight,2) == 0)
    heightcorrection = 1;
else
    heightcorrection = 0;
end
    
for counter = 1:frameheight
    singleline = frame(counter,:);
    zerolocs = find(singleline == 0);
    nonzerolocs = find(singleline > 0);
    if length(zerolocs) ~= framewidth
        singleline(nonzerolocs) = singleline(nonzerolocs) - mean(singleline(nonzerolocs));
        frame(counter,:) = singleline;
    end
end

for counter = 1:stripheight
    singleline = strip(counter,:);
    zerolocs = find(singleline == 0);
    nonzerolocs = find(singleline > 0);
    if length(zerolocs) ~= stripwidth
        singleline(nonzerolocs) = singleline(nonzerolocs) - mean(singleline(nonzerolocs));
        strip(counter,:) = singleline;
    end
end

if framewidth ~= stripwidth
    switch (framewidth < stripwidth)
        case 1
            tempframe = zeros(size(frame,1),size(strip,2));
            x_start = (floor(size(strip,2) / 2) + 1) - floor(size(frame,2) / 2);
            x_end = x_start + size(frame,2) - 1;
            tempframe(:,x_start:x_end) = frame;
            frame = tempframe;
            framewidth = size(frame,2);
        case 0
            tempstrip = zeros(size(strip,1),size(frame,2));
            x_start = (floor(size(frame,2) / 2) + 1) - floor(size(strip,2) / 2);
            x_end = x_start + size(strip,2) - 1;
            tempstrip(:,x_start:x_end) = strip;
            strip = tempstrip;
            stripwidth = size(strip,2);
    end
end

correlwidth = 2 .^ nextpow2(framewidth);
if correlwidth == framewidth
    correlwidth = 2 .^ nextpow2(framewidth + 1);
end
correlheight = frameheight - stripheight;

padding_horisize = correlwidth - framewidth;
indicestoputmatrices = [0:framewidth - 1] + floor((correlwidth - framewidth) / 2);

tempframe = zeros(frameheight,correlwidth);
tempframe(:,indicestoputmatrices) = frame;
frame = tempframe;

tempstrip = zeros(stripheight,correlwidth);
tempstrip(:,indicestoputmatrices) = strip;
strip = tempstrip;

clear tempstrip tempframe;

if windowflag
    coswindow = repmat(scale(cos(2 * pi * [0:correlwidth - 1] / correlwidth) * -1.0),...
        stripheight,1); %#ok<BDSCI>
    strip = strip .* coswindow;
end

correlxcenter = floor(correlwidth / 2) + 1;
correlycenter = floor(correlheight / 2) + 1;

if ismac
	correlation = locatestripMac(frame,strip);
else
	correlation = locatestrip(frame,strip);
end

if nargout >= 2
    correlation_width = size(correlation,2);
    correlation_height = size(correlation,1);
    
    max_correl = max(correlation(:));
    [ymaxloc xmaxloc] = find(correlation == max_correl);
    if length(xmaxloc) > 1
        xmaxloc = round(mean(xmaxloc));
    end
    if length(ymaxloc) > 1
        ymaxloc = round(mean(ymaxloc));
    end
    
    if subpixelflag
        numsplineindices_x = min(5,correlation_width);
        numsplineindices_y = min(5,correlation_height);
        
        splineresolution = 0.1;
                
        splineindexaddition_x = [0:numsplineindices_x - 1] - floor(numsplineindices_x / 2);
        splineindexaddition_y = [0:numsplineindices_y - 1] - floor(numsplineindices_y / 2);

        xspline_xaxis = unique(min(max(xmaxloc + splineindexaddition_x,1),correlation_width));
        xspline_yaxis = correlation(ymaxloc,xspline_xaxis);
        xspline_interpaxis = [xspline_xaxis(1):splineresolution:xspline_xaxis(end)];

        xspline = interp1(xspline_xaxis,xspline_yaxis,xspline_interpaxis,'spline');

        yspline_xaxis = unique(min(max(ymaxloc + splineindexaddition_y,1),correlation_height));
        yspline_yaxis = correlation(yspline_xaxis,xmaxloc)';
        yspline_interpaxis = [yspline_xaxis(1):splineresolution:yspline_xaxis(end)];

        yspline = interp1(yspline_xaxis,yspline_yaxis,yspline_interpaxis,'spline');
        
        xmaxloc = mean(xspline_interpaxis(find(xspline == max(xspline)))); %#ok<FNDSB>
        ymaxloc = mean(yspline_interpaxis(find(yspline == max(yspline)))); %#ok<FNDSB>
    end
    
    varargout{1} = [correlxcenter - xmaxloc,correlycenter - ymaxloc];
    
    if nargout >= 3
        varargout{2} = max_correl;
        tempmat = correlation;
        
        tempmat_thresholded = tempmat <= (max_correl / 5);
        % Get the horizontal width of peak
        width_left = max(find(tempmat_thresholded(round(ymaxloc),1:round(xmaxloc) - 1) == 1)); %#ok<MXFND>
        if isempty(width_left)
            width_left = 1;
        end
        width_right = min(find(tempmat_thresholded(round(ymaxloc),round(xmaxloc) + 1:end) == 1,1)) + round(xmaxloc);
        if isempty(width_right)
            width_right = correlation_width;
        end
        
        % Get the Vertical FullWidth at half height
        width_top = max(find(tempmat_thresholded(1:round(ymaxloc) - 1,round(xmaxloc)) == 1)); %#ok<MXFND>
        if isempty(width_top)
            width_top = 1;
        end
        width_bottom = min(find(tempmat_thresholded(round(ymaxloc) + 1:end,round(xmaxloc)) == 1)) + round(ymaxloc); %#ok<MXFND>
        if isempty(width_bottom)
            width_bottom = correlation_height;
        end
        
        if  (width_right - width_left + 1) < 40
            peakxindices = [-20:20] + round(xmaxloc);
            peakxindices = max(1,peakxindices);
            peakxindices = min(correlation_width,peakxindices);
        else
            peakxindices = [width_left:width_right];
        end

        if (width_bottom - width_top + 1) < 40
            peakyindices = [-20:20]' + round(ymaxloc);
            peakyindices = max(1,peakyindices);
            peakyindices = min(correlation_height,peakyindices);
        else
            peakyindices = [width_top:width_bottom]';
        end
        
        peakxindices = repmat(peakxindices,size(peakyindices,1),1);
        peakyindices = repmat(peakyindices,1,size(peakxindices,2));
        
        peakindices = sub2ind([correlation_height,correlation_width],peakyindices(:),peakxindices(:));
        nonpeakindices = setdiff([1:correlation_height * correlation_width]',peakindices);
        
        if isempty(nonpeakindices)
            noise = 0;
            secondpeak = 0;
        else
            noise = std(correlation(nonpeakindices));
            secondpeak = max(correlation(nonpeakindices));
        end
        
        varargout{2} = [max_correl;secondpeak;noise];
    end
end


% -------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix ./ max(newmatrix(:));

%--------------------------------------------------------------------------