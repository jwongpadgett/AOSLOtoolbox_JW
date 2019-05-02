function sumcorr = locatestrip(theframe,thestrip)

[fm fn] = size(theframe);
[sm sn] = size(thestrip);
sumcorr = zeros(fm-sm,fn + sn -1);
theframe = double(theframe); theframe = theframe - mean(theframe(:));
thestrip = double(thestrip); thestrip = thestrip - mean(thestrip(:));

for srowdx = 1:sm
	for frowdx = 1:fm-sm
        a = [theframe(frowdx+srowdx-1,:) zeros(1,sn -1)];
        b = [thestrip(srowdx,:) zeros(1,fn -1)];
        onecorr = fftshift(ifft(fft(a) .* conj(fft(b))));
% 		[onecorr, lags] = xcorr(,,'coeff');
		sumcorr(frowdx,:) = sumcorr(frowdx,:) + onecorr;
	end
end
