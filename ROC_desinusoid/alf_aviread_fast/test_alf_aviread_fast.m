clc
[filename,path] = uigetfile('*.avi','Select primary sequence AVI file');

tic
movie_info_robust = aviinfo(strcat(path,filename),'Robust');
movie_info        = aviinfo(strcat(path,filename));


% deleting previous profiling sessions
%profile clear

% turning profiling on
%profile on

% testing the algorithms
for k = 2 : movie_info.NumFrames,
    %first_frame = getfield(aviread(strcat(path,filename),k),'cdata');
    first_frame = getfield(alf_aviread_fast(strcat(path,filename),k,movie_info_robust),'cdata');
end


toc

% turning profiling off
%profile off

% viewing results
%profile viewer
