%                             Transverse isotropic case

close all;  %close all extra windows
clc;        %clear console
clear all;  %clear all variables

% Grid size
% For simplicity have uniform grid and mg is required to change
% simultaneously both grid size in both directions and time step, to have
% dx/dt to be constant
 mg=1;
 NX =100*mg;  %X
 NY =100*mg;  %Y
 
 time=0.02d0;  %total duration of observation
 
 % time step in seconds
 DELTAT = 0.5d-4;	%[sec] %time step
 DELTAT = DELTAT/mg; % modify timestep depending on the grid size
 
 NSTEP = round(time/DELTAT); % number of time steps
 time_vec = [1:NSTEP]'*DELTAT; %time vector, that represents all time steps

YMAX=50.d0; %[m] max size of model in physical domain
XMAX=50.d0; %[m]

XMIN=0.d0; %[m] min size of model in physical domain
YMIN=0.d0; %[m]

DELTAX=(XMAX-XMIN)/NX; %[m] grid step
DELTAY=(YMAX-YMIN)/NY; %[m]
IT_DISPLAY = 25; % show image every ... time steps
%--------------------------------------------------------------------------
%---------------------- FLAGS --------------------------------------------- 
SNAPSHOT=false; %Take snapshot of ongoing image
snapshot_time=400:50:NSTEP; %on what steps

SHOW_SOURCE_POSITION=true; %Show source position on the graph?

PAUSE_ON=false; %If works to fast then pause a little bit each iteration
pause_time=0.1; %[sec]

% Show what component of wavefield?
SHOW_UX_WF =false; 
SHOW_UY_WF =true;

%Record video, because video is being created by capturing of current frame
%Matlab 2012 + required, saves video to a current folder
MAKE_MOVIE=false;
tagv='mzm100'; 

% flags to add PML layers to the edges of the grid(has not been applied yet)
USE_PML_XMIN = false;
USE_PML_XMAX = false;
USE_PML_YMIN = false;
USE_PML_YMAX = false;

DISP_NORM=false;     %plot normal displacement

DATA_TO_BINARY_FILE=false;  %save wavefield data to binary files for each iteration
tag='mz_';

SAVE_SEISMOGRAMS=false;      % save seismograms for each receiver to txt files
SHOW_REC_POSITION = false;   % plot reciever line
seis_tag=['mz2Dgauss' num2str(NX)];

RED_BLUE=false;     %use custom red-blue colormap
COLORBAR_ON=false;   %show colorbar

FE_BOUNDARY=true;   %homogeneous or heterogeneous media
LEFT_R = true;      %flat \ or / oblique interface
DEBUG_MODE = false; % show step by step operator construction

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% parameters for the source
f0= 600.d0;
t0 = 1.20d0 / f0; %duration of excitation of the source
factor = 1.d6; %amplitude-like term

%Initiate video object for vy
if MAKE_MOVIE
    movie_name=[tagv num2str(NX) '_' num2str(NY) '_' num2str(f0) 'hz' '.avi'];
    vidObj_mv=VideoWriter(movie_name);
    open(vidObj_mv);
end

eps=0.00000000001d0; %small value

if FE_BOUNDARY %set parameters over the interface
     fprintf('ON. Lithological boundary\n');
     cp_below_eb=1800.d0;
     cp_above_eb=3300.d0;
     rho_below_eb=2400.d0;
     rho_above_eb=2400.d0;
     fprintf('  cp_above=%.2f rho_above=%.2f\n', cp_above_eb, rho_above_eb);
     fprintf('  cp_below=%.2f rho_below=%.2f\n', cp_below_eb, rho_below_eb);
else
     fprintf('OFF. Lithological boundary\n');
     cp_above_eb=1800.d0;
     cp_below_eb=1800.d0;
     rho_above_eb=2400.d0;
     rho_below_eb=2400.d0;
     fprintf('  cp_above=%.2f rho_above=%.2f\n', cp_above_eb, rho_above_eb);
     fprintf('  cp_below=%.2f rho_below=%.2f\n', cp_below_eb, rho_below_eb);
end

%anisotropic
% % zinc, from Komatitsch et al. (2000)
% c11 = 16.5d10;
% c13 = 5.d10;
% c33 = 6.2d10;
% c44 = 3.96d10;
% rho = 7100.d0;
% % f0 = 170.d3;
% f0 = 100;
% 
% % apatite, from Komatitsch et al. (2000)
% c11 = 16.7d10;
% c13 = 6.6d10;
% c33 = 14.d10;
% c44 = 6.63d10;
% rho = 3200.d0;
% f0 = 300.d3;

% % isotropic material a bit similar to apatite
% c11 = 16.7d10;
% c13 = c11/3.d0;
% c33 = c11;
% c44 = (c11-c13)/2.d0;  % = c11/3.d0
% density = 3200.d0;
% f0 = 300.d3;

% % model I from Becache, Fauqueux and Joly, which is stable
% scale_aniso = 1.d10;
% c11 = 4.d0 * scale_aniso;
% c13 = 3.8d0 * scale_aniso;
% c33 = 20.d0 * scale_aniso;
% c44 = 2.d0 * scale_aniso;
% density = 4000.d0;  % used to be 1.
% f0 = 450.d3;

% model II from Becache, Fauqueux and Joly, which is stable
% scale_aniso = 1.d10;
% c11 = 20.d0 * scale_aniso;
% c13 = 3.8d0 * scale_aniso;
% c33 = c11;
% c44 = 2.d0 * scale_aniso;
% density = 4000.d0;  % used to be 1.
% f0 = 200.d3;
% f0=170.d0;
% density= rho;
% cp = max(sqrt(c33/density),sqrt(c11/density));
  
% True isotropic
density= rho_above_eb;
cp = cp_above_eb;	%[km/s]
cs = cp / 1.732d0;	%[km/s]
lambda =density*(cp*cp - 2.d0*cs*cs);
mu = density*cs*cs;

c11 = (lambda + 2.d0*mu);
c13 = lambda;
c33 = c11;
c44 = mu;

%  f0 = 20.d0;%0.d3;
% f0=200.d0;
% f0=150.d0;

%From Roland Martin code
% from Becache et al., INRIA report, equation 7 page 5 http://hal.inria.fr/docs/00/07/22/83/PDF/RR-4304.pdf
  if(c11*c33 - c13*c13 <= 0.d0)
      disp('problem in definition of orthotropic material');
      %break
  end

% check intrinsic mathematical stability of PML model for an anisotropic material
% from E. B\'ecache, S. Fauqueux and P. Joly, Stability of Perfectly Matched Layers, group
% velocities and anisotropic waves, Journal of Computational Physics, 188(2), p. 399-433 (2003)
  aniso_stability_criterion = ((c13+c44)^2 - c11*(c33-c44)) * ((c13+c44)^2 + c44*(c33-c44));
  fprintf('PML anisotropy stability criterion from Becache et al. 2003 = %e\n', aniso_stability_criterion);
  if(aniso_stability_criterion > 0.d0 && (USE_PML_XMIN  ||  USE_PML_XMAX  ||  USE_PML_YMIN  ||  USE_PML_YMAX))
     fprintf('WARNING: PML model mathematically intrinsically unstable for this anisotropic material for condition 1');
     %break
  end

  aniso2 = (c13 + 2*c44)^2 - c11*c33;
  fprintf('PML aniso2 stability criterion from Becache et al. 2003 = %e\n',aniso2);
  if(aniso2 > 0.d0 && (USE_PML_XMIN  ||  USE_PML_XMAX  ||  USE_PML_YMIN  ||  USE_PML_YMAX))
     fprintf('WARNING: PML model mathematically intrinsically unstable for this anisotropic material for condition 2');
     %break
  end

  aniso3 = (c13 + c44)^2 - c11*c33 - c44^2;
  fprintf('PML aniso3 stability criterion from Becache et al. 2003 = %e\n',aniso3);
  if(aniso3 > 0.d0 && (USE_PML_XMIN  ||  USE_PML_XMAX  ||  USE_PML_YMIN  ||  USE_PML_YMAX))
     fprintf('WARNING: PML model mathematically intrinsically unstable for this anisotropic material for condition 3');
     %break
  end
 
%------------------------------------------------------------------

%vectors for visualisation using imagesec
nx_vec=[0:NX]*DELTAX;	%[m]
ny_vec=[0:NY]*DELTAY;


% thickness of the PML layer in grid points
NPOINTS_PML = 10;

% angle of source force clockwise with respect to vertical (Y) axis
if LEFT_R
    ANGLE_FORCE = 135.d0;
else
    ANGLE_FORCE = 45.d0;
end
% value of PI
PI = 3.141592653589793238462643d0;

% conversion from degrees to radians
DEGREES_TO_RADIANS = PI / 180.d0;

% zero
ZERO = 0.d0;

% large value for maximum
HUGEVAL = 1.d+30;

% velocity threshold above which we consider that the code became unstable
STABILITY_THRESHOLD = 1.d+25;

if LEFT_R % set source position in physical domain depending on the case
    %left \
    xsource=round(18*NX/40)*DELTAX; %[m]
    ysource=round(16*NY/40)*DELTAY; %[m]
else
    %right /
    xsource=round(22*NX/40)*DELTAX; %[m]
    ysource=round(16*NY/40)*DELTAY; %[m]
end

%find corresponding source position in computational domain 
dist = HUGEVAL;
for j = 2:NY
for i = 2:NX
  distval = sqrt((DELTAX*double(i-1) - xsource)^2 + (DELTAY*double(j-1) - ysource)^2);
  if(distval < dist)
    dist = distval;
    ISOURCE = i;
    JSOURCE = j;
  end
end
end
ISOURCE = ISOURCE -1;
JSOURCE = JSOURCE -1;
xsource=ISOURCE*DELTAX; % final source position that has been placed to the
ysource=JSOURCE*DELTAY; % closest grid node in physical domain 

%Arrays
ux=zeros(3,NX+1,NY+1); %displacements over X and Y
uy=zeros(3,NX+1,NY+1);

rho=zeros(NX+1,NY+1); %density

%   total_energy_kinetic=zeros(NSTEP);
%   total_energy_potential=zeros(NSTEP);

%-----------------------------------------
% Everything for PMLs
%-----------------------------------------
% power to compute d0 profile
NPOWER = 2.d0;

K_MAX_PML = 1.d0; % from Gedney page 8.11
ALPHA_MAX_PML = 2.d0*PI*(f0/2.d0); % from Festa and Vilotte

% could declare these arrays in PML only to save a lot of memory, but proof of concept only here
memory_dux_dxx=zeros(NX+1,NY+1);
memory_duy_dyy=zeros(NX+1,NY+1);
memory_dux_dxy=zeros(NX+1,NY+1);
memory_duy_dxy=zeros(NX+1,NY+1);

% 1D arrays for the damping profiles
d_x=zeros(NX+1,1);
K_x=zeros(NX+1,1);
alpha_x=zeros(NX+1,1);
a_x=zeros(NX+1,1);
b_x=zeros(NX+1,1);

d_y=zeros(NY+1,1);
K_y=zeros(NY+1,1);
alpha_y=zeros(NY+1,1);
a_y=zeros(NY+1,1);
b_y=zeros(NY+1,1);

%--- define profile of absorption in PML region ---
% thickness of the PML layer in meters
  thickness_PML_x = NPOINTS_PML * DELTAX;
  thickness_PML_y = NPOINTS_PML * DELTAY;

% reflection coefficient (INRIA report section 6.1) http://hal.inria.fr/docs/00/07/32/19/PDF/RR-3471.pdf
  Rcoef = 0.001d0;

% check that NPOWER is okaymarkers=zeros(nx+1,ny+1);
  if(NPOWER < 1)       
      disp('NPOWER must be greater than 1');
      %break;
  end
  
% compute d0 from INRIA report section 6.1 http://hal.inria.fr/docs/00/07/32/19/PDF/RR-3471.pdf
  d0_x = - (NPOWER + 1.d0) * cp * log(Rcoef) / (2.d0 * thickness_PML_x);
  d0_y = - (NPOWER + 1.d0) * cp * log(Rcoef) / (2.d0 * thickness_PML_y);
 
%   fprintf('d0_x = %.2f\n',d0_x);
%   fprintf('d0_y = %.2f\n\n',d0_y);

  d_x(:) = ZERO;
  K_x(:) = 1.d0;
  alpha_x(:) = ZERO;
  a_x(:) = ZERO;

  d_y(:) = ZERO;
  K_y(:) = 1.d0;
  alpha_y(:) = ZERO;
  a_y(:) = ZERO;
  %break;
%--------------------------------------------------------------------------
% damping in the X direction

%PMLs by Roland Martin
% origin of the PML layer (position of right edge minus thickness, in meters)
  xoriginleft = thickness_PML_x;
  xoriginright = (NX-1)*DELTAX - thickness_PML_x;

for i = 1:NX+1
    % abscissa of current grid point along the damping profile
    xval = DELTAX * double(i-1);
    %---------- left edge
    if(USE_PML_XMIN)
        % define damping profile at the grid points
        abscissa_in_PML = xoriginleft - xval;
        if(abscissa_in_PML >= ZERO)
            abscissa_normalized = abscissa_in_PML / thickness_PML_x;
            d_x(i) = d0_x * abscissa_normalized^NPOWER;
            % this taken from Gedney page 8.2
            K_x(i) = 1.d0 + (K_MAX_PML - 1.d0) * abscissa_normalized^NPOWER;
            alpha_x(i) = ALPHA_MAX_PML * (1.d0 - abscissa_normalized) + 0.1d0 * ALPHA_MAX_PML;
        end
    end

%---------- right edge
   if(USE_PML_XMAX)
        % define damping profile at the grid points
        abscissa_in_PML = xval - xoriginright;
        if(abscissa_in_PML >= ZERO)
            abscissa_normalized = abscissa_in_PML / thickness_PML_x;
            d_x(i) = d0_x * abscissa_normalized^NPOWER;
            % this taken from Gedney page 8.2
            K_x(i) = 1.d0 + (K_MAX_PML - 1.d0) * abscissa_normalized^NPOWER;
            alpha_x(i) = ALPHA_MAX_PML * (1.d0 - abscissa_normalized) + 0.1d0 * ALPHA_MAX_PML;
        end
   end

    % just in case, for -5 at the end
    if(alpha_x(i) < ZERO) 
        alpha_x(i) = ZERO;
    end

    b_x(i) = exp(- (d_x(i) / K_x(i) + alpha_x(i)) * DELTAT);
  
    % this to avoid division by zero outside the PML
    if(abs(d_x(i)) > 1.d-6) 
        a_x(i) = d_x(i) * (b_x(i) - 1.d0) / (K_x(i) * (d_x(i) + K_x(i) * alpha_x(i)));
    end    
  end

%--------------------------------------------------------------------------
% damping in the Y direction

% origin of the PML layer (position of right edge minus thickness, in meters)
  yoriginbottom = thickness_PML_y;
  yorigintop = (NY-1)*DELTAY - thickness_PML_y;

  for j = 1:NY+1
    % abscissa of current grid point along the damping profile
    yval = DELTAY * double(j-1);
    %---------- bottom edge
    if(USE_PML_YMIN)
      % define damping profile at the grid points
      abscissa_in_PML = yoriginbottom - yval;
      if(abscissa_in_PML >= ZERO)
        abscissa_normalized = abscissa_in_PML / thickness_PML_y;
        d_y(j) = d0_y * abscissa_normalized^NPOWER;
        % this taken from Gedney page 8.2
        K_y(j) = 1.d0 + (K_MAX_PML - 1.d0) * abscissa_normalized^NPOWER;
        alpha_y(j) = ALPHA_MAX_PML * (1.d0 - abscissa_normalized) + 0.1d0 * ALPHA_MAX_PML;
      end
    end

%---------- top edge
    if(USE_PML_YMAX)
      % define damping profile at the grid points
      abscissa_in_PML = yval - yorigintop;
      if(abscissa_in_PML >= ZERO)
        abscissa_normalized = abscissa_in_PML / thickness_PML_y;
        d_y(j) = d0_y * abscissa_normalized^NPOWER;
        % this taken from Gedney page 8.2
        K_y(j) = 1.d0 + (K_MAX_PML - 1.d0) * abscissa_normalized^NPOWER;
        alpha_y(j) = ALPHA_MAX_PML * (1.d0 - abscissa_normalized) + 0.1d0 * ALPHA_MAX_PML;
      end
    end

    b_y(j) = exp(- (d_y(j) / K_y(j) + alpha_y(j)) * DELTAT);
    
    % this to avoid division by zero outside the PML
    if(abs(d_y(j)) > 1.d-6)
        a_y(j) = d_y(j) * (b_y(j) - 1.d0) / (K_y(j) * (d_y(j) + K_y(j) * alpha_y(j)));
    end  
  end
  
%---------------------------------------------
% Output of general information
%---------------------------------------------
fprintf('2D elastic finite-difference code in displacement formulation with C-PML\n\n');
fprintf('NX = %d  ',NX);
fprintf('NY = %d  ',NY);
fprintf('%d in total\n',NX*NY);
fprintf(' dx = %f  dy=%f  dt=%e\n',DELTAX,DELTAY,DELTAT);
fprintf('Size of the model: %.2f m x ',NX*DELTAX);
fprintf('%.2f\n',NY*DELTAY);
fprintf('\n');
  
% R. Courant et K. O. Friedrichs et H. Lewy (1928)
  Courant_number = cp * DELTAT * sqrt(1.d0/DELTAX^2.d0 + 1.d0/DELTAY^2.d0);
  fprintf('Courant number = %.4f\n',Courant_number);
  fprintf('Check stability');
  if Courant_number > 1.d0 
      disp('Error. Time step is too large, simulation will be unstable.');
      %break;
  end
  fprintf('...OK\n');
  fprintf('\n');
  
% Place receivers
if SAVE_SEISMOGRAMS
    fprintf('ON. Save seismograms\n');
    NREC=41; %number of receivers
    fprintf('Set %d recievers:\n',NREC);
    if LEFT_R
        % receivers are placed in line
        xdeb=0.2d0*XMAX; % x begin
        xfin=0.8d0*XMAX; % x end
        ydeb=0.2d0*YMAX; % y begin
        yfin=0.8d0*YMAX; % y end
    else
        xdeb=0.2d0*XMAX;
        xfin=0.8d0*XMAX;
        ydeb=0.8d0*YMAX;
        yfin=0.2d0*YMAX;
    end

    fprintf('  x0=%.2f  x1=%.2f\n  y0=%.2f  y1=%.2f\n', xdeb,xfin,ydeb,yfin);

    % for receivers
    ix_rec=zeros(NREC,1); % x position of each receiver on grid
    iy_rec=zeros(NREC,1); % y position of each receiver on grid
    xrec=zeros(NREC,1); % x position of each receiver in physical domain
    yrec=zeros(NREC,1); % y position of each receiver in physical domain

    seisux=zeros(NSTEP,NREC); %seismograms for each time step for each receiver
    seisuy=zeros(NSTEP,NREC);

    xspacerec = (xfin-xdeb) / double(NREC-1); %find x step between receivers along the receiver line
    yspacerec = (yfin-ydeb) / double(NREC-1); %find x step between receivers along the receiver line
    for irec=1:NREC %set position of each receiver in physical domain
         xrec(irec) = xdeb + double(irec-1)*xspacerec;
         yrec(irec) = ydeb + double(irec-1)*yspacerec;
    end

    % find closest grid point for each receiver
    for irec=1:NREC
       dist = HUGEVAL;
       for j = 2:NY
        for i = 2:NX
          distval = sqrt((DELTAX*double(i-1) - xrec(irec))^2 + (DELTAY*double(j-1) - yrec(irec))^2);
          if(distval < dist)
            dist = distval;
            ix_rec(irec) = i;
            iy_rec(irec) = j;
          end
        end
       end
       fprintf('Reciever %d at x= %.2f y= %.2f\n',irec,xrec(irec), yrec(irec));
    end
    fprintf('Source position:  '); % additional output
    fprintf('x = %.2f  ',xsource);
    fprintf('y = %.2f\n',ysource);

    fprintf('%d files will be saved to %s',2*NREC,pwd)
    fprintf('\n ...OK\n');
end
%--------------------------------------------------------------------------


%Find reflection and transition coefficients
Refl_coef=(rho_below_eb*cp_below_eb-rho_above_eb*cp_above_eb)/(rho_below_eb*cp_below_eb+rho_above_eb*cp_above_eb);
Trans_coef=2.d0*rho_below_eb*cp_below_eb/(rho_below_eb*cp_below_eb+rho_above_eb*cp_above_eb);
if Refl_coef<ZERO
  tmps=', inverse polarity';
else
  tmps='';
end
fprintf('Below --> Above:\n');
fprintf('  R= %.2f - reflection%s\n  T= %.2f - transmition\n', Refl_coef, tmps ,Trans_coef);
clearvars  Refl_coef Trans_coef tmps;


%Set initial values for arrays (in fact it is not required in matlab)
  ux(:,:,:) = ZERO;
  uy(:,:,:) = ZERO;

% PML
  memory_dux_dxx(:,:) = ZERO;
  memory_duy_dyy(:,:) = ZERO;
  memory_duy_dxy(:,:) = ZERO;
  memory_dux_dxy(:,:) = ZERO;

% initialize seismograms
  seisux(:,:) = ZERO;
  seisuy(:,:) = ZERO;

% % initialize total energy
%   total_energy_kinetic(:) = ZERO;
%   total_energy_potential(:) = ZERO;

 if RED_BLUE % create custom colormap
  fprintf('Set custom colormap');
  CMAP=zeros(256,3);
  c1=[0 0 1]; %blue
  c2=[1 1 1]; %white
  c3=[1 0 0]; %red
      for nc=1:128
          f=(nc-1)/128;
          c=(1-sqrt(f))*c1+sqrt(f)*c2;
          CMAP(nc,:)=c;
          c=(1-f^2)*c2+f^2*c3;
          CMAP(128+nc,:)=c;
      end
      colormap(CMAP);
     fprintf('...OK\n');   
  end
  
fprintf('Cartesian grid generation'); %required to find involved points for Mizutani operator
%grid point coordinates in physical domain
gr_x=zeros(NX+1,NY+1);
gr_y=zeros(NX+1,NY+1);
for i=1:NX+1
    for j=1:NY+1
        gr_x(i,j)=(i-1)*DELTAX;
        gr_y(i,j)=(j-1)*DELTAY;    
    end    
end
fprintf('...OK\n');
  
fprintf('Find closest grid nodes')  
curvature=0.2;
% curvature=0.0000001;
% xdscr=[0:NX]*DELTAX;
% ymid=((YMAX+YMIN)/2.d0)/3.d0;
% ydscr=-curvature*YMAX*sin(1.25*PI*xdscr/max(xdscr)+0.25*PI);

if LEFT_R
    ymid=YMAX;
    xdscr=linspace(XMIN,XMAX,(40*NX)+1);
    ydscr=-YMAX*xdscr/max(xdscr);
    ydscr=ymid+ydscr;
else
    ymid=0;
    xdscr=linspace(XMIN,XMAX,(40*NX)+1);
    ydscr=YMAX*xdscr/max(xdscr);
    ydscr=ymid+ydscr;
end

%calculate involved grid points
%normal vectors, coordinates of middles of the descritized samples.
%All the output variables are vectors
[markers, xt_dis, yt_dis, nvecx, nvecy, xmn, ymn] = func_p_find_closest_grid_nodes(NX,NY,1,gr_x,gr_y ,xdscr, ydscr);
 clearvars xt_dis nvecx nvecy yt_dis xmn ymn;  
fprintf('...OK\n')

%------------------------------------------------------------------------
C=zeros(NX+1,NY+1,4);
        
% compute the Lame parameters and density  
% Create Cijkl matrix

nice_matrix=zeros(NX+1,NY+1);
densitya = rho_above_eb;
cpa = cp_above_eb;	%[km/s]
csa = cpa / 1.732d0;	%[km/s]
lambdaa =densitya*(cpa*cpa - 2.d0*csa*csa);
mua = densitya*csa*csa;
densityb = rho_below_eb;
cpb = cp_below_eb;	%[km/s]
csb = cpb / 1.732d0;	%[km/s]
lambdab =densityb*(cpb*cpb - 2.d0*csb*csb);
mub = densityb*csb*csb;
topo_szx=length(xdscr);
tgrx=round(topo_szx/NX);

c11a = (lambdaa + 2.d0*mua);
c13a = lambdaa;
c33a = c11a;
c44a = mua;

c11b = (lambdab + 2.d0*mub);
c13b = lambdab;
c33b = c11b;
c44b = mub;

%  scale_aniso = 1.d10;
% c11b = 4.d0 * scale_aniso;
% c13b = 3.8d0 * scale_aniso;
% c33b = 20.d0 * scale_aniso;
% c44b = 2.d0 * scale_aniso;
% rho_below_eb = 4000.d0;  % used to be 1.
% % f0 = 200.d3;
% % f0 = 450.d0;
% f0 = 10.d0;
% 
% % % model II from Becache, Fauqueux and Joly, which is stable
%  c11a = 20.d0 * scale_aniso;
%  c13a = 3.8d0 * scale_aniso;
%  c33a = c11a;
%  c44a = 2.d0 * scale_aniso;
%  rho_above_eb = 4000.d0;  % used to be 1.

fprintf('\nCreate C 6D %d elements\n',NX*NY*4);
for i = 1:NX
    x_trial=(1+(i-1)*tgrx):(i*tgrx);
    for j = 1:NY
        y_trial=ny_vec(j);
        if y_trial>=ydscr(x_trial)
            C(i,j,:)=[c11a c13a c33a c44a];
            rho(i,j) = rho_above_eb;
            nice_matrix(i,j)=1.d0;
            if i==NX
                C(i+1,j,:)=[c11a c13a c33a c44a];
                rho(i+1,j) = rho_above_eb;
                nice_matrix(i+1,j)=1.d0;
            end
            if j==NY
                C(i,j+1,:)=[c11a c13a c33a c44a];
                rho(i,j+1) = rho_above_eb;
                nice_matrix(i,j+1)=1.d0;%      cp_below_eb=1800.d0;
%      cp_above_eb=3300.d0;

            end
        else
            C(i,j,:)=[c11b c13b c33b c44b];
            rho(i,j) = rho_below_eb;
            nice_matrix(i,j)=0.d0;
            if i==NX
                C(i+1,j,:)=[c11b c13b c33b c44b];
                rho(i+1,j) = rho_below_eb;
                nice_matrix(i+1,j)=1.d0;
            end
            if j==NY
                C(i,j+1,:)=[c11b c13b c33b c44b];
                rho(i,j+1) = rho_below_eb;
                nice_matrix(i,j+1)=1.d0;
            end
        end
    end
end
C(i+1,j+1,:)=[c11a c13a c33a c44a];
rho(i+1,j+1) = rho_above_eb;
% dlmwrite('cijtr', C);
% fprintf('C(i,j,4) saved to %s\n', pwd);
clearvars densitya cpa csa lambdaa mua densityb cpb csb lambdab mub;
clearvars x_trial y_trial topo_szx tgrx;
clearvars c11a c13a c33a c44a c11b c13b c33b c44b;
fprintf('C(i,j,4) of size: %s  ...OK\n',num2str(size(C)));

fprintf('\n');

fprintf('Constructing coeff{i,j}');
% fprintf('Keep calm. It can take couple of minutes.\n');

arr_eta0x=zeros(NX,NY,9);
arr_eta1x=zeros(NX,NY,9);
arr_eta0y=zeros(NX,NY,9);
arr_eta1y=zeros(NX,NY,9);

coeffux=cell(NX,NY);
coeffuy=cell(NX,NY);

dx = DELTAX; 
dy = DELTAY;
dx2 = DELTAX^2.d0;
dy2 = DELTAY^2.d0;
ddx = 2.d0*DELTAX;
ddy = 2.d0*DELTAY;
dxdy4 = 4.d0*DELTAX*DELTAY;

one_over_2dx2 = 1.d0/(2.d0*DELTAX^2.d0);
one_over_2dy2 = 1.d0/(2.d0*DELTAY^2.d0);
one_over_2dxdy4 = 1.d0/(2.d0*dxdy4);

tmp_dx2=[1.d0 -2.d0 1.d0]/dx2;
tmp_dy2=[1.d0 -2.d0 1.d0]/dy2;
tmp_dxdy=[1.d0 -1.d0 -1.d0 1.d0]/dxdy4;

tic;
for i=2:NX %over OX
    for j=2:NY %over OY
         cux=[1.d0; 1.d0; 1.d0; C(i,j,1); C(i,j,4); C(i,j,2)];
       % Construct eta0 and eta1 arrays for each marked point
        if markers(i,j)>0
            pt0x=gr_x(i,j);
            pt0y=gr_y(i,j);
            ctr=0;
            for ik=1:-1:-1 %over columns of points from right to left
                for jk=1:-1:-1  %over rows of points from top to bottom
                        pt1x=gr_x(i+ik,j);
                        pt1y=gr_y(i,j+jk);
                        ctr=ctr+1;
                        x_trial=linspace(pt0x,pt1x,20);
                        y_trial=linspace(pt0y,pt1y,20);
    %                     plot(x_trial,y_trial); hold on;
                        [xi,yi]=curveintersect(x_trial,y_trial,xdscr, ydscr);
                        if ~isempty([xi,yi]) % check if there is an intersection
                            if size(xi,1)*size(xi,2)>1  %get rid of multiple intersections
                                xi=xi(1);
                                yi=yi(1);
                            end
                            delta_x=abs(pt1x-pt0x);
                            delta_y=abs(pt1y-pt0y);
                            if delta_x<eps || delta_y<eps
                                if delta_x<eps %vertical line
                                    arr_eta0y(i,j,ctr)=abs(yi-pt0y)/delta_y;
                                    arr_eta1y(i,j,ctr)=1.d0-arr_eta0y(i,j,ctr);
                                    arr_eta0x(i,j,ctr)=ZERO;
                                    arr_eta1x(i,j,ctr)=ZERO;                                    
                                end
                                if delta_y<eps %hoizontal line
                                    arr_eta0x(i,j,ctr)=abs(xi-pt0x)/delta_x;
                                    arr_eta1x(i,j,ctr)=1.d0-arr_eta0x(i,j,ctr);
                                    arr_eta0y(i,j,ctr)=ZERO;
                                    arr_eta1y(i,j,ctr)=ZERO;
                                end
                                if delta_x<eps && delta_y<eps %if single point
                                    arr_eta0y(i,j,ctr)=ZERO;
                                    arr_eta1y(i,j,ctr)=ZERO;
                                    arr_eta0x(i,j,ctr)=ZERO;
                                    arr_eta1x(i,j,ctr)=ZERO;
                                end
                            else %if evrything ok with deltas
                                    arr_eta0y(i,j,ctr)=abs((yi-pt0y)/delta_y);
                                    arr_eta1y(i,j,ctr)=1.d0-arr_eta0y(i,j,ctr);
                                    arr_eta0x(i,j,ctr)=abs((xi-pt0x)/delta_x);
                                    arr_eta1x(i,j,ctr)=1.d0-arr_eta0x(i,j,ctr);
                            end
                            
                            %Define normal in point
                            tmp=abs(xdscr-xi);
                            [cvalue,idx]=min(tmp);
                            if idx==1 
                                idx=2;
                            end
                            p1x=xdscr(idx-1); p2x=xi; p3x=xdscr(idx+1);
                            p1y=ydscr(idx-1); p2y=yi; p3y=ydscr(idx+1);
                            s12 = sqrt((p2x-p1x)^2+(p2y-p1y)^2);
                            s23 = sqrt((p3x-p2x)^2+(p3y-p2y)^2);
                            dxds = (s23^2*(p2x-p1x)+s12^2*(p3x-p2x))/(s12*s23*(s12+s23));
                            dyds = (s23^2*(p2y-p1y)+s12^2*(p3y-p2y))/(s12*s23*(s12+s23));
                            tvx=dxds;
                            tvy=dyds;
                            nvx=-dyds;
                            nvy=dxds;
                            if isnan(nvx)
                                nvx=0.d0;
                                nvy=0.d0;
                            end
                        else  % if there is no intersection
                                arr_eta1x(i,j,ctr)=1.d0*abs(ik);
                                arr_eta1y(i,j,ctr)=1.d0*abs(jk);
                                arr_eta0x(i,j,ctr)=abs(1.d0*ik)*abs((1.d0-arr_eta1x(i,j,ctr)));
                                arr_eta0y(i,j,ctr)=abs(1.d0*jk)*abs((1.d0-arr_eta1y(i,j,ctr)));
                                nvx=0.d0;
                                nvy=0.d0;
                        end   % checking if there are intersections
                        
                        %Apply Mizutani operators
                        eta0x = arr_eta0x(i,j,ctr);
                        eta1x = arr_eta1x(i,j,ctr);
                        eta0y = arr_eta0y(i,j,ctr);
                        eta1y = arr_eta1y(i,j,ctr);                    
 
                        [A0,B0,A1,B1] = A0B0A1B1triso2(i,j,ik,jk,0,0, nvx, nvy,C, rho, dx, dy, -ik*eta0x,ik*eta1x, -jk*eta0y, jk*eta1y, DEBUG_MODE);
                        CJI=svdinv(B0*A0)*(B1*A1);
                        coeffAux(ctr,:)=CJI(1,1:6);
                        coeffAuy(ctr,:)=CJI(7,7:12);

                        if DEBUG_MODE
                            %CHECK OUT PLOTS
                            subplot(231);
                            % Add central point as red circle
                            scatter(gr_x(i,j),gr_y(i,j),'filled','r'); hold on
                            scatter(gr_x(i+ik,j),gr_y(i,j+jk),'filled','b'); hold on
                            % Add line of Taylor expansion
                            line([gr_x(i,j) gr_x(i+ik,j)],[gr_y(i,j), gr_y(i,j+jk)]); hold on;
                            %Plot topography in cell
                            ind = find(xdscr(1,:)<gr_x(i+1,j) & xdscr(1,:)>gr_x(i-1,j));
                            plot(xdscr(ind), ydscr(ind),'k'); hold on;
                            
                            if ~isempty(xi)
                                fprintf('ik=%d jk=%d\n',ik,jk);
                                fprintf(' nvx=%d\n nvy=%f\n',nvx,nvy);
                                %Plot normal
                                line([xi xi+dx*nvx],[yi yi+dy*nvy],'Color','m'); hold on;
                                %Plot intersection point
                                scatter(gr_x(i,j)+ik*dx*eta0x,gr_y(i,j)+jk*dy*eta0y,'filled','g');
                            end
                            drawnow
                            
                            fprintf('ik=%d jk=%d eta0x=%.4f eta0y=%.4f',ik,jk,eta0x,eta0y); 
                            subplot(234);
                            pcolor(flipud(CJI));
                            colorbar();
                            title(['CJI i=' num2str(i) ' j=%s' num2str(j)]);
                            
                             CJI(1,1:6)./[1 dx dy dx2/2 dy2/2 dx*dy]
                             CJI(7,7:12)./[1 dx dy dx2/2 dy2/2 dx*dy]
                             
                             input('next?');
                            clf;
                            clc;
                        end
%        
                end      %end of jk loop
            end  %%end of ik loop
            pre_dx2=svdinv([coeffAux(2,[1,2,4]); coeffAux(5,[1,2,4]); coeffAux(8,[1,2,4])]);
            pre_dy2=svdinv([coeffAux(4,[1,3,5]); coeffAux(5,[1,3,5]); coeffAux(6,[1,3,5])]);
            pre_dxdy=svdinv([coeffAux(1,:); coeffAux(3,:); coeffAux(7,:); coeffAux(9,:)]);
            coeffux_dx2 = C(i,j,1)*pre_dx2(3,:);
            coeffux_dy2 = C(i,j,4)*pre_dy2(3,:);
            coeffux_dxdy= C(i,j,2)*pre_dxdy(6,:);
%             coeffux_dxdy= C(i,j,2)*[1.d0 -1.d0 -1.d0 1.d0]/dxdy4;
      
            pre_dx2=svdinv([coeffAuy(2,[1,2,4]); coeffAuy(5,[1,2,4]); coeffAuy(8,[1,2,4])]);
            pre_dy2=svdinv([coeffAuy(4,[1,3,5]); coeffAuy(5,[1,3,5]); coeffAuy(6,[1,3,5])]);
            pre_dxdy=svdinv([coeffAuy(1,:); coeffAuy(3,:); coeffAuy(7,:); coeffAuy(9,:)]);
            coeffuy_dx2 = C(i,j,4)*pre_dx2(3,:);
            coeffuy_dy2 = C(i,j,3)*pre_dy2(3,:);
            coeffuy_dxdy= C(i,j,4)*pre_dxdy(6,:);
%             coeffuy_dxdy= C(i,j,1)*[1.d0 -1.d0 -1.d0 1.d0]/dxdy4;
            
            coeffux{i,j}=[[coeffux_dx2 0]; [coeffux_dy2 0]; coeffux_dxdy];
            coeffuy{i,j}=[[coeffuy_dx2 0]; [coeffuy_dy2 0]; coeffuy_dxdy];
            
        end  %end of if markers(i,j)
        
        %if ani conditions were used use conventional operator
        if isempty(coeffux{i,j}) && isempty(coeffuy{i,j})
            %ux_dx2
            ml = C(i-1,j,1)+C(i,j,1);                  %left point 
            mr = C(i,j,1)+C(i+1,j,1);                  %right point
            mc = C(i-1,j,1) +2.d0*C(i,j,1)+C(i+1,j,1); %middle point
            coeffux_dx2 = one_over_2dx2*[ml -mc mr];
            %uy_dx2
            ml = C(i-1,j,4)+C(i,j,4);                  %left point 
            mr = C(i,j,4)+C(i+1,j,4);                  %right point
            mc = C(i-1,j,4) +2.d0*C(i,j,4)+C(i+1,j,4); %middle point
            coeffuy_dx2 = one_over_2dx2*[ml -mc mr];
            %ux_dy2
            ml = C(i,j-1,4)+C(i,j,4);                  %left point 
            mr = C(i,j,4)+C(i,j+1,4);                  %right point
            mc = C(i,j-1,4) +2.d0*C(i,j,4)+C(i,j+1,4); %middle point           
            coeffux_dy2 = one_over_2dy2*[ml -mc mr];
            %uy_dy2
            ml = C(i,j-1,3)+C(i,j,3);                  %left point 
            mr = C(i,j,3)+C(i,j+1,3);                  %right point
            mc = C(i,j-1,3) +2.d0*C(i,j,3)+C(i,j+1,3); %middle point  
            coeffuy_dy2 = one_over_2dy2*[ml -mc mr];
            
            %ux_dxdy
%             mp1p1 = C(i+1,j+1,2)+C(i,j,2);
%             mp1m1 = C(i+1,j-1,2)+C(i,j,2);
%             mm1p1 = C(i-1,j+1,2)+C(i,j,2);
%             mm1m1 = C(i-1,j-1,2)+C(i,j,2);
%             coeffux_dxdy= one_over_2dxdy4*[mp1p1 -mp1m1 -mm1p1 mm1m1];
            
            %uy_dxdy
%             mp1p1 = C(i+1,j+1,1)+C(i,j,1);
%             mp1m1 = C(i+1,j-1,1)+C(i,j,1);
%             mm1p1 = C(i-1,j+1,1)+C(i,j,1);
%             mm1m1 = C(i-1,j-1,1)+C(i,j,1);
%             coeffuy_dxdy= one_over_2dxdy4*[mp1p1 -mp1m1 -mm1p1 mm1m1];
            
%             coeffux_dx2 = C(i,j,1)*tmp_dx2;
%             coeffux_dy2 = C(i,j,4)*tmp_dy2;
            coeffux_dxdy= C(i,j,2)*tmp_dxdy;
      
%             coeffuy_dx2 = C(i,j,4)*tmp_dx2;
%             coeffuy_dy2 = C(i,j,3)*tmp_dy2;
            coeffuy_dxdy= C(i,j,4)*tmp_dxdy;
            
            coeffux{i,j}=[[coeffux_dx2 0]; [coeffux_dy2 0]; coeffux_dxdy];
            coeffuy{i,j}=[[coeffuy_dx2 0]; [coeffuy_dy2 0]; coeffuy_dxdy];
        end
        
    end % end of j loop
end  %end of i loop
fprintf('...OK\n')


fprintf('Check coeff{i,j} for explosions');
% tic;
mmAB=0;
for i=2:size(coeffux,1)-2
    for j=2:size(coeffux,2)-2
        A=max(max(coeffux{i,j}));
        B=max(max(coeffuy{i,j}));
        mAB=max(A,B);
        if mAB>mmAB
            mmAB=mAB;
        end
    end
end
if mmAB>100*max(cux)
    fprintf('...FAILED\n');
%     %break;
else
    fprintf('...OK\n');
    clearvars i j A B mAB mmAB;
%     toc;
end

toc;

%Clean up memory from temporary variables
clearvars coeffAux coeffAuy cux cuy tmp_coeff eta0x eta0y eta1x eta1y;
clearvars A0 B0 A1 B1 CJI ctr pt0x pt0y pt1x pt1y;
clearvars ik jk ii jj i j denom_for_tmp_coeff nvx nvy x_trial y_trial;
clearvars arr_eta0x arr_eta1x arr_eta0y arr_eta1y delta_x delta_y;
clearvars idx cvalue p1x p1y p2x p2y p3x p3y s12 s23 tmp tvx tvy
clearvars xi yi xdeb xfin ydeb yfin dxds dyds;
clearvars xoriginleft xoriginright nc;
clearvars cp cs cp_above_eb cp_below_eb density rho_below_eb rho_above_eb;
clearvars tmp_dx2 tmp_dy2 tmp_dxdy coeffux_dx2 coeffux_dy2 coeffux_dxdy;
clearvars coeffuy_dx2 coeffuy_dy2 coeffuy_dxdy;


fprintf('Used memory: %.2f mb\n', monitor_memory_whos);
input('\nPress Enter to start time loop ...');
%---------------------------------
%---  beginning of the time loop -----
%---------------------------------
for it = 1:NSTEP
    tic;
    ux(3,:,:)=ZERO;
    uy(3,:,:)=ZERO;
    for i = 2:NX
        for j = 2:NY
            rhov=rho(i,j);
            A_ux=coeffux{i,j};
            value_dux_dxx=A_ux(1,1:3)*[ux(2,i-1,j); ux(2,i,j); ux(2,i+1,j)];
            value_dux_dyy=A_ux(2,1:3)*[ux(2,i,j-1); ux(2,i,j); ux(2,i,j+1)];
            value_dux_dxy=A_ux(3,:)*[ux(2,i+1,j+1); ux(2,i+1,j-1); ux(2,i-1,j+1); ux(2,i-1,j-1)];
            
            A_uy=coeffuy{i,j};
            value_duy_dxx=A_uy(1,1:3)*[uy(2,i-1,j); uy(2,i,j); uy(2,i+1,j)];
            value_duy_dyy=A_uy(2,1:3)*[uy(2,i,j-1); uy(2,i,j); uy(2,i,j+1)];
            value_duy_dxy=A_uy(3,:)*[uy(2,i+1,j+1); uy(2,i+1,j-1); uy(2,i-1,j+1); uy(2,i-1,j-1)];
            
            value_dux_dyx=value_dux_dxy*C(i,j,4)/C(i,j,2);
            value_duy_dyx=value_duy_dxy*C(i,j,2)/C(i,j,4);
            
            dt2rho=(DELTAT^2.d0)/rhov;

%                 sigmas_ux= c11v * value_dux_dxx + c13v * value_duy_dyx + c44v * value_dux_dyy + c44v * value_duy_dxy;
%                 sigmas_uy= c44v * value_dux_dyx + c44v * value_duy_dxx + c13v * value_dux_dxy + c33v * value_duy_dyy;

            sigmas_ux= value_dux_dxx + value_duy_dyx + value_dux_dyy + value_duy_dxy;
            sigmas_uy= value_dux_dyx + value_duy_dxx + value_dux_dxy + value_duy_dyy;

            ux(3,i,j) = 2.d0 * ux(2,i,j) - ux(1,i,j) + sigmas_ux * dt2rho;
            uy(3,i,j) = 2.d0 * uy(2,i,j) - uy(1,i,j) + sigmas_uy * dt2rho;
                                                               
        end
    end
         
    % add the source (force vector located at a given grid point)
    a = pi*pi*f0*f0;
    t = double(it-1)*DELTAT;
    % Gaussian
     source_term = factor * exp(-a*(t-t0)^2);
     %source_term = factor * (t-t0);  
     % first derivative of a Gaussian
%       source_term =  -factor*2.d0*a*(t-t0)*exp(-a*(t-t0)^2);
    % Ricker source time function (second derivative of a Gaussian)
%      source_term = factor * (1.d0 - 2.d0*a*(t-t0)^2)*exp(-a*(t-t0)^2);

    force_x = sin(ANGLE_FORCE * DEGREES_TO_RADIANS) * source_term;
    force_y = cos(ANGLE_FORCE * DEGREES_TO_RADIANS) * source_term;
%       force_x=factor * (1.d0 - 2.d0*a*(t-t0)^2)*exp(-a*(t-t0)^2);
%       force_y=factor * (1.d0 - 2.d0*a*(t-t0)^2)*exp(-a*(t-t0)^2);

    % define location of the source
    i = ISOURCE;
    j = JSOURCE;

    ux(3,i,j) = ux(3,i,j) + force_x * DELTAT / rhov;
    uy(3,i,j) = uy(3,i,j) + force_y * DELTAT / rhov;
% 
%     ux(3,i,j) = force_x * DELTAT / rhov;
%     uy(3,i,j) = force_y * DELTAT / rhov;
    
    % Dirichlet conditions (rigid boundaries) on the edges or at the bottom of the PML layers
    ux(3,1,:) = ZERO;
    ux(3,NX+1,:) = ZERO;

    ux(3,:,1) = ZERO;
    ux(3,:,NY+1) = ZERO;

    uy(3,1,:) = ZERO;
    uy(3,NX+1,:) = ZERO;

    uy(3,:,1) = ZERO;
    uy(3,:,NY+1) = ZERO;

    % store seismograms
    if SAVE_SEISMOGRAMS
        for irec = 1:NREC
                seisux(it,irec) = ux(3,ix_rec(irec),iy_rec(irec));
                seisuy(it,irec) = uy(3,ix_rec(irec),iy_rec(irec));
        end   
    end
    
    %Set previous timesteps
    ux(1,:,:)=ux(2,:,:);
    ux(2,:,:)=ux(3,:,:);
    
    uy(1,:,:)=uy(2,:,:);
    uy(2,:,:)=uy(3,:,:);


    % compute total energy in the medium (without the PML layers)

    % compute kinetic energy first, defined as 1/2 rho ||v||^2
    % in principle we should use rho_half_x_half_y instead of rho for vy
    % in order to interpolate density at the right location in the staggered grid cell
    % but in a homogeneous medium we can safely ignore it
    
    %total_energy_kinetic(it) = 0.5d0 .*sum(rho((NPOINTS_PML+1):(NX-NPOINTS_PML),(NPOINTS_PML+1):(NY-NPOINTS_PML))*( ...
    %    vx((NPOINTS_PML+1):(NX-NPOINTS_PML),(NPOINTS_PML+1):(NY-NPOINTS_PML)).^2 +  ...
    %    vy((NPOINTS_PML+1):(NX-NPOINTS_PML),(NPOINTS_PML+1):(NY-NPOINTS_PML)).^2));

    % add potential energy, defined as 1/2 epsilon_ij sigma_ij
    % in principle we should interpolate the medium parameters at the right lo thencation
    % in the staggered grid cell but in a homogeneous medium we can safely ignore it
%     total_energy_potential(it) = ZERO;
%     for j = NPOINTS_PML+1: NY-NPOINTS_PML
%         for i = NPOINTS_PML+1: NX-NPOINTS_PML
%             epsilon_xx = ((lambda(i,j) + 2.d0*mu(i,j)) * sigmaxx(i,j) - lambda(i,j) * ...
%                 sigmayy(i,j)) / (4.d0 * mu(i,j) * (lambda(i,j) + mu(i,j)));
%             epsilon_yy = ((lambda(i,j) + 2.d0*mu(i,j)) * sigmayy(i,j) - lambda(i,j) * ...
%                 sigmaxx(i,j)) / (4.d0 * mu(i,j) * (lambda(i,j) + mu(i,j)));
%             epsilon_xy = sigmaxy(i,j) / (2.d0 * mu(i,j));
%             total_energy_potential(it) = total_energy_potential(it) + ...
%                 0.5d0 * (epsilon_xx * sigmaxx(i,j) .+ epsilon_yy * sigmayy(i,j) + 2.d0 * epsilon_xy * sigmaxy(i,j));
%         end
%     end
        % check stability of the code, exit if unstable
                % print maximum of norm of velocity
        velocnorm = max(sqrt(ux(3,:,:).^2 + uy(3,:,:).^2));
        if(velocnorm > STABILITY_THRESHOLD)
            %break 
            disp('code became unstable and blew up');
        end   
    % output information
    if(mod(it,IT_DISPLAY) == 0 || it == 5)
        fprintf('Time step: %d\n',it)
        fprintf('Time: %.2f seconds\n',single((it-1)*DELTAT));
        toc;

        %fprintf('Max norm velocity vector V (m/s) = %.2f\n',velocnorm);
        %     fprintf('total energy = ',total_energy_kinetic(it) + total_energy_potential(it)
        %     print * 
    
        if(SHOW_UX_WF || SHOW_UY_WF)
            clf;	%clear current frame
            if DISP_NORM
                u=sqrt(ux(3,:,:).^2+uy(3,:,:).^2);
            else
                if SHOW_UX_WF 
                    u=ux(3,:,:); 
                elseif SHOW_UY_WF
                    u=uy(3,:,:);
                end
            end
            %velnorm(ISOURCE-1:ISOURCE+1,JSOURCE-1:JSOURCE+1)=ZERO;
            imagesc(nx_vec,ny_vec,squeeze(u(1,:,:))'); hold on;
            title(['Step = ',num2str(it),' Time: ',num2str(single((it-1)*DELTAT)),' sec']); 
            xlabel('m');
            ylabel('m');
            set(gca,'YDir','normal');
            if FE_BOUNDARY
                plot(xdscr,ydscr,'m'); 
            end
            if COLORBAR_ON
                colorbar();
            end
            drawnow;  hold on;
            if SHOW_SOURCE_POSITION
                scatter(xsource, ysource,'g','filled'); drawnow;
            end
            
            if SHOW_REC_POSITION
                for i=1:NREC
                    scatter(xrec(i),yrec(i)); hold on;
                end
                drawnow;
            end
           
            if SNAPSHOT
                if  nnz(snapshot_time==it)>0
                    snapshat = getframe(gcf);
                    imgg = frame2im(snapshat);
                    scrsht_name=['im' num2str(it) '.png'];
                    imwrite(imgg,scrsht_name);
                    fprintf('Screenshot %s saved to %s\n', scrsht_name, pwd);
                    clearvars scrsht_name imgg snapshat
                end  
            end
            
            if MAKE_MOVIE
                F_y=getframe(gcf);  %-  capture figure or use gcf to get current figure. Or get current
                writeVideo(vidObj_mv,F_y);  %- add frame to the movie
                fprintf('Frame for %s captured\n',movie_name);
            end
            
            if DATA_TO_BINARY_FILE
                filename=[tag 'u_' 'disp_t_' num2str(it) '.txt'];
                dlmwrite(filename, u);
                fprintf('Data file %s saved to %s\n',filename, pwd);
            end
        end
        fprintf('\n'); 
        if it==3100
            input('Next?');
        end
    end
    if PAUSE_ON
        pause(pause_time);
    end
end
  % end of time loop

  
  current_folder=pwd;	%current path
  if MAKE_MOVIE
	  close(vidObj_mv);     %- close video file
      fprintf('Video %s saved in %s\n',movie_name, current_folder);
  end
 
    
 if SAVE_SEISMOGRAMS
      for i=1:NREC
          filename=[seis_tag 'ux' '4x' num2str((ix_rec(i)-1)*dx,'%.2f') 'y' num2str((iy_rec(i)-1)*dy,'%.2f') '_' num2str(i) '.txt'];
          dlmwrite(filename, [time_vec, seisux(:,i)]);
          fprintf('ux. Seismogram for rec at %.2f %.2f saved as %s to %s\n', (ix_rec(i)-1)*dx, (iy_rec(i)-1)*dy, filename, pwd);
          filename=[seis_tag 'uy' '4y' num2str((iy_rec(i)-1)*dy,'%.2f') 'x' num2str((ix_rec(i)-1)*dx,'%.2f') '_' num2str(i) '.txt'];
          dlmwrite(filename, [time_vec, seisuy(:,i)]);
          fprintf('uy. Seismogram for rec at %.2f %.2f saved as %s to %s\n', (ix_rec(i)-1)*dx, (iy_rec(i)-1)*dy, filename, pwd);
      end
 end
  
  disp('End');
 