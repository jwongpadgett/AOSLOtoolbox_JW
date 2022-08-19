function spVid = createSplitVid(ch2Vid, ch3Vid)
    %Create split video
    v2 = VideoReader(ch2Vid);
    v3 = VideoReader(ch3Vid);
    spVid = VideoWrite([ch2Vid(1:end-4) '_splitVideo.avi'],'Grayscale AVI');
    open(spVid);
    while(hasFrame(v2))
        currFrame2 = double(readFrame(v2));
        currFrame3 = double(readFrame(v3));
        spFrame = ( (currFrame2-currFrame3)./(currFrame2+currFrame3)+1 ./ 2;
        writeVideo(spVid,spFrame/255);
    end
    close(spVid);
end