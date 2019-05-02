% Appends given movies into single file
[fnames,pname] = uigetfiles('*.avi','Open AVI files');
%keyboard;
pname = pname{1};
mkdir(pname,'Combined');
%keyboard;
nummovies = size(fnames,1);
fname = fnames{1};
destfile = strcat(fname(1:(size(fname,2)-4)),'_combined.avi'); %name of new file
movieObj = VideoReader([pname fname]);
newMovieObj = VideoWriter([pname 'Combined/' destfile]); 
'colormap', movie(1).colormap,'compression', 'None','fps', 30); % Creates new AVI file for processed video
if (exist(movieObj.Colormap))
    newMovieObj.Colormap = movieObj.Colormap;
end
newMovieObj.FrameRate = movieObj.FrameRate;
open(newMovieObj);

for movienum = 1:nummovies % Analyze each video selected
    
    fname = fnames{movienum};
    movieObj = VideoReader([pname fname]);
    endframe = movieObj.FrameRate*movieObj.Duration;

    while hasFrame(movieObj)
	writeVideo(newMovieObj, readFrame(movieObj));
    end
    
end

close(newMovieObj); % Reset AVI handle
 