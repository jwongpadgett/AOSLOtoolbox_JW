function [img] = readMONA(fileName)

    % Define parameters (you must know these beforehand)
   if contains(fileName,'montage')
       [xpart,ypart] = strtok(fileName,'x');
       width = str2num(xpart(25:size(xpart,2)));
       ypart = strtok(ypart,'_');
       height = str2num(ypart(2:size(ypart,2)));
   else
        width = 1024; 
        height = 1024;

   end
    pixelCount = width * height;
    % Open the file in read-only binary mode
    fileID = fopen(fileName, 'r');

    % Read the data (adjust 'uint8', 'uint16', or 'float' to match your file)
    A = fread(fileID, pixelCount, 'uint16=>uint16');

    % Close the file descriptor
    fclose(fileID);

    % Reshape the 1D array back into a 2D image matrix
    img = reshape(A, [width, height])';
    %imshow(img);
end