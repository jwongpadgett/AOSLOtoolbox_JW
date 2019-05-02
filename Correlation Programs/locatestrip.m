% locatestrip.dll
% This is the main engine behind the findthestrip.m program.
% Usage: correlation = locatestrip(frame,strip)
% frame         - The 2D matrix that will be used as the reference.
% strip         - The 2D matrix. Since this is the 'test' matrix it has to
%                 have a smaller number of rows when compared to frame
%
% correlation   - The cross-correlation function.
% 
% The program performs a cross-correlation of frame and strip using the
% principle outline by Dr. Scott B. Stevenson's findstripinframe program.
% The first line in the strip is cross-correlated with every line of the
% frame starting from the first one and ending with the line whose index
% number is that is equal to the number lines in the frame minus the number
% of lines in the strip. The second line is cross-correlated with all the
% lines in the frame from the second to the line whose index number is
% equal to the number of lines in the frame minus the number of lines the
% strip plus one. And so on and so forth till all the lines in the strip
% are correlated.
%
%
% Program Author: Girish Kumar
% Date of Completion: 05/10/06
