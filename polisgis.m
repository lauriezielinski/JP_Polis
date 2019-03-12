function varargout=polisgis(wot,plt)
% [pl,xl,yl,tl,utmzone]=POLISGIS(wot,plt)
%
% Plots some features of Polis Chrysochous from certain GIS databases
% 
% INPUT:
%
% wot      1 Plots walls from the Peristeries field
%          2 Plots roads in Cyprus around the Peristeries field
% plt      0 Make the plot but don't print it
%          1 Make the plot and print it also
%
% OUTPUT:
%
% pl       Handles to what's being plotted
% xl,yl    Handles to x and y axis labels
% tl       Handles to the title object
% utmzone  The UTM zone string 
%
% Tested on 8.3.0.532 (R2014a) and 9.0.0.341360 (R2016a)
% 
% Last modified by fjsimons-at-alum.mit.edu, 03/01/2019

defval('wot',1)
defval('plt',0)

% Set a path beyond which the code doesn't change
pname='/u/fjsimons/CLASSES/FRS-Cyprus/dropbox-2011/Cyprus/CyprusGIS/webGIS/';
if ~exist(pname)
  pname='/Users/Laurie/Documents/JP_Polis/Data';
end

switch wot
  case 1
   % Looks like the original was in Transverse Mercator, don't bother for
   % now, Adam converted it to the same systems as "roads"... copying the file
   fname='PeristeriesWalls';
   titst='Peristeries Plateau (Polis Chrysochous, Cyprus) Sanctuary B.D7';
   % Limits of the region being shown
   axlim=[32.43   32.45   35.0410   35.0420];
   % Line widths
   lw=0.5;
 case 2
  fname='roads';
  titst='Peristeries Plateau (Polis Chrysochous, Cyprus) Roads';
  axlim=[32.4225   32.4375   35.037   35.043];
  % Line widths
  lw=1;
end

% Combine the path name and the file name
fname=fullfile(pname,fname);

% The corrsponding Matlab-format file name 
mname=sprintf('%s.mat',fname);

% Load the features from the GIS database and resaves them
if ~exist(mname,'file')
  hh=shaperead(fname);
  save(mname,'hh')
else
  load(mname);
end
lon=[hh(:).X]; lon=lon(:);
lat=[hh(:).Y]; lat=lat(:);
% can also do cat(1,hh.X)

% Convert features to UTM grid
[lonutm,latutm,axutm,utmzone]=croputm(axlim,lon,lat);

% Do the actual plotting
hold on
pl=plot(lonutm,latutm,'k-');
hold off

axis equal
% axis axutm

% Cosmetics for gridding and axes labels
set(pl,'LineW',lw)

if plt==1
  % Assume this is all in the same UTM zone
  [xl,yl]=utmlabels(utmzone(1,:));
  tl=title(titst);
  set(tl,'FontS',15)
  movev(tl,1)
  box on
  
  % Print a standalone figure
  fig2print(gcf,'landscape')
  figna=figdisp([],wot,[],1);
  system(sprintf('epstopdf %s.eps',figna));
  system(sprintf('rm -f %s.eps',figna));
else
  [xl,yl,tl]=deal(NaN);
end

% OUTPUT
varns={pl,xl,yl,utmzone};
varargout=varns(1:nargout);
