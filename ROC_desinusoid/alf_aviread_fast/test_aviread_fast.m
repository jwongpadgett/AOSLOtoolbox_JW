clc

[filename,path]   = uigetfile('*.avi','Select primary sequence AVI file');

if filename ~=0
    
    movie_info        = aviinfo(strcat(path,filename));

    tic
    movie_info_robust = aviinfo(strcat(path,filename),'Robust');
    % testing the algorithms
    for k = 1 : movie_info.NumFrames,
        first_frame = alf_aviread_fast(strcat(path,filename),k,movie_info_robust);
    end
    toc

    tic
    % testing the algorithms
    for k = 1 : movie_info.NumFrames,
        first_frame = getfield(aviread(strcat(path,filename),k),'cdata');
    end
    toc
end