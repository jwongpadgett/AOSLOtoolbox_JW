% computes the power spectrum density of images

[fname pname] = uigetfile('*.tiff','Please choose the IR image');
imagefile= strcat(pname,fname);
imageIR = double(imread(imagefile));

[fname pname] = uigetfile('*.tiff','Please choose the Red image');
imagefile= strcat(pname,fname);
imageRed = double(imread(imagefile));

[fname pname] = uigetfile('*.tiff','Please choose the Green image');
imagefile= strcat(pname,fname);
imageGreen = double(imread(imagefile));

tformEstimateRed = imregcorr(imageRed,imageIR);
tformEstimateGreen = imregcorr(imageGreen,imageIR);

Rfixed = imref2d(size(imageIR));
movingRegRed = imwarp(imageRed,tformEstimateRed,'OutputView',Rfixed);
movingRegGreen = imwarp(imageGreen,tformEstimateGreen,'OutputView',Rfixed);

figure;
imshowpair(imageIR,imageRed,'falsecolor');

alpha = ones(size(imageIR));
figure;
colormap gray;
ir = imagesc(imageIR); hold on;
r = imagesc(movingRegRed); set(r, 'AlphaData', 0.5.*alpha);
g = imagesc(movingRegGreen); set(g, 'AlphaData', 0.5.*alpha);
roi = round(getrect); hold off;

%make sure the subimage has odd dimensions
roi(3) = 2*floor(roi(3)/2)+1;
roi(4) = 2*floor(roi(4)/2)+1;

subimageIR = imageIR(roi(2):roi(2)+roi(4)-1,roi(1):roi(1)+roi(3)-1);
subimageRed = movingRegRed(roi(2):roi(2)+roi(4)-1,roi(1):roi(1)+roi(3)-1);
subimageGreen = movingRegGreen(roi(2):roi(2)+roi(4)-1,roi(1):roi(1)+roi(3)-1);

row = size(subimageIR,1);
col = size(subimageIR,2);
M = row*col;

% Fourier transform
fftimageIR = fftshift(fft2(subimageIR));
fftimageRed = fftshift(fft2(subimageRed));
fftimageGreen = fftshift(fft2(subimageGreen));

% Normalized power spectrum
normalizedPSIR = abs(fftimageIR).^2 ./ ( mean(mean(subimageIR)).^2 * M );
normalizedPSRed = abs(fftimageRed).^2 ./ ( mean(mean(subimageRed)).^2 * M );
normalizedPSGreen = abs(fftimageGreen).^2 ./ ( mean(mean(subimageGreen)).^2 * M );

% figure;imagesc(log10((normalizedPSIR)));colormap gray

x = floor(col/2);
y = floor(row/2);
[X, Y] = meshgrid(-x:x,-y:y); % Make Cartesian grid
[theta, rho] = cart2pol(X, Y);    
rho = round(rho);

radialLineIR = zeros(1, y+1);
radialLineRed = zeros(1, y+1);
radialLineGreen = zeros(1, y+1);

for r = 0:y
    radialLineIR(r+1) = sum(sum(normalizedPSIR(rho==r)))./y;
    radialLineRed(r+1) = sum(sum(normalizedPSRed(rho==r)))./y;
    radialLineGreen(r+1) = sum(sum(normalizedPSGreen(rho==r)))./y;
end

% image quality metric
sumPSIR = 1/M*sum(radialLineIR)
sumPSRed = 1/M*sum(radialLineRed)
sumPSGreen = 1/M*sum(radialLineGreen)

figure; plot(log10(radialLineIR),'k');hold on
plot(log10(radialLineRed),'r'); 
plot(log10(radialLineGreen),'g')
hold off


