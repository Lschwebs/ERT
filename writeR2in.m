% Lena J. Schwebs
% Created on: 06/06/2024
% Last updated: 07/07/2024
% Adapted from Dr. Andrew D. Parsekian 'writeR2in.m'
% write R2.in for triangular mesh (will NOT work for quad mesh)
% line # comments correspond to line # described in R2 v4.11 user guide 

function writeR2inLS(startRes, numel, reg_mode, alpha_s, num_electrodes)

%% inversion settings
job_type = 1; % 0 = forward, 1 = inverse
mesh_type = 3; % 3 = triangular, 4 = regular quadrilateral, 5 = generalised structured quad, 6 = general quad
flux_type = 3.0; % 2.0 = 2D, 3.0 = 3D
singular_type = 0; % singularity removal: 0 = no (only for flat surface), 1 = yes
res_matrix = 1; % 0 = none, 1 = sensitivity matrix, 2 = resolution matrix, 3 = sensitivity map (Jacobian and roughness matrix)
scale = 1; % mesh scale, leave at 1 to maintain coordinates in mesh.dat
num_regions = 1; % number of regions for starting model

inverse_type = 1; 
    % 0 = pseudo-Marquardt solution
    % 1 = regularised solution w linear filter (usual mode)
    % 2 = reg type w quadratic filter
    % 3 = qualitative solution   
target_decrease = 0.0; % 0.0 = achieve max reduction in misfit
data_type = 1; % 0 = normal data, 1 = log-transform data

% reg_mode = function input; 
    % 0 = normal regularization 
    % 1 = regularize relative to starting resistivity (startRes) requires alpha_s 
    % 2 = time-lapse mode: requires extra column in protocol.dat and starting model = inverse model of reference dataset

% alpha_s = function input; 
    % set alpha_s high (e.g. 10) to highly penalize a departure from the starting model
    % if alpha_s is too high, R2 may not converge
    % printed as "Alpha" in R2.out

tolerance = 1; % RMS tolerance for terminating iterations (desired misfit)
max_iter = 10; % maximum number of iterations
error_mod = 2; % 2 recommended for updating data weights
alpha_aniso = 1; % anisotropy of the smoothing factor
    % alphaaniso > 1 for smoother horizontal models
    % alphaaniso = 1 for isotropic smoothing
    % alphaaniso < 1 for smoother vertical models

a_wgt = 0.0;
b_wgt = 0.0;
    % default a_wgt = 0.01 Ohms and b_wgt = 0.02 Ohms
    % setting to 0.0 requires extra column in protocal.dat... 
    % for individual errors for each measurement

rho_min = 0; 
rho_max =  100000;

num_xy_poly = 0; % 0 = no bounding in the x-y plane
elecs = linspace(1, num_electrodes, num_electrodes)';
elecs = [elecs elecs]; % electrode, node

%% assemble R2.in
line1 = sprintf('Inverse model'); % line1: header
line2 = sprintf('%1.0f %1.0f %1.1f %1.0f %1.0f', job_type, mesh_type, flux_type, singular_type, res_matrix); % line2
line10 = scale; % line10: this ONLY applies for mesh_type = 3 
line11 = num_regions; % line11
line13 = [1 numel startRes]; % line13
line18 = [inverse_type target_decrease]; % line18
line21 = [data_type reg_mode]; % line21

if reg_mode == 1
    line22 = [tolerance max_iter error_mod alpha_aniso alpha_s]; % line22: use if regmode = 1
else
    line22 = [tolerance max_iter error_mod alpha_aniso]; % line22: use if regmode = 0 or 2
end

line23 = [a_wgt b_wgt rho_min rho_max]; % line23
line25 = num_xy_poly; % line25
line27 = num_electrodes; % line27
line28 = elecs; % line28

%% write R2.in
newfile = [pwd '\R2.in'];

dlmwrite(newfile, line1, '')
dlmwrite(newfile, line2, '-append', 'delimiter', '')
dlmwrite(newfile, line10, '-append', 'delimiter', ' ')
dlmwrite(newfile, line11, '-append', 'delimiter', ' ')
dlmwrite(newfile, line13, '-append', 'delimiter', ' ')
dlmwrite(newfile, line18, '-append', 'delimiter', ' ')
dlmwrite(newfile, line21, '-append', 'delimiter', ' ')
dlmwrite(newfile, line22, '-append', 'delimiter', ' ')
dlmwrite(newfile, line23, '-append', 'delimiter', ' ')
dlmwrite(newfile, line25, '-append', 'delimiter', ' ')
dlmwrite(newfile, line27, '-append', 'delimiter', ' ')
dlmwrite(newfile, line28, '-append', 'delimiter', ' ')

clear newfile;

fprintf('R2.in written\n')

end

