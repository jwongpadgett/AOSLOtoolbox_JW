function [correlation varargout] = corr2d(refmatrix,testmatrix,subpixelflag,windowflag)
% corr2d.m. This function performs a 2D correlation function (scaled to provide a maximum value of one at
% zero lag with a autocorrelation) and returns the shift between refmatrix and testmatrix in pixels
%
% Usage: [correlation,[shifts,peaksandnoise]] = corr2d(refmatrix,[testmatrix,subpixelflag,windowflag]);
% refmatrix          - A 2D matrix which is used as the refernce or the "ground zero"/"assumed truth".
% testmatrix        - A 2D matrix. If this matrix is not provided then the program uses the reference matrix as the test matrix.
% subpixelflag      - Flag to force the program to calculate shifts with subpixel resolution. Default is 1.
% windowflag       - Flag to force the program to conduct the cross-correlation after placing a raised cosine window on the
%                         test matrix. Default is zero.
%
% correlation         - The 2D cross-correlation function.
% shifts                - The shift between the reference and test matrices. The array has two elements, the first is the horizontal
%                           shift while the second is the vertical shift. If the test matrix has moved to the left when compared to refmatrix
%                           shifts(1) is negative. If the testmatrix has moved up when compared to refmatrix shift(2) is negative.
% peaksandnoise     - A three element array. The first element is the maximum value of the correlation function. The second element
%                            is the next highest value once the peak and the surrounding values have been eleminated. The third element is
%                            the std. deviation/noise of the cross-correlation function.
%
%
% Program Author: Girish Kumar
% Make Peaceful Love Not War


if (nargin < 1) || (nargin > 4)
    disp('corr2d_check.m requires 1-4 input arguments');
    error('Type ''help corr2d'' for usage');
end

if (nargin < 3) || isempty(subpixelflag)
    subpixelflag = 1;
end

if (nargin < 4) || isempty(windowflag)
    windowflag = 0;
end

if (nargin < 2) || isempty(testmatrix)
    testmatrix = refmatrix;
end

if (nargin < 1) || isempty(refmatrix)
    disp('corr2d_check.m requires 1-4 input arguments');
    error('Type ''help corr2d_check'' for usage');
end

if (nargout < 1) || (nargout > 3)
    disp('corr2d.m requires 1-3 output arguments');
    error('Type ''help corr2d'' for usage');
end

if (length(size(refmatrix)) > 2) || (length(size(testmatrix)) > 2)
    disp('corr2d.m works only with 2-D matricies')
    warning('Using only the first layer of the input matrices')
    if (length(size(refmatrix)) > 2)
        refmatrix = refmatrix(:,:,1);
    end
    if (length(size(testmatrix)) > 2)
        testmatrix = testmatrix(:,:,1);
    end
end

refmatrix = double(refmatrix);
testmatrix = double(testmatrix);

refmatrix = refmatrix - mean(refmatrix(:));
testmatrix = testmatrix - mean(testmatrix(:));

refwidth = size(refmatrix,2);
refheight = size(refmatrix,1);

testwidth = size(testmatrix,2);
testheight = size(testmatrix,1);

scalefactor = sqrt((sum(refmatrix(:) .^ 2)) * (sum(testmatrix(:) .^ 2)));

if scalefactor == 0
    scalefactor = 1;
end

if refwidth ~= testwidth
    switch (refwidth < testwidth)
        case 1
            tempref = zeros(refheight,testwidth);
            x_start = (floor(testwidth / 2) + 1) - floor(refwidth / 2);
            x_end = x_start + refwidth - 1;
            tempref(:,x_start:x_end) = refmatrix;
            refmatrix = tempref;
            refwidth = size(refmatrix,2);
        case 0
            temptest = zeros(testheight,refwidth);
            x_start = (floor(refwidth / 2) + 1) - floor(testwidth / 2);
            x_end = x_start + testwidth - 1;
            temptest(:,x_start:x_end) = testmatrix;
            testmatrix = temptest;
            testwidth = size(testmatrix,2);
    end
end

if refheight ~= testheight
    switch (refheight < testheight)
        case 1
            tempref = zeros(testheight,refwidth);
            y_start = (floor(testheight / 2) + 1) - floor(refheight / 2);
            y_end = y_start + refheight - 1;
            tempref(y_start:y_end,:) = refmatrix;
            refmatrix = tempref;
            refheight = size(refmatrix,1);
        case 0
            temptest = zeros(refheight,testwidth);
            y_start = (floor(refheight / 2) + 1) - floor(testheight / 2);
            y_end = y_start + testheight - 1;
            temptest(y_start:y_end,:) = testmatrix;
            testmatrix = temptest;
            testheight = size(testmatrix,1);
    end
end

if windowflag
    if rem(refheight,2)
        vertpad = 0;
    else
        vertpad = 1;
    end


    xaxis = repmat(([0:(refwidth - 1)] - floor(refwidth / 2)) / (refwidth / 2),refheight,1);
    yaxis = repmat((flipud([0:(refheight - 1)]') - floor(refheight / 2) + vertpad) / (refheight / 2),1,refwidth);

    radiusaxis = min(sqrt((xaxis .^ 2) + (yaxis .^ 2)),1);


    windowimage = cos(2 * pi * 0.5 * radiusaxis);
    windowimage = (windowimage + 1) / 2;
    
    refmatrix = refmatrix;
%     refmatrix = refmatrix .* windowimage;
    testmatrix = testmatrix .* windowimage;

    refwidth = size(refmatrix,2);
    refheight = size(refmatrix,1);
end

% correlwidth = 2 .^ nextpow2(refwidth);
correlwidth = refwidth;
correlxcenter = floor(correlwidth / 2) + 1;

% correlheight = 2 .^ nextpow2(refheight);
correlheight = refheight;
correlycenter = floor(correlheight / 2) + 1;

correlation = fftshift(ifft2(fft2(refmatrix,correlheight,correlwidth) .*...
    conj(fft2(testmatrix,correlheight,correlwidth)))) ./ scalefactor;


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
        xspline_yaxis = correlation(round(mean(ymaxloc)),xspline_xaxis);
        xspline_interpaxis = [xspline_xaxis(1):splineresolution:xspline_xaxis(end)];

        xspline = interp1(xspline_xaxis,xspline_yaxis,xspline_interpaxis,'spline');

        yspline_xaxis = unique(min(max(ymaxloc + splineindexaddition_y,1),correlation_height));
        yspline_yaxis = correlation(yspline_xaxis,round(mean(xmaxloc)))';
        yspline_interpaxis = [yspline_xaxis(1):splineresolution:yspline_xaxis(end)];

        yspline = interp1(yspline_xaxis,yspline_yaxis,yspline_interpaxis,'spline');

        xmaxloc = mean(xspline_interpaxis(find(xspline == max(xspline)))); %#ok<FNDSB>
        ymaxloc = mean(yspline_interpaxis(find(yspline == max(yspline)))); %#ok<FNDSB>
    end

    varargout{1} = [correlxcenter - xmaxloc,correlycenter - ymaxloc];

    if nargout >= 3

        tempmat = correlation;

        % Remove the main peak's data while calculating noise,and second
        % peak. Threshold the correlation matrix and get incidices where
        % the matrix values have dropped to 1/5th of the peak correlation
        tempmat_thresholded = tempmat <= (max_correl / 5);
        width_left = max(find(tempmat_thresholded(round(ymaxloc),1:round(xmaxloc) - 1) == 1)); %#ok<MXFND>
        if isempty(width_left)
            width_left = 1;
        end
        width_right = min(find(tempmat_thresholded(round(ymaxloc),round(xmaxloc) + 1:end) == 1)) + round(xmaxloc); %#ok<MXFND>
        if isempty(width_right)
            width_right = correlation_width;
        end
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

        peakyindices = repmat(peakyindices,1,size(peakxindices,2));
        peakxindices = repmat(peakxindices,size(peakyindices,1),1);

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

%     if nargout >= 4
%
%
%
%
%
%
%         % Get the horizontal width of peak
%
%
%
%
%         tempmat(round(peakyindices),round(peakxindices)) = 0;
%         noisemat = tempmat(find(abs(tempmat) > 0.00001));
%         if length(noisemat) == 0
%             varargout{3} = 0;
%             noise = 0;
%         else
%             noise = std(noisemat(:));
%             varargout{3} = noise;
%         end
%
%         if nargout >= 5
%             if length(noisemat) == 0
%                 varargout{4} = 0;
%                 secondpeak = 0;
%             else
%                 secondpeak = max(noisemat(:));
%                 varargout{4} = secondpeak;
%             end
%             %             if nargout >= 7
%             %                 [ymaxloc xmaxloc] = find(tempmat == secondpeak);
%             %                 if length(ymaxloc) > 1
%             %                     ymaxloc = mean(ymaxloc(:));
%             %                 end
%             %                 if length(xmaxloc) > 1
%             %                     xmaxloc = mean(xmaxloc(:));
%             %                 end
%             %                 xloc = correlxcenter - xmaxloc;
%             %                 yloc = correlycenter - ymaxloc;
%             %
%             %                 varargout{6} = [xloc yloc];
%             %             end
%             %             if nargout >= 8
%             %                 firstpeak.fullwidthathalfheight_h = fullwidthathalfheight_hori;
%             %                 firstpeak.fullwidthathalfheight_v = fullwidthathalfheight_vert;
%             %                 firstpeak.widthproportion_h = fullwidthathalfheight_hori / correlation_width;
%             %                 firstpeak.widthproportion_v = fullwidthathalfheight_vert / correlation_height;
%             % %                 firstpeak.zscore = log(abs((max_correl + 1) / (max_correl - 1))) / 2;
%             %
%             %                 tempmat_thresholded = tempmat <= (secondpeak / 2);
%             %
%             %                 % Get the Horizontal FullWidth at half height
%             %                 halfwidth_left = max(find(tempmat_thresholded(round(ymaxloc),1:round(xmaxloc) - 1) == 1));
%             %                 if isempty(halfwidth_left)
%             %                     halfwidth_left = 1;
%             %                 end
%             %                 halfwidth_right = min(find(tempmat_thresholded(round(ymaxloc),round(xmaxloc) + 1:end) == 1)) + round(xmaxloc);
%             %                 if isempty(halfwidth_right)
%             %                     halfwidth_right = correlation_width;
%             %                 end
%             %
%             %                 fullwidthathalfheight_hori = halfwidth_right - halfwidth_left + 1;
%             %
%             %                 % Get the Vertical FullWidth at half height
%             %                 halfwidth_top = max(find(tempmat_thresholded(1:round(ymaxloc) - 1,round(xmaxloc)) == 1));
%             %                 if isempty(halfwidth_top)
%             %                     halfwidth_top = 1;
%             %                 end
%             %                 halfwidth_bottom = min(find(tempmat_thresholded(round(ymaxloc) + 1:end,round(xmaxloc)) == 1)) + round(ymaxloc);
%             %                 if isempty(halfwidth_bottom)
%             %                     halfwidth_bottom = correlation_height;
%             %                 end
%             %
%             %                 fullwidthathalfheight_vert = halfwidth_bottom - halfwidth_top + 1;
%             %
%             %                 secondpeak.fullwidthathalfheight_h = fullwidthathalfheight_hori;
%             %                 secondpeak.fullwidthathalfheight_v = fullwidthathalfheight_vert;
%             %                 secondpeak.widthproportion_h = fullwidthathalfheight_hori / correlation_width;
%             %                 secondpeak.widthproportion_v = fullwidthathalfheight_vert / correlation_height;
%             % %                 secondpeak.zscore = log(abs((secondpeak + 1) / (secondpeak - 1))) / 2;
%             %
%             %                 varargout{7} = [firstpeak;secondpeak];
%         end
%     end
% end

% -------------------------------------------------------------------------
function newmatrix = scale(oldmatrix)

newmatrix = oldmatrix - min(oldmatrix(:));
newmatrix = newmatrix ./ max(newmatrix(:));

%--------------------------------------------------------------------------




%         % First analyse the correlation for the full width @ half height
%         % data we might use this later on. No use currently.
%         tempmat_thresholded = tempmat <= (max_correl / 2);
%
%         % Get the Horizontal FullWidth at half height
%         halfwidth_left = max(find(tempmat_thresholded(round(ymaxloc),1:round(xmaxloc) - 1) == 1));
%         if isempty(halfwidth_left)
%             halfwidth_left = 1;
%         end
%         halfwidth_right = min(find(tempmat_thresholded(round(ymaxloc),round(xmaxloc) + 1:end) == 1)) + round(xmaxloc);
%         if isempty(halfwidth_right)
%             halfwidth_right = correlation_width;
%         end
%
%         fullwidthathalfheight_hori = halfwidth_right - halfwidth_left + 1;
%
%         % Get the Vertical FullWidth at half height
%         halfwidth_top = max(find(tempmat_thresholded(1:round(ymaxloc) - 1,round(xmaxloc)) == 1));
%         if isempty(halfwidth_top)
%             halfwidth_top = 1;
%         end
%         halfwidth_bottom = min(find(tempmat_thresholded(round(ymaxloc) + 1:end,round(xmaxloc)) == 1)) + round(ymaxloc);
%         if isempty(halfwidth_bottom)
%             halfwidth_bottom = correlation_height;
%         end
%
%         fullwidthathalfheight_vert = halfwidth_bottom -
%         halfwidth_top + 1;