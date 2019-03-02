function XYHDLM=readmag(filename,cleanup)
% XYHDLM=readmag(filename,cleanup)
%
% Reads MAGNETIC data from a *.dat file saved by MagMap2000, with header
% X  Y  GPS_HEIGHT  READING_1  TIME  DATE  LINE  MARK
%
% INPUT: 
%
% filename          Name of the .dat file to be loaded
% cleanup           1 delete the zero magnetic data
%                   0 do not delete the zero magnetic data [default]
%
% OUTPUT:           
%
% XYHDLM            Matrix with in its columns:
%                     X UTM position [m],
%                     Y UTM position [m],
%                     GPS elevation [m],
%                     magnetic data [nT]
%                     line umber
%                     mark number
%
% EXAMPLE:
%
% data=readmag('Princeton09272011_B.dat');
%
% SEE ALSO:
%
% PLOTDATA2DL
%
% Last modified by plattner-at-alumni.ethz.ch, 09/14/2011
% Last modified by fjsimons-at-alum.mit.edu, 03/01/2019

% Note that this overrides any inputs - change this if you must
defval('cleanup',0);

XYHDLM=[];
fid=fopen(filename,'r');

% Read and discare the header
titleline=fgets(fid);
% Read the rest until you're done
while 1
  try
    line=fgets(fid);
    X=sscanf(line( 1:18),'%f');
    Y=sscanf(line(19:37),'%f');
    H=sscanf(line(42:50),'%f');    
    D=sscanf(line(53:62),'%f');
    L=sscanf(line(84:96),'%i');
    M=sscanf(line(97:end),'%i');
  catch
    % Now you're done
    break
  end
  % Assemble the output
  XYHDLM=[XYHDLM; X Y H D L M];
  % Now you're really done
  if feof(fid)==1
    break
  end
end

% If you had this set to not-zero, you'd be doing this
if cleanup
  good=find(XYHDLM(:,4)~=0);
  XYHDLM=XYHDLM(good,:);
end

