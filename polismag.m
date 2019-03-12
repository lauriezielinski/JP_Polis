function polismag(dnums,fnums,popt,sstr,newopt)
% POLISMAG(dnums,fnums,popt,sstr)
%
% Makes a plot of magnetometry, e.g. collected at Polis Chrysochous.
%
% INPUT:
%
% dnums    The directory numbers out of the total available list
% fnums    The file numbers out of the total available list
% popt     1 Plots the shifted lines (all of them)
%          2 Plots the field on the interpolation grid with shifted lines
%          3 Plots the original lines (all of them)
%          4 Plots the original LINES one by one (for prepping only)
%          5 Plots the original POINTS one by one (for prepping only)
% sstr     A search string applied to the directory [default: 'Polis']
% newopt   1 Decides ahead of time on a large field of view
%          0 Crops the coordinates
%
% EXAMPLE:
%
%% For all files in the Polis/Peristeres subdirectory
% polismag(2,[],1)
%
% Last modified by fjsimons-at-alum.mit.edu, 03/12/2019

% Set default values
defval('popt',1)
defval('sstr','Polis')
defval('newopt',0)

% Query all the directories in the pathname below
try 
  pname='/u/fjsimons/CLASSES/FRS-Cyprus/Magnetometry';
  % Find all the data directories inside the pathname above
  diros=ls2cell(fullfile(pname,sstr,'/'),1);
catch
  pname='/Users/Laurie/Documents/JP_Polis/Data/';
  % Find all the data directories inside the pathname above
  diros=ls2cell(fullfile(pname,sstr,'/'),1);
end

% Default is to do this for all available directories inside those
defval('dnums',1:length(diros))

% Loop over the directories
for ondex=dnums
  disp(sprintf('Loading directory %s',diros{ondex}))
  % Query all the DATA files in the directory
  try
    files=ls2cell(fullfile(diros{ondex},'*.dat'));
  catch
    disp(sprintf(' '))
    ls(diros{ondex})
    error(sprintf('\nThere appear to be no *.dat files in %s',diros{ondex}))
  end

  % Default is to do this for all available data

  % But not using defval since the loop will be messed up!
  defval('fnums',1:length(files))

  % Loop over all the files
  for index=fnums
      % Locate the data
      wheraminow=fullfile(diros{ondex},files{index});
      disp(sprintf('Loading file %s',wheraminow))
      % Read the data
      data=readmag(wheraminow);
      % Fix any filename special character issues
      fname=nounder(files{index});

      % Proceed to doing what's been asked
      switch popt
       case 1
	% Apply the offsets to the coordinates; you can request info plots!
	data2=rearrange(data,0);
	% Shifted data lines
	% pl=everythingplot(data2,fname);
	% Nicer to show the contrast, no pause
	linebylineplot(data2,fname,0);
       case 2
	% But here is where the real data analysis goes!
	% Apply the offsets to the coordinates
	data2=rearrange(data);
	% This used to be plotdata2Dl
	[~,Z,X,Y,z,x,y,res,deg]=plotmag(data2,2,[3 97]);	
	% Now I have access to all the data, and we will be saving it
	sfile=fullfile(diros{ondex},pref(fname));

	if exist([sfile '.mat'])~=2
	  save(sfile,'Z','X','Y','z','x','y','res','deg')
	end
	tl=title(fname);
	box on
       case 3
	% Original data lines
	% pl=everythingplot(data,fname);
	% Nicer to show the contrast, no pause
	linebylineplot(data,fname,0);
       case 4
	% For visualization preparation only, pause
	linebylineplot(data,fname,1);
       case 5
	% For visualization preparation only, pause
	pointbypointplot(data,fname,1);
      end

      % You could plot this outline if you had it
      try
%	plotERT
      end
      
      % Cosmetics
      longticks(gca,2)
      grid on

      % Don't like that the UTM zone is not in the file
      fig2print(gcf,'landscape')
      % Watch the x/ylabel bug after SURF
      [xl,yl]=utmlabels('36 S');

      if newopt==1
	% Focus on Petrides
	axis([.44823 .4485034062817501 3.87765 3.87787]*1e6)
      end

      % Save this shit
      figna=figdisp([],sprintf('%i_%i_%i',ondex,index,popt),[],2);
      
      if index~=fnums
	% Gives you a moment to inspect befor you hit RETURN to go on
	disp('Hit RETURN to continue')
	pause
      end
  end
  clear fnums
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data2=rearrange(data,ifpo)
% This function does the pole-holding GPS-carrying line adjustment
% INPUT
%
% data
% ifpo   1 Plot the original data and the shifts line by line on top of them
%        2 Plots the originals and the shifts, pauses, then removes originals
%        3 Details the line shifts line by line for maximum understanding

% Pause, perhaps?
defval('ifpo',0)

% Colors for the alternating lines
cols={'k','b'};
symbs={'s','o'};

% Always same distance in the direction of the line
d=1.5;

% Determine lineshift based on the first/each line
data2=data;
% Pick out the line, do the fit, keep track of fit
for ln=0:max(data(:,5))
  lain=data(:,5)==ln;
  % Shift the lines in the direction of pole movement
  [~,~,xs,ys,yy,x,~,p(ln+1,:)]=...
      lineshift(data(lain,1),data(lain,2),d,ln);
  % Redefine the line locations
  data2(lain,1)=xs;
  data2(lain,2)=ys;
  % Some plots to keep track, preliminary, I guess
  if ifpo==1
    pl=everythingplot(data,[],1);
    hold on
    pr=plot(x,yy,'r');
    ps=plot(xs,ys,'o');
    hold off
    pause
  end
end

% Now should also do a lineshift across
% Use every other line to determine the distance
% http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
% http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html
% Of course only do this for every non-overlapping pair
for ln=0:2:max(data(:,5))-2
  % One-direction
  lain1=data(:,5)==ln;
  % Same direction
  lain2=data(:,5)==ln+2;
  % Opposite direction in between 
  lain3=data(:,5)==ln+1;
  
  % Don't shift but just calculate the parameters - again, I know
  [~,~,~,~,yy1,x1,~,p1]=...
      lineshift(data(lain1,1),data(lain1,2),d,ln);
  [~,~,~,~,yy2,x2,~,p2]=...
      lineshift(data(lain2,1),data(lain2,2),d,ln+2);
  [~,~,~,~,yy3,x3,~,p3]=...
      lineshift(data(lain3,1),data(lain3,2),d,ln+1);
    
  % Figure out the distance between these two lines and the offset vector
  % to bring the first one closer to the second one
  [d,dvv]=linedist(x1,yy1,p1,x2,yy2,p2);
  [d3,dvv3]=linedist(x1,yy1,p1,x3,yy3,p3);
  
  % Then, armed with that knowledge, need to do some shifting
  % let's say that we shift every OTHER line to in-between pairs 
  % Redefine the line locations by the shifting back ACROSS!
  dvvx=-dvv3+dvv/2;
  
  % Comment this out if you're NOT doing the cross-shifting
  data2(lain3,1)=data2(lain3,1)+dvvx(:,1);
  data2(lain3,2)=data2(lain3,2)+dvvx(:,2);
  
  if ifpo==3
    clf
    plot(x1,yy1,'b'); hold on
    plot(x2,yy2,'r');
    % See if the blue line gets shifted to the red line as a green line
    plot(x1+dvv(:,1),yy1+dvv(:,2),'go');
    % See if the intermediate line gets shifted back to fall in line
    plot(x3,yy3,'k','LineWidth',2);
    plot(x3+dvvx(:,1),yy3+dvvx(:,2),'ks');
    pause
  end
end

% Some plots at the end to keep track
if ifpo==2
  pl1=everythingplot(data,[],1);
  set(pl1,'MarkerFaceColor',grey,'MarkerEdgeColor',grey)
  hold on
  pl2=everythingplot(data2,[],0);
  set(pl2,'Marker','o')
  hold off
  pause
  delete(pl1)
  pause
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function linebylineplot(data,tittel,ifpo)
% Line by line plotting of the lines

% Pause, perhaps?
defval('ifpo',1)

% Colors and symbols
cols={'k','b'};
symbs={'s','o'};

% Axis restrictions
axl=xpand([minmax(data(:,1)) minmax(data(:,2))],5);

% For each of the LINES
for ln=0:max(data(:,5))
  % Pick out the line
  lain=data(:,5)==ln;
  % The x and y positions of the line 
  ex=data(lain,1);
  yi=data(lain,2);
  pln(ln+1)=plot(ex,yi,'MarkerSize',4,...
		'MarkerFaceColor',cols{mod(ln,2)+1},...
		'MarkerEdgeColor',cols{mod(ln,2)+1},...
		        'Marker',symbs{mod(ln,2)+1});
  axis(axl)
  hold on
  tl=title(sprintf('%s Line %i',nounder(tittel),unique(data(lain,5))));
  if ifpo==1
    pause(0.1)
  end
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pointbypointplot(data,tittel,ifpo)
% Point by point plotting of the lines

% Pause, perhaps?
defval('ifpo',1)

% Colors and symbols
cols={'k','b'};
symbs={'s','o'};

% Axis restrictions
axl=xpand([minmax(data(:,1)) minmax(data(:,2))],5);

% For each of the POINTS
for in=size(data,1):-1:1
  ln=data(in,5);
  plot(data(in,1),data(in,2),'MarkerSize',4,...
       'MarkerFaceColor',cols{mod(ln,2)+1},...
       'MarkerEdgeColor',cols{mod(ln,2)+1},...
       'Marker',symbs{mod(ln,2)+1})
  axis(axl)
  hold on
  tl=title(sprintf('%s Line %i Mark %i',nounder(tittel),data(in,5),data(in,6)));
  if ifpo==1
    pause(0.01)
  end
end
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pl,tl]=everythingplot(data,tittel,rd)
% Plotting of all the line points together

defval('tittel',[])
defval('rd',0)

% Predefine colors and symbols for a random pick
cols={'b','g','r','c','m','y','k'};
syms={'.','x','+','.','x','+','.'};
if rd==1
  rando=randi(length(cols));
else
  rando=1;
end

% Plot using a random color symbol combination
pl=plot(data(:,1),data(:,2),...
	'Marker',syms{rando},'Color',cols{rando},'LineStyle','none');
axis image

% Open up the axis just a little bit
axis(xpand(axis,5))

% Display the title if you should do this one by one
tl=title(nounder(tittel));
