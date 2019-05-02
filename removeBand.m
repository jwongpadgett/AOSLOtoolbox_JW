function remBandVid = removeBand(videoname)
    oldVideo = VideoReader(videoname);
    remBandVid = VideoWriter([videoname(1:end-4) '_remBand_r.avi' ],'Grayscale AVI');
    open(remBandVid)
    while(hasFrame(oldVideo))
        currentframe = double(readFrame(oldVideo));
        lineMean = mean(currentframe);
        currentframe(:,lineMean>mean(lineMean)+1*std(lineMean))=currentframe(:,lineMean>mean(lineMean)+1*std(lineMean))-...
            lineMean(lineMean>mean(lineMean)+1*std(lineMean))+mean(lineMean);
        currentframe(currentframe<0)=0;
        writeVideo(remBandVid,currentframe/255);
    end
    
    close(remBandVid);
end