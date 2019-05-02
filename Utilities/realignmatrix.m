function newmatrix = realignmatrix(oldmatrix)

matrixwidth = size(oldmatrix,2);
matrixheight = size(oldmatrix,1);

matrixcentre_x = floor(matrixwidth / 2) + 1;
matrixcentre_y = floor(matrixheight / 2) + 1;

correlation = zeros(matrixheight,matrixwidth);
movements_raw = zeros(matrixheight,1);
movements = zeros(matrixheight,1);

for linecounter = 1:matrixheight
    temptestlineindex = linecounter;
    temptestline = oldmatrix(temptestlineindex,:);
    temptestline = temptestline - mean(temptestline(:));
    if length(find(temptestline == 0)) == length(temptestline)
        continue
    end
    
    switch sign(linecounter - matrixcentre_y)
        case -1
            tempreflineindex = linecounter + 1;
        case 0
            tempreflineindex = linecounter;
        case 1
            tempreflineindex = linecounter - 1;
    end
    
    temprefline = oldmatrix(tempreflineindex,:);
    temprefline = temprefline - mean(temprefline(:));
    if length(find(temprefline == 0)) == length(temprefline)
        continue
    end
    
    correlation(linecounter,:) = fftshift(ifft(fft(temprefline) .* conj(fft(temptestline))));
    templine = correlation(linecounter,:);
    movements_raw(linecounter) = matrixcentre_x - find(templine == max(templine(:)));
end

for linecounter = (matrixcentre_y - 1):-1:1
    movements(linecounter) = movements(linecounter + 1) - movements_raw(linecounter);
end
for linecounter = (matrixcentre_y + 1):matrixheight
    movements(linecounter) = movements(linecounter - 1) - movements_raw(linecounter);
end

horisize = abs(min(movements)) + matrixwidth + max(movements);
numelementsinnewmatrix = matrixheight .* horisize;
numelementsinoldmatrix = matrixheight .* matrixwidth;

randpixelindices = floor(rand(numelementsinnewmatrix,1) * (numelementsinoldmatrix - 1)) + 1;
newmatrix = oldmatrix(randpixelindices);
newmatrix = reshape(newmatrix,matrixheight,horisize);
indexaddition = [1:matrixwidth];

for linecounter = 1:matrixheight
    indicestoput = min(indexaddition + movements(linecounter),horisize);
    indicestoput = max(indicestoput,1);
    newmatrix(linecounter,indicestoput) = oldmatrix(linecounter,:);
end


