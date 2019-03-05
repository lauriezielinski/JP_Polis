function [XYHDout,XYHDpoly]=removepoly(XYHD,deg)
% [XYHDout,XYHDpoly]=removepoly(XYHD,deg)
%
% Removes a twodimensional polynomial trend from magnetic data read by the
% function READMAG.
%
% INPUT:
%
% XYHD  Magnetic data in the format created by the function READMAG
% deg   Degree of the two-dimensional polynomial you wish to fit and remove
% 
% OUTPUT:
%
% XYHDout   Data with removed polynomial
% XYHDpoly  The polynomial that was fitted and removed
%
% EXAMPLE:
%
% data=readmag('somefilename.dat');
% [datarem,polyfit]=removepoly(data,3); % Remove a 2d polynomial of deg 3
% plotdata2Dl(datarem) % Plot the detrended data
% figure; plotdata2Dl(polyfit) % Plot the fitted polynomial
%
% SEE ALSO:
%
% READMAG, POLISMAG
%
% Last modified by plattner-at-alumni.ethz.ch, 10/25/2012
% Last modified by fjsimons-at-alum.mit.edu, 03/01/2019

%% Step 0: Preparing the data
% Before continuing, bring x,y, and d into reasonable range 
% (only translating, no scaling)
meanx=mean(XYHD(:,1));
x=XYHD(:,1)-meanx;

meany=mean(XYHD(:,2));
y=XYHD(:,2)-meany;

meand=mean(XYHD(:,4));
d=XYHD(:,4)-meand;

f=zeros(size(x));

%% Step 1: Find the coefficients of the twodimensional polynomial
% f=a_00 + a_10x + a_01y + a_11xy + ...
% Setup the matrix
M=zeros(length(x),(deg+1)^2);
for i=1:length(x)
  xpol=x(i).^(0:deg);
  ypol=y(i).^(0:deg);
  tudypolvals=xpol'*ypol;
  M(i,:)=tudypolvals(:)';
end

% Solve the least squares fitting problem M'Mc=M'd
c=(M'*M)\(M'*d);

%% Step 2: Calculate the polynomial's values at the points
for i=1:length(x)
  xpol=x(i).^(0:deg);
  ypol=y(i).^(0:deg);
  tudypolvals=xpol'*ypol;
  f(i)=c'*tudypolvals(:);
end
   
%% Step 3: Subtract the polynomial from the data
XYHDout=[x+meanx y+meany XYHD(:,3) d-f XYHD(:,5)];    
XYHDpoly=[x+meanx y+meany XYHD(:,3) f+meand XYHD(:,5)]; 
    
