% Lena J. Schwebs
% Last updated on: 08/26/2024
% Adapted from Dr. Niels Claes (University of Wyoming) and Dr. Michael Tso (Lancaster University)
 
% fLoc = inverted resistivity file (f00X_res.dat)
% mLoc = mesh file (mesh.dat)
function plot_res(mLoc)

%% This matlab script plots the _res.dat results with the unstructured grid of the survey area
[file, folder] = uigetfile('*_res.dat','*.*'); % select the file (res.dat file) (both the file name and folder will be saved)

cd(folder); % change the working directory to the folder with the file

%% open mesh-file (geometry that will be used to plot the results on)
% USE THE SURVEY AREA MESH NOT THE INVERSION MESH
mymesh = which(mLoc); 
fid = fopen(mymesh,'r'); 

%% count # of lines in the mesh-file
nlines  = 0;
while fgets(fid)~= -1
    nlines = nlines+1;
end
frewind(fid);

%% read mesh-file content linewise
data = cell(nlines,1);

for n = 1:nlines
    data{n} = fgetl(fid);
end

line1 = strsplit(data{1},' ');
num_triangles = str2double(line1(1));
num_points = str2double(line1(2));

%% define triangle element data and coordinate data
tridat = cell(num_triangles, 7);
for n = 2:(num_triangles + 1)
    tridat(n-1, :) = strsplit(data{n},' ');
end

pointdat = cell(num_points, 5);
for n = (num_triangles + 2):nlines
    pointdat(n-(num_triangles+1), :) = strsplit(data{n},' ');
end
pointdat = pointdat(:, 2:4);

%% write triangle file and point coordinate file out for further use
% triangle elements file
fileID = fopen('triangle_points.dat','w');
formatSpec = '%s %s %s %s %s %s \r\n';
for n = 1:num_triangles
    fprintf(fileID, formatSpec, tridat{n, 1}, tridat{n, 2}, tridat{n, 3}, ...
        tridat{n, 4}, tridat{n, 5}, tridat{n, 6});
end
fclose(fid);

% triangle point coordinate file
fileID = fopen('point_coo.dat','w');
formatSpec = '%10s %20s %20s \r\n';
for n = 1:num_points
    %string = strsplit(data{n, :});
    fprintf(fileID,formatSpec, pointdat{n, 1}, pointdat{n, 2}, pointdat{n, 3});
end
fclose(fid);

% create variables from new files
mesh = load('triangle_points.dat');
coordinates = load('point_coo.dat');

%% X and Y coordinates of the triangle corners
for i = 1:length(mesh)
    x = [coordinates(mesh(i, 2), 2); coordinates(mesh(i, 3), 2); coordinates(mesh(i, 4), 2)]; 
    y=[coordinates(mesh(i, 2), 3); coordinates(mesh(i, 3), 3); coordinates(mesh(i, 4), 3)];
    triangle(i).coo = [x, y];
end

%% load inverted resistivity data
result = load(strcat(folder, file));

%mask=load(strcat(folder,'f002_sen.dat'));

%%%% a mask that leaves out the areas that are unsensitive/non-sensical
%%%% reduces the risk of making overconfident or wrong interpretations
%%%% One can run a second inversion, starting with a different starting
%%%% model and use the method as desribed by Oldenburg and Li (1999) or one
%%%% can use the diagonal of the [Jt Wt W J] matrix as an estimate of
%%%% senstivity over the profile (set RES matrix in line 2 over the R.in
%%%% file to '1'). There are no clear defined boundaries between what
%%%% values constitute sensitive and what values are insensitive areas.
%%%% However, higher values are more sensitive areas. An example of a
%%%% comparison between both methods can be found in the appendix of
%%%% Parsekian et al. (2017). The user is encouraged to assess the depth of
%%%% sensitivity and develop a mask suited for the field conditions

%% plotting
figure(1);
vmin = 1;
vmax = 4;
subplot(2, 1, 1)
title('Title', 'FontSize', 12, 'FontWeight', 'bold')
colormap('jet')
caxis([vmin vmax]); % the colorbar range of resistivity values 
axis([-1 128 -5 3]); % min and max values for the x coordinates and y coordinates

%%%% The patch command draws triangles with the color of the triangles
%%%% scaled within the caxis values, if the values lie outside the range,
%%%% the color assinged to the triangle will be equal to the minimum or
%%%% maximum value in the caxis.
%%%% The patch command requires: x-coordinates of the corners,
%%%% y-coordinates of the corners, the value assigned (res-value) to the
%%%% triangle, CDataMapping is the command that will scale the values and
%%%% assign it a color to the caxis range on the colormap, EdgeColor is set
%%%% to none, otherwise you get a black edge on each triangle (Very messy
%%%% if you have +10000 triangles, and FaceAlpha is a method to set the
%%%% transparency of the triangle 1.0 is no transparency, 0.00 is fully
%%%% transparent

for i = 1:length(result)
    patch(triangle(i).coo(:,1), triangle(i).coo(:,2), result(i,4), 'CDataMapping', 'scaled', 'EdgeColor', 'None', 'FaceAlpha', 1.0) 
    %{
    if mask(i,4)>-1
        patch(triangle(i).coo(:,1),triangle(i).coo(:,2),result(i,4),'CDataMapping','scaled','EdgeColor','None','FaceAlpha',1.0) %% 
    elseif (mask(i,4)>-2 && mask(i,4)<=-1)
        patch(triangle(i).coo(:,1),triangle(i).coo(:,2),result(i,4),'CDataMapping','scaled','EdgeColor','None','FaceAlpha',0.4)
    else
        patch(triangle(i).coo(:,1),triangle(i).coo(:,2),result(i,4),'CDataMapping','scaled','EdgeColor','None','FaceAlpha',0.05)
    end
    %}
end

%%%% second subplot plots the colorbar
subplot(2,1,2)
colormap('jet')
caxis([vmin vmax]);
axis off
colorbar('north');

%{
%%%% saving the figure in a user specified folder
figuredirectory=uigetdir(folder,'Choose the folder to save your figure');
cd(figuredirectory);
%%%% user specified name
prompt = 'Provide a name for the figure (letters and numbers are accepted)';
str = input(prompt,'s');
if isempty(str)
    str='Inverted Resistivity';
end

saveas(gcf,str,'png');
%}

end


