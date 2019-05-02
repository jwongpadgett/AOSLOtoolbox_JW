function [resultmatrix varargout] = getsubmatrix(inputmatrix,...
    x_origin,y_origin,x_searchzone,y_searchzone,xlims,ylims,fillmatrixwithrand,warnflag)
% getsubmatrix.m. This program was written to simplify the AOSLO analysis program, since this section of code was being repeated within the
% program. However this program could be used in a more generic way since it gives the user a smaller matrix from within a larger matrix.
% The two searchzone variables control the size of the submatrix returned. If however the user asks for a submatirx that exceeds the boundaries of
% the original matrix the locations that exceed the boundaries will be filled with zeros/random noise based on the input arguments
%
% Usage: [resultmatrix [warnstring]] = getsubmatrix(inputmatrix, x_origin,y_origin,x_searchzone, y_searchzone,[xlims,ylims,fillmatrixwithrand,warnflag])
%
% inputmatrix                   - The matrix from which we want a smaller matrix.
% x_origin                        - The location in the input matrix that is the horizontal centre of the returned matrix.
% y_origin                        - The location in the input matrix that is the vertical centre of the returned matrix.
% x_searchzone                - The width of the returned matrix.
% y_searchzone                - The height of the returned matrix.
% xlims                            - An array of size 1x2 that state the horizontal limits beyond which data cannot ber placed in the
%                                      result matrix. Default is 1 and the width of the input matrix.
% ylims                            - An array of size 1x2 that state the vertical limits beyond which data cannot ber placed in the
%                                      result matrix. Default is 1 and the height of the input matrix.
% fillmatrixwithrand            - The flag that determines if the indices in resultmatrix that extend beyond the inputmatrix
%                                      is filled with zeros or random values taken from the targematrix. If the flag is set to be 1 then
%                                      the indices are filled with random values. Default is 0
% warnflag                       - If this flag is set to 1 then the program prints warning messages to the command window. To
%                                      prevent the printing set the flag to 0.
%
% resultmatrix                  - The smaller matrix taken from the larger input matrix
% warnstring                    - A string that informs the user of the type of non-fatal, non-blue screen of death type error
%                                     that occured
%
%
% Program Author : Girish Kumar
% Make Peacefful Love Not War


% Error check the input & outpur arguments arguments
if (nargin < 5)
    disp('getsubmatrix requires atleast 5 input arguments');
    error('Type ''help getsubmatrix.m'' for usage');
end

if (nargin < 6) || isempty(xlims)
    xlims = [1,size(inputmatrix,2)];
end

if (nargin < 7) || isempty(ylims)
    ylims = [1,size(inputmatrix,1)];
end

if (nargin < 8) || isempty(fillmatrixwithrand)
    fillmatrixwithrand = 0;
end

if (nargin < 9) || isempty(warnflag)
    warnflag = 1;
end

if (nargout < 1) || (nargout > 3)
    disp('getsubmatrix produces 1/2 output arguments');
    error('Type ''help getsubmatrix.m'' for usage');
end

if length(xlims) ~= 2;
    disp('xlims should have only two elements');
    error('Type ''help getsubmatrix.m'' for usage');
end

if length(ylims) ~= 2;
    disp('ylims should have only two elements');
    error('Type ''help getsubmatrix.m'' for usage');
end

isbadsubmatrix = [0 0 0];
warnstring = ('No Errors');

if (x_origin < 1) || (x_origin > size(inputmatrix,2))
    warnstring = ('X Origin has to be within the input matrix');
    isbadsubmatrix(1) = 1;
    if warnflag
        disp('X Origin is outside the input matrix');
    end
end

if (y_origin < 1) || (y_origin > size(inputmatrix,1))
    warnstring = ('Y Origin has to be within the input matrix');
    if isbadsubmatrix(1)
        isbadsubmatrix(1) = 3;
    else
        isbadsubmatrix(1) = 2;
    end
    if warnflag
        disp('Y Origin is outside the input matrix');
    end
end

if x_searchzone > size(inputmatrix,2)
    warnstring = ('Horizontal Search Zone has to be equal to or smaller than input matrix');
    isbadsubmatrix(2) = 1;
    if warnflag
        disp('Horizontal search zone bigger than input matrix');
    end
end

if y_searchzone > size(inputmatrix,1)
    warnstring = ('Vertical Search Zone has to be equal to or smaller than input matrix');
    if isbadsubmatrix(2)
        isbadsubmatrix(2) = 3;
    else
        isbadsubmatrix(2) = 2;
    end
    if warnflag
        disp('Vertical search zone bigger than input matrix');
    end
end


if fillmatrixwithrand
    randindices = floor(rand(y_searchzone * x_searchzone,1) *...
        (size(inputmatrix,2) * size(inputmatrix,1))) + 1;
    resultmatrix = inputmatrix(randindices);
    resultmatrix = reshape(resultmatrix,y_searchzone, x_searchzone);
else
    resultmatrix = zeros(y_searchzone, x_searchzone);
end

x_start = x_origin - floor(x_searchzone / 2);
y_start = y_origin - floor(y_searchzone / 2);

x_end = x_start + x_searchzone - 1;
y_end = y_start + y_searchzone - 1;

% Check if the the start and end indices are within the zones specified by
% the user.
if x_start < xlims(1)
    warnstring = ('Minimum Horizontal index for result matrix is lesser than lower limit');
    result_xstart =  xlims(1) - x_start + 1;
    x_start = xlims(1);
    isbadsubmatrix(3) = 1;
else
    result_xstart = 1;
end
if x_end > xlims(2)
    warnstring = ('Maximum Horizontal index for result matrix is greater than upper limit');
    result_xend = x_searchzone - (x_end - xlims(2));
    x_end = xlims(2);
    isbadsubmatrix(3) = 1;
else
    result_xend = x_searchzone;
end

if y_start < ylims(1)
    warnstring = ('Minimum Vertical index for result matrix is lesser than lower limit');
    result_ystart =  ylims(1) - y_start + 1;
    y_start = ylims(1);
    if isbadsubmatrix(3)
        isbadsubmatrix(3) = 3;
    else
        isbadsubmatrix(3) = 2;
    end
else
    result_ystart = 1;
end

if y_end > ylims(2)
    warnstring = ('Maximum Vertical index for result matrix is greater than upper limit');
    result_yend = y_searchzone - (y_end - ylims(2));
    y_end = ylims(2);
    if isbadsubmatrix(3)
        isbadsubmatrix(3) = 3;
    else
        isbadsubmatrix(3) = 2;
    end
else
    result_yend = y_searchzone;
end

resultmatrix(result_ystart:result_yend,result_xstart:result_xend) = double(inputmatrix(y_start:y_end,x_start:x_end));

if nargout == 2
    varargout{1} = isbadsubmatrix;
end
if nargout == 3
    varargout{2} = warnstring;
end