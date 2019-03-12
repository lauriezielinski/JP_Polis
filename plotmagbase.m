function varargout=plotmagbase(filedir,filename,indices,timein,meth,fs)
% [data,p]=plotmagbase(filedir,filename,indices,timein,meth,fs)
%
% Plots single-channel data from a MagMap2000 stn-file over a time index range
%
% INPUT:
%
% filedir       Name string of the data directory
% filename      Name string of the data file (stn extension automatically appended)
% indices       Indices (chronologically) between which you display the data [default: all]
%               ... indices define the intervals counting FROM the beginning and FROM the end 
% timein        The index (after trimming) of the hour called the zeroth hour [default: 1]
% meth          The method, 'fast' [default] or 'slow'
% fs            The font size of the figure [default: 12]
%
% OUTPUT:
%
% data          The data that were thusly extracted
% p             The handle to the line plot
%
% EXAMPLE:
% 
% plotmagbase([],'Rathouse-06122011',[748])
% plotmagbase([],'DigHouse-10292013-1')
% plotmagbase([],'Peristeres-10282013-1',[13])
% plotmagbase([],'Peristeres-10282013-2',[62])
% plotmagbase([],'Peristeres-10302013-C',[37 20])
% plotmagbase([],'PetraradesEG1-E',[96 12])
% plotmagbase([],'PetraradesEG1-F',5,114)
% plotmagbase([],'PetraradesEF2-11012013-4',13)
% plotmagbase([],'PetraradesEG1-11012013-3',[107 4])
%
% SEE ALSO:
%
% PLOTVARIATION, which was retired
%
% Last modified by fjsimons-at-alum.mit.edu, 03/05/2019

clf

% Define directories and font size
defval('filedir','/u/fjsimons/CLASSES/FRS-Cyprus/Magnetometry/Polis/Basestation')
defval('filename','DigHouse10291013_1')

% Setting the figure fontsize
defval('fs',12);

% Load the named file, manually get rid of the header line first
fid=fopen(fullfile(filedir,sprintf('%s.stn',filename)));

% Get the file size
fseek(fid,0,1); filesize=ftell(fid); fseek(fid,0,-1); 

defval('meth','fast')

switch meth
 case 'fast'
  tic
  % Read everything as one big string
  fulldat=reshape(fscanf(fid,'%s'),35,[])';
  % The magnetometer data
  M=str2num(fulldat(:,[2:10]));
  % Time string
  ts=fulldat(:,[16:26]);
  % Date string
  ds=fulldat(:,[27:34]);
  % Numerical date conversion, see DATESTR
  dt=datevec([ds ts],'mm/dd/yyHH:MM:SS.FFF');
  % Convert to all numerical values
  fulldat=[M dt];
  toc
 case 'slow'
  tic
  % Read everything line by line but initialize
  fulldat=nan(filesize/51,7);
  indo=0;
  while 1
    try
      line=fgets(fid);
      % One of several junk lines
      jk=sscanf(line(1:3),'%i');

      % Mag reading
      M=sscanf(line(5:13),'%f');
      jk=sscanf(line(15:23),'%f');    

      % Time string
      ts=sscanf(line(25:35),'%s');

      % Date string
      ds=sscanf(line(38:45),'%s');

      % Numerical date conversion, see DATESTR
      dt=datevec([ds ts],'mm/dd/yyHH:MM:SS.FFF');
      jk=sscanf(line(47:49),'%i');

      % Update the index
      indo=indo+1;
    catch
      % Now you're done
      break
    end
    % Assemble the output as numerical values
    fulldat(indo,:)=[M dt];
    % Now you're really done
    if feof(fid)==1
      break
    end
  end
  toc
end

% Close the file
fclose(fid);

% Arrange chronologically (the indices later refer to this order!)
fulldat=flipud(fulldat);

% By default you take it all
defval('indices',[1 0])
% If you give two indices, uses the values in-between; if only one, to the end
if length(indices)==1
  indices(2)=0;
end

% Trim between the indices
disp(sprintf('Data trimmed to lie between indices %i and %i inclusive',...
	     indices(1),size(fulldat,1)-indices(2)))
fulldat=fulldat(indices(1):size(fulldat,1)-indices(2),:);

% And by default you call the first index the zeroth hour
defval('timein',1)

% Get the actual magnetic data out of this array
data=fulldat(:,1);

% Determine the position relative to the indexed point
tint=etime(fulldat(2,[2:7]),fulldat(1,[2:7]));
offs=etime(fulldat(1,[2:7]),fulldat(timein,[2:7]));
tims=linspace(offs,[size(fulldat,1)-1]*tint+offs,size(fulldat,1));

% Make the plot and return plot handle
xt=axes;
p1=plot(tims,data);

% Ticks, Titling, and Cosmetics 
if max(tims)>3600
  tval=3600;
  tbla='hours';
else
  tval=60*15;
  tbla='15-minute intervals';
end
% Label the whole hours/minutes only
% If there are NO hours, we're talking minutes, baby
xtims=[tims(1) tims(~mod(tims,tval)) tims(end)];
xtimsu=unique(xtims);
set(xt,'XTick',xtimsu);
xtimsl=repmat({' '},1,length(xtimsu));
hh=find(~mod(xtimsu,tval));
for ind=1:length(hh)
  xtimsl{hh(ind)}=xtimsu(hh(ind))/tval;
end
set(xt,'xtickl',xtimsl)
set(xt,'ytickl',get(xt,'ytick'))

axis tight
ylim(xpand(ylim))
% SPECIAL CASE!! KATHLEEN WENT AND TOOK A GPS POINT AT THE BASE STATION
if strcmp(filename,'DigHouse10292013_1')
  ylim([45337 45356])
end

xlabel(sprintf('daytime [%s] since %s',tbla,datestr(fulldat(timein,[2:7]))),...
       'Fontsize',fs)
ylabel('magnetic field (nT)','Fontsize',fs)
set(xt,'Fontsize',fs)
% Extract the location from the filename
locashun=filename([abs(filename)>=97 & abs(filename)<=122] | ...
		  [abs(filename)>=65 & abs(filename)<=90] | ...
		  [abs(filename)>=48 & abs(filename)<=57]);
t=title(sprintf('Magnetic field at %s base station',locashun),'Fontsize',fs);
shrink(xt,1.,1.2)
movev(t,range(ylim)/15)
longticks(xt,2)
grid on

% Orient the figure properly
fig2print(gcf,'portrait')

% Put a SECOND axis on the right 
[ax,xl,yl]=xtraxis(xt,[],[],[],get(xt,'ytick'),...
		   get(xt,'ytick')-indeks(get(xt,'ytick'),1));
longticks(ax,2)

% Print the figure to file 
figna=figdisp(filename,[],[],1); 
system(sprintf('epstopdf %s.eps',figna));
system(sprintf('rm -f %s.eps',figna));

% Provide output if so desired
varns={data,p1};
varargout=varns(1:nargout);
