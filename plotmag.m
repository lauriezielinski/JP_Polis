function varargout=plotmag(data,res,percs,deg,sofs)
% Zmax=plotmag(data,res,percs,deg,sofs)
%
% Plots a data matrix containing magnetic field as an interpolated map
%
% INPUT:
%
% data       the data to be plotted (loaded with READMAG)
% res        inverse fraction of the data length for interpolation
% percs      percentiles of the data for the color bar range [1 99]
% deg        polynomial degree of what will be fitted and removed
% sofs       1 reference the data to the westernmost/southernmost point
%            0 don't
% 
% OUTPUT:
%
% Zmax       Maximum of the data plotted (for overlays using PLOT3)
%
% See also READMAG, PLOTSURVEY, POLISMAG
%
% Last modified by fjsimons-at-alum.mit.edu, 03/01/2019

% Resolution parameter
defval('res',50);

% Default font size
defval('fs',12)

% Default data percentiles for color range
defval('percs',[1 99])

% Polynomials to be removed
defval('deg',1)

% Geographic corner reference
defval('sofs',0)

% Remove some polynomials
data2=data;
if deg>0
  disp(sprintf('Polynomials up to degree %i removed',deg))
  data2=removepoly(data,deg);
end

% Location
x=data2(:,1);
y=data2(:,2);
% The magnetic data in the original unit 
z=data2(:,4);

% And shift to meaningful x and y axes
if sofs==1
  ofsx=min(x);
  ofsy=min(y);
else
  [ofsx,ofsy]=deal(0);
end
x=x-ofsx;
y=y-ofsy;

% Prepare the interpolation "handle"
warning('off','MATLAB:TriScatteredInterp:DupPtsAvValuesWarnId')
F=TriScatteredInterp(x,y,z,'natural');
warning('on','MATLAB:TriScatteredInterp:DupPtsAvValuesWarnId')

% Make a grid to interpolate on
xp=linspace(min(x),max(x),ceil(length(x)/res));
yp=linspace(min(y),max(y),ceil(length(y)/res));

% Make the 2D grid, pairs of values 
[X,Y]=meshgrid(xp,yp);

% Then do the interpolation 
Z=F(X,Y);

disp(sprintf('Creating %i by %i field',size(Z)))

% Prepare labels
utmzone=18;
utmletr='T';
Zmax=max(Z(:));

% Make the plot
%imagesc(xp,yp,Z)
surf(X,Y,Z)
view(2)
noticks(gca,3)
axis equal
shading interp
% Open up the map axis just a little bit
axis image
axis(xpand(axis,5))
box on
if sofs==1
  exel=sprintf('m east of UTM zone %i %i easting',utmzone,round(ofsx));
  wyel=sprintf('m north of UTM zon %i %i northing',utmzone,round(ofsy));
  xl=xlabel(exel);
  yl=ylabel(wyel);
else
  [xl,yl]=utmlabels(sprintf('%i %s',utmzone,utmletr));
end
tl=title(sprintf('interpolated magnetic field (resolution %i degree %i removed)',res,deg));

% Do the color bar later - now we've removed the poly's
caxis(prctile(Z(:),percs))
cb=colorbar;
tox=get(cb,'ylim');
tix=linspace(tox(1),tox(2),9);
set(cb,'YTick',tix,'YtickLabel',tix)
ylcb=ylabel(cb,'magnetic field (nT)');
% Make
set(cb,'YtickLabel',round(get(cb,'ytick')))

% Cosmetics
set([xl yl tl ylcb],'FontSize',fs)
figdisp([],[],[],0)

% Output
varns={Zmax};
varargout=varns(1:nargout);

