%                             Transverse isotropic case
%           Operators splitted for dx2 dy2 dxdy

close all;  %close all extra windows
clc;        %clear console
clear all;  %clear all variables

% total number of grid points in each direction of the grid
 mg= 2;
 NX =100*mg;  %X
 NY =100*mg;  %Y
 
%  time=0.02d0;
  time=0.6d0;
 
 % time step in seconds
 DELTAT = 0.1d-2;	%[sec] 
%  DELTAT = DELTAT/mg;
 % total number of time steps
 %  NSTEP = 2000;
 NSTEP = round(time/DELTAT);
 time_vec = [1:NSTEP]'*DELTAT;

YMAX=2000.d0; %[m]
XMAX=2000.d0; %[m]

XMIN=0.d0;
YMIN=0.d0;

DELTAX=(XMAX-XMIN)/NX; %[m]
DELTAY=(YMAX-YMIN)/NY; %[m]

Cerj_thick = floor(0.15*NX);
Cerjan_rate = 0.015*15/Cerj_thick;
%--------------------------------------------------------------------------
%---------------------- FLAGS ---------------------------------------------
% total number of time steps
% NSTEP = 350;
% NSTEP=2000;
% display information on the screen from time to time
IT_DISPLAY = 20;

%Take instant snapshot
SNAPSHOT=false;
snapshot_time=50:25:NSTEP; %on what steps

%Show source position on the graph?
SHOW_SOURCE_POSITION=true;

% To show or don't show wavefield 
SAVE_VX_JPG =false; %doesn't work, because I didn't pay attention to it yet
SAVE_VY_JPG =true;

%Record video - corresponding SAVE_VX or VY must be turned on
%because video is being created by capturing of the current frame
%Matlab 2012 + required, saves video to a current folder
MAKE_MOVIE_VX=false;
MAKE_MOVIE_VY=false;
tagv='video';


DISP_NORM=true;    %show normal displacement

DATA_TO_BINARY_FILE=true;  %save data to .txt files
tag='3int_f12_A0B0ch';

SAVE_SEISMOGRAMS=false;
seis_tag=['mzcurvetriso2D' num2str(NX)];

RED_BLUE=false;      %use custom red-blue only colormap
PLOT_INTERFACES = true;
eps=0.00000000001d0;

%------------------------------------------------------------------
%Check if it is possible to save video
if MAKE_MOVIE_VY && ~SAVE_VY_JPG
    disp('Error. It is necesary to have SAVE_VY_JPG=true.');
    MAKE_MOVIE_VY=false;
end
if MAKE_MOVIE_VX && ~SAVE_VX_JPG
    disp('Error. It is necesary to have SAVE_VX_JPGquasi_cp_max=true.');
    MAKE_MOVIE_VX=false;
end

%vectors for visualisation using imagesec
nx_vec=[0:NX]*DELTAX;	%[m]
ny_vec=[0:NY]*DELTAY;


% P-velocity, S-velocity and density
% cp = 3300.d0;	%[km/s]
% cs = cp / 1.732d0;	%[km/s]
% density = 2800.d0;	%[kg/m3]

% parameters for the source
f0 = 12.d0;
t0 = 1.20d0 / f0;
factor = 1.d10;

% source
ANGLE_FORCE = 90.d0;

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


xsource=round(NX/2)*DELTAX;
% ysource=round(0.85*NY)*DELTAY;
ysource=round(0.7*NY)*DELTAY;

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
xsource=ISOURCE*DELTAX;
ysource=JSOURCE*DELTAY;


%Initiate video object for vx
if MAKE_MOVIE_VX
    movie_name_vx=[tagv '_vx_' num2str(NX) '_' num2str(NY) '_' num2str(DELTAX) '_' num2str(f0) '.avi'];
    vidObj_vx=VideoWriter(movie_name_vx);
    open(vidObj_vx);
end

%Initiate video object for vy
if MAKE_MOVIE_VY
    movie_name_vy=[tagv '_vy_' num2str(NX) '_' num2str(NY) '_' num2str(DELTAX) '_' num2str(f0) '.avi'];
    vidObj_vy=VideoWriter(movie_name_vy);
    open(vidObj_vy);
end

 
 %----------------------------------------
 %--- program starts here ----------------
 %----------------------------------------

fprintf('2D elastic finite-difference code in displacement formulation with C-PML\n\n');
fprintf('NX = %d  ',NX);
fprintf('NY = %d  ',NY);
fprintf('%d in total\n',NX*NY);
fprintf(' dx = %f  dy=%f  dt=%e\n',DELTAX,DELTAY,DELTAT);
fprintf('Size of the model: %.2f m x ',NX*DELTAX);
fprintf('%.2f\n',NY*DELTAY);
fprintf('\n');

if SAVE_SEISMOGRAMS
    fprintf('ON. Save seismograms\n');
    NREC=41;
    fprintf('Set %d recievers:\n',NREC);
    ydeb=0.2d0*YMAX;
    yfin=0.8d0*YMAX;
    xdeb=xsource;
    xfin=xsource;
    fprintf('  x0=%.2f  x1=%.2f\n  y0=%.2f  y1=%.2f\n', xdeb,xfin,ydeb,yfin);

    % for receivers
    ix_rec=zeros(NREC,1);
    iy_rec=zeros(NREC,1);
    xrec=zeros(NREC,1);
    yrec=zeros(NREC,1); 

    % for seismograms
    seisux=zeros(NSTEP,NREC);
    seisuy=zeros(NSTEP,NREC);

    xspacerec = (xfin-xdeb) / double(NREC-1);
    yspacerec = (yfin-ydeb) / double(NREC-1);
    for irec=1:NREC
         xrec(irec) = xdeb + double(irec-1)*xspacerec;
         yrec(irec) = ydeb + double(irec-1)*yspacerec;
    end
    NREC=length(xrec);
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
    fprintf('Source position:  '); % print position of the source
    fprintf('x = %.2f  ',xsource);
    fprintf('y = %.2f\n',ysource);
    fprintf('%d files will be saved to %s',2*NREC,pwd)
    fprintf('\n ...OK\n');
end


%--------------------------------------------------------------------------

 if RED_BLUE
      fprintf('Set custom colormap');
      CMAP = make_red_blue_colormap();
      colormap(CMAP);
     fprintf('...OK\n');   
 end
  
  
fprintf('Cartesian grid generation');
gr_x=zeros(NX+1,NY+1);  %grid point coordinates in physical domain
gr_y=zeros(NX+1,NY+1);

for i=1:NX+1
    for j=1:NY+1
        gr_x(i,j)=(i-1)*DELTAX;
        gr_y(i,j)=(j-1)*DELTAY;    
    end    
end         %calculate cartesian grid points
fprintf('...OK\n');

%------------------------------------------------------------------------
%     CREATE VELOCITY MODEL
%------------------------------------------------------------------------
%elastic parameters
rho = zeros(NX+1,NY+1);
C = zeros(NX+1,NY+1,4);
nice_matrix = zeros(NX+1,NY+1);

% fprintf('Create velocity model ');
tic;
[model_cp, model_cs, model_rho, interface_list] = make_vel_model3(NX+1, NY+1, XMAX, XMIN, YMAX, YMIN);
% fprintf('...OK\n');
% fprintf('\n');
toc;

number_of_interfaces = length(interface_list);

% Put markers at nodes near the interfaces
markers = find_modified_nodes(NX,NY,gr_x,gr_y ,interface_list);

% Elastic moduli array
fprintf('\nCreate C 6D %d elements. ',NX*NY*4);
for i = 1:NX+1
    for j = 1:NY+1
        rhov = model_rho(i,j);
        cpv = model_cp(i,j);
        csv = model_cs(i,j);
        
        lambda =rhov*(cpv*cpv - 2.d0*csv*csv);
        mu = rhov*csv*csv;  
        
        % isotropic material
        c11v = (lambda + 2.d0*mu);
        c13v = lambda;
        c33v = c11v;
        c44v = mu;
        
        % if in liquid
        if csv < eps
            nice_matrix(i,j) = 1;
            c44v = c11v;
            c33v = c11v;
        end
        
        rho(i,j) = model_rho(i,j);
        C(i,j,:)=[c11v c13v c33v c44v];
    end
end
fprintf('C(i,j,4) of size: %s  ...OK\n',num2str(size(C)));
fprintf('\n');

% Check anisotropic material stability
check_material_stability(C);

% Check Courant stability condition
check_CFL(max(max(model_cp)), DELTAT, DELTAX, DELTAY);

% Check number of nodes per wavelength, ~ 10 is recommended
check_nodes_per_wavelength(min(min(model_cp)), f0, DELTAX, DELTAY);

%------------------------------------------------------------------------
%     CONSTRUCT OPERATORS
%------------------------------------------------------------------------
fprintf('Constructing coeff{i,j}...');
coeffux=cell(NX,NY);
coeffuy=cell(NX,NY);

tic;
% Construct modified and conventional operators

for i=2:NX %over OX
    for j=2:NY %over OY

        if markers(i,j)>0        % construct modified operators
            num_of_interface = markers(i,j);
            xdscr = interface_list{num_of_interface,1};
            ydscr = interface_list{num_of_interface,2};
            
%             try
            [Aux, Auy] = construct_interface_operators(i,j, gr_x, gr_y, xdscr, ydscr, C, rho);   
%             catch
%                 fprintf('%d %d %d INSTABILITY\n', num_of_interface,i, j);
%             end
            
            Aux(1,:) = C(i,j,1)*Aux(1,:);
            Aux(2,:) = C(i,j,4)*Aux(2,:);
            Aux(3,:) = C(i,j,2)*Aux(3,:);
            Aux(4,:) = C(i,j,4)*Aux(4,:);
            
            Auy(1,:) = C(i,j,4)*Auy(1,:);
            Auy(2,:) = C(i,j,3)*Auy(2,:);
            Auy(3,:) = C(i,j,4)*Auy(3,:);
            Auy(4,:) = C(i,j,2)*Auy(4,:);
            
            [Aux, Auy] = check_if_conventional_rows(Aux, Auy, i, j, C, DELTAX, DELTAY);
            
            coeffux{i,j}=Aux;
            coeffuy{i,j}=Auy;
        end
        
        
        %if any conditions were used - use conventional heterogeneous operator
        if isempty(coeffux{i,j}) && isempty(coeffuy{i,j})
            [Aux, Auy] = construct_Zahradnik_operators(i,j,C, DELTAX, DELTAY);
            coeffux{i,j} = Aux;
            coeffuy{i,j} = Auy;
        end    
        
    end
end
fprintf('OK\n')

% Check stability of constructed operators
fprintf('Check coeff{i,j} for explosions');
mmAB=0;
for i=2:size(coeffux,1)-2
    for j=2:size(coeffux,2)-2
        cux=[C(i,j,1); C(i,j,4); C(i,j,2)];
        cuy=[C(i,j,4); C(i,j,3); C(i,j,2)];
        A=max(max(coeffux{i,j}));
        B=max(max(coeffuy{i,j}));
        mAB=max(A,B);
        if mAB>mmAB
            mmAB=mAB;
        end
    end
end
if mmAB>100*max(cux) || mmAB>100*max(cuy)
    fprintf('...FAILED\n');
else
    fprintf('...OK\n');
end
toc;

%Clean up memory from temporary variables
clearvars Aux Auy xdscr ydscr;
clearvars xdeb xfin ydeb yfin;
clearvars cux cuy i j A B mAB mmAB;

fprintf('Used memory: %.2f mb\n', monitor_memory_whos);
input('\nPress Enter to start time loop ...');

% main arrays
  ux=zeros(3,NX+1,NY+1);
  uy=zeros(3,NX+1,NY+1);
  
% initialize arrays
  ux(:,:,:) = ZERO;
  uy(:,:,:) = ZERO;

% initialize seismograms
  seisux(:,:) = ZERO;
  seisuy(:,:) = ZERO;
  
%------------------------------------------------------------------------
%     TIME LOOP
%------------------------------------------------------------------------
for it = 1:NSTEP   
    % calculate next step
    tic;
%     [ux, uy] = solver_mx_VTI_elastic(ux, uy, DELTAT, coeffux, coeffuy, rho, C);
%     [ux, uy] = solver_mx_acoustic(ux, uy, DELTAT, coeffux, coeffuy, rho);

    ux(3,:,:)=0.d0;
    uy(3,:,:)=0.d0;
    
    for i = 2:NX
        for j = 2:NY          
            rhov=rho(i,j);
            A_ux=coeffux{i,j};
            value_dux_dxx=A_ux(1,1:3)*[ux(2,i-1,j); ux(2,i,j); ux(2,i+1,j)];
            value_dux_dyy=A_ux(2,1:3)*[ux(2,i,j-1); ux(2,i,j); ux(2,i,j+1)];
            value_dux_dxy=A_ux(3,:)*[ux(2,i+1,j+1); ux(2,i+1,j-1); ux(2,i-1,j+1); ux(2,i-1,j-1)];
            value_dux_dyx=A_ux(4,:)*[ux(2,i+1,j+1); ux(2,i+1,j-1); ux(2,i-1,j+1); ux(2,i-1,j-1)];
            
            A_uy=coeffuy{i,j};
            value_duy_dxx=A_uy(1,1:3)*[uy(2,i-1,j); uy(2,i,j); uy(2,i+1,j)];
            value_duy_dyy=A_uy(2,1:3)*[uy(2,i,j-1); uy(2,i,j); uy(2,i,j+1)];
            value_duy_dxy=A_uy(3,:)*[uy(2,i+1,j+1); uy(2,i+1,j-1); uy(2,i-1,j+1); uy(2,i-1,j-1)];
            value_duy_dyx=A_uy(4,:)*[uy(2,i+1,j+1); uy(2,i+1,j-1); uy(2,i-1,j+1); uy(2,i-1,j-1)];

            %--------------------------------------------------------------------------------------------------------------------
            
            dt2rho=(DELTAT^2.d0)/rhov;
% 
%           sigmas_ux= c11v * value_dux_dxx + c13v * value_duy_dyx + c44v * value_dux_dyy + c44v * value_duy_dxy;
%           sigmas_uy= c44v * value_dux_dyx + c44v * value_duy_dxx + c13v * value_dux_dxy + c33v * value_duy_dyy;
            
            if nice_matrix(i,j)
                sigmas_ux = value_dux_dxx + value_dux_dyy;
                sigmas_uy = value_duy_dxx + value_duy_dyy;
            else
                sigmas_ux = value_dux_dxx + value_duy_dyx + value_dux_dyy + value_duy_dxy;
                sigmas_uy = value_dux_dyx + value_duy_dxx + value_dux_dxy + value_duy_dyy;
            end

            ux(3,i,j) = 2.d0 * ux(2,i,j) - ux(1,i,j) + sigmas_ux * dt2rho;
            uy(3,i,j) = 2.d0 * uy(2,i,j) - uy(1,i,j) + sigmas_uy * dt2rho;
        end
    end

    % Add volumetric force source term
    t = double(it-1)*DELTAT;
    [force_x, force_y] = source_function(f0, t0, factor, ANGLE_FORCE, t);
    i = ISOURCE;
    j = JSOURCE;
    rhov = rho(i,j);
    ux(3,i,j) = ux(3,i,j) + force_x * DELTAT^2.d0 / rhov;
    uy(3,i,j) = uy(3,i,j) + force_y * DELTAT^2.d0 / rhov;
    
    
    % Dirichlet conditions (rigid boundaries) on the edges
    ux(3,1,:) = ZERO;       % OX left and right
    ux(3,NX+1,:) = ZERO;

    ux(3,:,1) = ZERO;       % OX up and down
    ux(3,:,NY+1) = ZERO;

    uy(3,1,:) = ZERO;       % OY left and right
    uy(3,NX+1,:) = ZERO;

    uy(3,:,1) = ZERO;       % OY up and down
    uy(3,:,NY+1) = ZERO;

    % store seismograms
    if SAVE_SEISMOGRAMS
        for irec = 1:NREC
                seisux(it,irec) = ux(3,ix_rec(irec),iy_rec(irec));
                seisuy(it,irec) = uy(3,ix_rec(irec),iy_rec(irec));
        end   
    end

    % Implement exponential absorbing Cerjan boundary conditions
    [ux, uy] = Cerjan_absorbing_BC(ux, uy, Cerjan_rate, [Cerj_thick Cerj_thick], [Cerj_thick Cerj_thick]);
    
    %Set previous timesteps
    ux(1,:,:)=ux(2,:,:);
    ux(2,:,:)=ux(3,:,:);
    
    uy(1,:,:)=uy(2,:,:);
    uy(2,:,:)=uy(3,:,:);

    
    
    % output information
    if(mod(it,IT_DISPLAY) == 0 || it == 5)
        fprintf('Time step: %d\n',it)
        fprintf('Time: %.4f sec\n',single((it-1)*DELTAT));
        toc;
    
        if(SAVE_VX_JPG || SAVE_VY_JPG)
            clf;	%clear current frame
            if DISP_NORM
                u=sqrt(ux(3,:,:).^2+uy(3,:,:).^2);
            elseif SAVE_VX_JPG 
                u=ux(3,:,:); 
            elseif SAVE_VY_JPG
                u=uy(3,:,:);
            end
            u = squeeze(u(1,:,:))';
            timee = single((it-1)*DELTAT);
            ptitle = ['Step = ',num2str(it),' Time: ',sprintf('%.4f',timee),' sec']; 
            imagescc(nx_vec, ny_vec, u, ptitle,'m','m', 1);
            
            if PLOT_INTERFACES
                for int_cnt = 1:number_of_interfaces
                    x_interf = interface_list{int_cnt,1};
                    z_interf = interface_list{int_cnt,2};
                    plot(x_interf,z_interf,'Color','white','LineWidth',2); hold on;
                end
            end

            if SHOW_SOURCE_POSITION
                scatter(xsource, ysource,'g','filled'); hold on;
            end
            
            drawnow;
            
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
            
            if MAKE_MOVIE_VY
                F_y=getframe(gcf);  %-  capture figure or use gcf to get current figure. Or get current
                writeVideo(vidObj_vy,F_y);  %- add frame to the movie
                fprintf('Frame for %s captured\n',movie_name_vy);
            end
            
            if DATA_TO_BINARY_FILE
                filename=[tag 'u_' num2str(it) '.mat'];
%                 dlmwrite(filename, u);
                save(filename, 'u', 'timee','f0','factor', 'DELTAT','DELTAX','DELTAY','NX','NY','XMAX','YMAX','interface_list');
                fprintf('Data file %s saved to %s\n',filename, pwd);
            end
        end
        fprintf('\n'); 
    end
end
  % end of time loop

  
  current_folder = pwd;     %current path
  if MAKE_MOVIE_VX
	  close(vidObj_vx);     %- close video file
      printf('Video %s saved in %s\n',movie_name_vx,current_folder);
  end
  
  if MAKE_MOVIE_VY
	  close(vidObj_vy);     %- close video file
      fprintf('Video %s saved in %s\n',movie_name_vy, current_folder);
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
 