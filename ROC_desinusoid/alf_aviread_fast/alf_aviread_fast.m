function mov = alf_aviread_fast(filename,varargin)

% ALF_AVIREAD_FAST is almost identical to the native function AVIREAD, 
%           used to read frames from AVI files. The only difference is that
%           the internal call to the native function AVIINFO has to be
%           performed externally, thus eliminating the multiple unnecesary 
%           calls if processing several frames. The syntax is as follows:
%           first one calls
%
%           movie_info_robust = aviinfo(filename,'Robust');
%
%           and then passes the returned structure to alf_aviread_fast,
%
%           one_frame = alf_aviread_fast(filename,frame_number ,movie_info_robust);
%
%           In practise, this would be used in a FOR loop.
%
%           movie_info_robust = aviinfo(filename,'Robust');
%           movie_info        = aviinfo(filename);
%           for k = 1 : movie_info.NumFrames,
%               current_frame = alf_aviread_fast(filename,k,movie_info_robust);
%           end
%
%           See also AVIREAD, AVIINFO, AVIFILE, MOVIE.
%
%           For this function to work, it should be included in the folder 
%           ...\MATLAB71\toolbox\matlab\audiovideo or wherever the native
%           function AVIREAD is located.
%       
%           Alf Dubra, August 20th, 2006
%           adubra@cvs.rochester.edu

% Initialization
index = -10000;

% Validate input/output. 
error(nargoutchk(1,1,nargout));
error(nargchk(3,3,nargin));

if nargin == 3
  if isnumeric(varargin{1})
    index = varargin{1};
  else
    error('INDEX must be numeric.');
  end  
end

if ~ischar(filename)
  error('The filename must be a string.');
end

[path,name,ext] = fileparts(filename);
if isempty(ext)
  filename = strcat(filename,'.avi');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Begining of modification by Alf   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 3
    info = varargin{2};
else
    info = aviinfo(filename,'Robust');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  End of modification by Alf        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (index(1) ~= -10000)
  if ( isfield(info.MainHeader,'HasIndex') == 0 )
    error('%s does not support the ''Index'' parameter.',filename);
  elseif any(index > info.MainHeader.TotalFrames)
    error('Index value exceeds, %d, the total number of movie frames in this AVI movie.',info.MainHeader.TotalFrames);
  elseif any(index <= 0)
    error('Index value must be greater than zero.');
  end
end

if ispc
  if index == -10000
    X = readavi(info.Filename,-1);
  else   
    X = readavi(info.Filename,index-1);
  end 

  % The width of the frames may be padded to be on 4 byte boundaries because
  % this is how bitmaps are typically written.  However, AVI files do not
  % restrict the frames to lie on 4 byte boundries.  Because of
  % inconsistencies with the header information in AVI files, the READAVI
  % MEX-function determines if the frame is padded and reads the correct
  % number of bytes for each frame.  If the returned data is more than
  % expected (different for indexed and RGB) then the data is padded.  The
  % padding is removed before frames are returned by AVIREAD.
  
  width = info.VideoFrameHeader.Width;
  if ((info.VideoFrameHeader.Width*info.VideoFrameHeader.Height ~= length(X(1).cdata)) && (info.VideoFrameHeader.BitDepth == 8)) || ((info.VideoFrameHeader.Width*info.VideoFrameHeader.Height*3 ~= length(X(1).cdata)) && (info.VideoFrameHeader.BitDepth == 24) )
    paddedWidth = 4*ceil(width/4);
  else
    paddedWidth = width;
  end
  height = info.VideoFrameHeader.Height;
  
  if info.VideoFrameHeader.BitDepth == 8 || info.VideoFrameHeader.BitDepth == 16 
    % Indexed frames
    for i=1:length(X)
      if height<0
        % Movie frames are stored top down (height is negative).  
        mov(i).cdata = reshape(X(i).cdata, paddedWidth, abs(height))';
      else
        mov(i).cdata = rot90(reshape(X(i).cdata, paddedWidth, height));
      end
      if paddedWidth ~= width
        mov(i).cdata = mov(i).cdata(:,1:width);
      end
      map = reshape(X(i).colormap, 4, ...
		    info.VideoFrameHeader.NumColormapEntries);
      map = double(flipud(map(1:3,:))')/255;
      mov(i).colormap = map;
    end
  elseif info.VideoFrameHeader.BitDepth == 24
    paddedWidth = 4*ceil(width*3/4);
    % Truecolor frames
    for i=1:length(X)
      f = X(i).cdata;
      if height<0
	f = permute(reshape(f, paddedWidth,height),[2 1 3]);
      else
	f = rot90(reshape(f, paddedWidth,height));
      end
      if paddedWidth ~= width
	f = f(:,1:width*3);
      end
      RGB(1:height, 1:width,3) = f(:,1:3:end);
      RGB(:, :, 2) = f(:,2:3:end);
      RGB(:, :, 1) = f(:,3:3:end);
      mov(i).cdata = RGB;
      mov(i).colormap = [];
    end
  else
    error('The AVI file must be 8-bit Indexed or grayscale images, 16-bit grayscale, or 24-bit TrueColor images');
  end 
end %End of PC specific code

if isunix

  if isempty(strmatch(lower(info.VideoFrameHeader.CompressionType),...
		      {'dib ', 'raw ','none','raw ',char([0 0 0 0])}))
    error('Only uncompressed AVI movies can be read on UNIX.');
  end
  
  if strcmpi(info.VideoFrameHeader.CompressionType,char([0 0 0 0]))
    info.VideoFrameHeader.CompressionType = 'none';
  end
  
  fid = fopen(filename,'r','l');
  if fid == -1
    error('Unable to open %s.', filename);
  end

  % Find RIFF chunk
  [chunk, msg] = findchunk(fid,'RIFF');
  errorWithFileClose(msg,fid);

  % Read AVI chunk
  [rifftype,msg] = readfourcc(fid);
  errorWithFileClose(msg,fid);
  if ( strcmp(rifftype,'AVI ') == 0 )
    error('Not a valid AVI file. Missing ''AVI '' chunk.');
  end

  % Find hdrl LIST chunk
  [hdrlsize, msg] = findlist(fid,'hdrl');
  errorWithFileClose(msg,fid);

  % Find and skip avih chunk
  [chunk,msg] = findchunk(fid,'avih');
  errorWithFileClose(msg,fid);
  msg = skipchunk(fid,chunk);
  errorWithFileClose(msg,fid);

  % Find the video stream
  for  i = 1:info.MainHeader.NumStreams
    % Find strl LIST chunk
    [strlsize,msg] = findlist(fid,'strl');
    errorWithFileClose(msg,fid);
    % Read strh chunk
    [strhchunk, msg] = findchunk(fid,'strh');
    errorWithFileClose(msg,fid);
    % Determine stream type
    streamType = readfourcc(fid);
    % Break if it is a video stream
    if(strcmp(streamType,'vids'))
      found = 1;
      break;
    else
      found  = 0;
      % Seek to end of strl list minus the amount read
      if ( fseek(fid,listsize - 16,0) == -1 ) 
	error('Incorrect chunk size information in AVI file.');
      end                              
    end
  end
  
  if (found == 0)
    error('Unable to locate video stream.');
  end

  % Skip the strh chunk minus the fourcc (4 bytes) already read.
  strhchunk.cksize = strhchunk.cksize - 4;
  msg = skipchunk(fid,strhchunk);
  errorWithFileClose(msg,fid);

  % Read strf chunk
  [strfchunk, msg] = findchunk(fid,'strf');
  errorWithFileClose(msg,fid);

  if info.VideoFrameHeader.BitDepth == 24
    % For TrueColor images, skip the Stream Format chunk
    msg = skipchunk(fid,strfchunk);
    errorWithFileClose(msg,fid);
  elseif  info.VideoFrameHeader.BitDepth == 8 
    % If bitmap has a palette Seek past the BITMAPINFOHEADER to put the
    % file pointer at the begining of the colormap
    if  fseek(fid,info.VideoFrameHeader.BitmapHeaderSize,0) == -1       
      error('Incorrect BITMAPINFOHEADER size information in AVI file.');
    end 
    map = readColormap(fid,info.VideoFrameHeader.NumColorsUsed); 
  else
    error('Bitmap data must be 8-bit Index images or 24-bit TrueColor images');
  end

  % Search for the movi LIST
  [movisize,msg] = findlist(fid,'movi');
  errorWithFileClose(msg,fid);
  % movioffset will be used when using idx1. The offsets stored in idx1 are
  % with respect to just after the 'movi' LIST (not including 'movi')
  movioffset = ftell(fid) -4;

  %Determine method of reading movie
  if ( index ~= -10000 )
    method = 'UseIndex';
  elseif ( isfield(info,'IsInterleaved') == 1 )
    method = 'Interleaved';
  else
    method = 'Normal';
  end

  totalReadFrames = 1;			    
  switch method
   case 'Interleaved'
    % Read movies that are interleaved (contain rec lists)
    while(totalReadFrames < info.MainHeader.TotalFrames )
      [recsize, msg] = findlist(fid,'rec ');
      currentPos = ftell(fid);
      % The recListPos is the current position plus the rec list size minus
      % 4 bytes because we read the four character LIST name in findlist
      recListEndPos = currentPos + recsize - 4;
      chunk = readchunk(fid);
      while(~strcmpi(chunk.ckid,'00db') && ~strcmpi(chunk.ckid,'00dc'))
          msg = skipchunk(fid,chunk);
          errorWithFileClose(msg,fid);
          if (ftell(fid)==recListEndPos)
              [recsize, msg] = findlist(fid,'rec ');
              errorWithFileClose(msg,fid);
              currentPos = ftell(fid);
              recListEndPos = currentPos + recsize - 4; % minus 4 because we read
          end
          chunk = readchunk(fid);
      end
      
      % Prepare input for readbmpdata
      tempinfo = info;
      tempinfo.ImageDataOffset = ftell(fid);
      tempinfo.CompressionType = info.VideoFrameHeader.CompressionType;
      tempinfo.BitDepth = info.VideoFrameHeader.BitDepth;
      % readbmpdata opens and closes the file so aviread must also to 
      % have a valid fid.
      status = fclose(fid);
      
      RGB = readbmpdata(tempinfo);
      
      fid = fopen(filename,'r','l');
      fseek(fid,tempinfo.ImageDataOffset,'bof');
      % readbmpdata does not move the file pointer
      msg = skipchunk(fid,chunk);
      errorWithFileClose(msg,fid);
      % Assign to MATLAB movie structure
      mov(totalReadFrames).cdata = RGB;
      totalReadFrames = totalReadFrames+1;
    end
   case 'Normal'
    % Find each of the 00db or 00dc chunks and read the frames
    for i = 1:info.MainHeader.TotalFrames
      chunk = readchunk(fid);
      while (~strcmpi(chunk.ckid,'00db') && ~strcmpi(chunk.ckid,'00dc') );
        msg = skipchunk(fid,chunk);
        errorWithFileClose(msg,fid);
        chunk = readchunk(fid);
      end
      
      % Prepare data to be sent to readbmpdata
      tempinfo.Filename = info.Filename;
      tempinfo.Width = info.VideoFrameHeader.Width;
      tempinfo.Height = info.VideoFrameHeader.Height;
      tempinfo.ImageDataOffset = ftell(fid);
      tempinfo.CompressionType = 'none';
      tempinfo.BitDepth = info.VideoFrameHeader.BitDepth;
      % readbmpdata opens and closes the file so aviread must also to 
      % have a valid fid
      status = fclose(fid);
      % Read RGB frame
      RGB = readbmpdata(tempinfo);
      
      fid = fopen(filename,'r','l');
      fseek(fid,tempinfo.ImageDataOffset,'bof');
      msg = skipchunk(fid,chunk);
      errorWithFileClose(msg,fid);
      % Assign to MATLAB movie structure
      mov(i).cdata = RGB;
    end
   case 'UseIndex' 
    % Skip the movi LIST (minus 4 because 'movi' was read) and use idx1.  
    if ( fseek(fid,movisize-4,0) == -1 )
      error('Incorrect chunk size information in WAV file.');
    end
    % Find idx1 chunk 
    [idx1chunk, msg] = findchunk(fid,'idx1');
    errorWithFileClose(msg,fid);
    idx1ChunkPos = ftell(fid);

    for j = 1:length(index)
      fseek(fid,idx1ChunkPos,'bof');
      for i = 1:index(j)
        found = 0;
        while(found == 0)
          id = readfourcc(fid);
          if (strcmpi(id,'00db') || strcmpi(id,'00dc'))
            found = 1;
          end
          [idx1data, msg] = readIDX1(fid);
          errorWithFileClose(msg,fid);
        end

        % If the very first index inside the 'idx1' chunk contains a
        % data offset that is larger than the 'movi' list offset, then
        % it is an absolute offset.  Otherwise, we will calculate the
        % offset relative to the beginning of the 'movi' list.
        if (i == 1)
          if (idx1data.offset > movioffset)
            isIdx1OffsetAbsolute = true;
          else
            isIdx1OffsetAbsolute = false;
          end
        end
      end

      % Prepare data to be sent to readbmpdata
      tempinfo.Filename = info.Filename;
      tempinfo.Width = info.VideoFrameHeader.Width;
      tempinfo.Height = info.VideoFrameHeader.Height;
      tempinfo.BitDepth = info.VideoFrameHeader.BitDepth;
      % 8 is the riffheadersize

      % Add the 'movi' offset only if the data offset is not absolute.
      if isIdx1OffsetAbsolute
          tempinfo.ImageDataOffset = idx1data.offset + 8;
      else
          tempinfo.ImageDataOffset = movioffset + idx1data.offset + 8;
      end
      tempinfo.CompressionType = info.VideoFrameHeader.CompressionType;
      % readbmpdata opens and closes the file so aviread must also to 
      % have a valid fid
      currPos = ftell(fid);
      status = fclose(fid);
      
      frame = readbmpdata(tempinfo);
      
      fid = fopen(filename,'r','l');
      fseek(fid,currPos,'bof');
      mov(j).cdata = frame;
    end
  end
  fclose(fid);
  % Formulate outputs
  [mov.colormap] = deal(map);
  varargout{1} = mov;
end
return

function map = readColormap(fid,numColors)
% Read colormap for 8-bit indexed images
map = fread(fid,numColors*4,'*uint8');
map = reshape(map,4,numColors);
map = double(flipud(map(1:3,:))')/255;
return;


function [idx1data,msg] = readIDX1(fid)
% Read the data in the idx1 chunk.
msg = '';
[idx1data.flags, count] = fread(fid,1,'uint32');
if ( count ~= 1 )
  msg = 'Incorrect IDX1 chunk size information in AVI file.';
end
[idx1data.offset, count] = fread(fid,1,'uint32');
if ( count ~= 1 )
  msg = 'Incorrect IDX1 chunk size information in AVI file';
end
[idx1data.length, count] = fread(fid,1,'uint32');
if ( count ~= 1 )
  msg = 'Incorrect IDX1 chunk size information in AVI file';
end
return;

function errorWithFileClose(msg,fid)
%Close open file the error
if ~isempty(msg)
  fclose(fid);
  error('%s', msg);
end
return;

