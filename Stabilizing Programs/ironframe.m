function flatframe = iron(frame, x, y, theta, loci, sizeincrement, verbosity);
% This program is part of the bigger project to analyse AOSLO videos. Its
% function is to iron out a single frame given the shifts, loci of the
% shift measurement locations, and the size of the iron outed frame. This
% program is based onthe iron.m by Dr. Scott B. Stevenson with the added
% functionality of allowing the user to set the size of the ironed frame
%
% Usage: flatframe = iron(frame, x, y, theta, loci, size, verbosity);
% frame is the frame thatrequired ironing
% x are the horizontal shifts
% y are the vertical shifts
% theta are the torsional shifts
% loci are the locations at which the shifts were meansured
% sizeincrement is the multiple of the original frame's size that will
% determine the size of the ironed frame.
% verbosity is the level of communication between the program and the user.
% Id it is equal to 0, there is no communication. If it is equal to 1 then
% the program plots the spline fit to the shifts that will be used to iron
% the frame
%
% flatframe is the ironed frame
%
%
% Program Creator: Girish Kumar
% Date of Completion: 03/22/06


frame = double(frame);
x = x(:)'; % force it to be a row;
y = y(:)'; % force it to be a row;
theta = theta(:)'; % force it to be a row;
loci = loci(:)'; % force it to be a row;

[m, n] = size(frame);
flatframe = zeros(round(sizeincrement * [m n]));

[fm fn] = size(flatframe);
sumframe = flatframe;
loci = round(loci);
XX = 1:m;
vinterp = spline(loci, y, XX);
hinterp = spline(loci, x, XX);
thetainterp = spline(loci, theta, XX);
% keyboard;

if verbosity ~= 0;
    figure(40);plot(XX,[vinterp; hinterp; thetainterp],'-', loci, [y; x; theta], 'o');
    legend('y','x','theta');
end
for rowdx = 1:m
    onerow = frame(rowdx,:);
    if thetainterp(rowdx) ~= 0;
        rotrow = imrotate(onerow, thetainterp(rowdx),'bilinear');
    else 
        rotrow = onerow;
    end
    [rm, rn] = size(rotrow);
    targetrows = round(vinterp(rowdx)) + ceil((fm - m) /2) + rowdx - ceil(rm/2) + [1:rm];
    targetcols = round(hinterp(rowdx)) + ceil((fn - n) /2) + [1:rn];
    targetrows = min(targetrows, fm);
    targetrows = max(targetrows, 1);
    targetcols = min(targetcols, fn);
    targetcols = max(targetcols, 1);
    
    flatframe(targetrows, targetcols) = flatframe(targetrows, targetcols) + rotrow;
    sumframe(targetrows, targetcols) = sumframe(targetrows, targetcols) + (rotrow> 0);
    
end
flatframe(find(sumframe)) = flatframe(find(sumframe)) ./ sumframe(find(sumframe));