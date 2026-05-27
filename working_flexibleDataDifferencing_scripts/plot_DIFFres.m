% Lena J. Schwebs
% Last updated on: 10/01/2024
% Adapted from Dr. Niels Claes (University of Wyoming) and Dr. Michael Tso (Lancaster University)
 
% fLoc = inverted resistivity file (f00X_res.dat)
% mLoc = mesh file (mesh.dat)
function plot_DIFFres

%% This matlab script plots the _res.dat results with the unstructured grid of the survey area
%[files, folder] = uigetfile('*_diffres.dat','*.*'); % select the file (res.dat file) (both the file name and folder will be saved)
files = dir(fullfile('results/', '*_diffres.dat')); % find files
filesRes = dir(fullfile('GGData/', '*.tx0')); % find files
%cd(folder); % change the working directory to the folder with the file

%% open mesh-file (geometry that will be used to plot the results on)
% USE THE SURVEY AREA MESH NOT THE INVERSION MESH
mymesh = which('\mesh.dat'); 
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
tridat = cell(num_triangles, 6);
for n = 2:(num_triangles + 1)
    tridat(n-1, :) = strsplit(data{n},' ');
end

pointdat = cell(num_points, 4);
for n = (num_triangles + 2):nlines
    pointdat(n-(num_triangles+1), :) = strsplit(data{n},' ');
end
%%
pointdat = pointdat(:, 2:3);

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
formatSpec = '%20s %20s \r\n';
for n = 1:num_points
    %string = strsplit(data{n, :});
    fprintf(fileID,formatSpec, pointdat{n, 1}, pointdat{n, 2});
end
fclose(fid);

% create variables from new files
mesh = load('triangle_points.dat');
coordinates = load('point_coo.dat');

%% X and Y coordinates of the triangle corners
for i = 1:length(mesh)
    x = [coordinates(mesh(i, 2), 1); coordinates(mesh(i, 3), 1); coordinates(mesh(i, 4), 1)]; 
    y = [coordinates(mesh(i, 2), 2); coordinates(mesh(i, 3), 2); coordinates(mesh(i, 4), 2)];
    triangle(i).coo = [x, y];
end

for j = 1:length(files)
    %% load inverted resistivity data
    result = load(files(j).name);
    
    %% plotting
    figure(j);
    vmin = 2;
    vmax = 4;
    cmap = 'turbo';
    
    % seismic.mat is red blue colormap for difference plots
    seismic = load('seismic5.mat');
    %pmap = seismic.seismic5;
    pmap = flipud(spectral);
    cl = -50; % lower clim for percent change
    ch = 50; % higher clim for percent change
    
    subplot(2, 1, 1)
    hold on
    set(gca, 'FontName', 'Calibri', 'YDir','normal')
    fontsize(gca, 16, 'points')
 
    titleStr = strsplit(filesRes(j+1).name, {'_', '.'});
    title(titleStr(1), 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'none')
    xlabel('Distance (m)', 'FontSize', 16)
    ylabel('Depth (m)', 'FontSize', 16)
    
    colormap(pmap)
    caxis([cl ch]); % the colorbar range of resistivity values 
    axis([0 63 -6 12]); % min and max values for the x coordinates and y coordinates
    
    for i = 1:length(result)
        patch(triangle(i).coo(:,1), triangle(i).coo(:,2), result(i,3), 'CDataMapping', 'scaled', 'EdgeColor', 'None', 'FaceAlpha', 1.0) 
    end

    fillout([0 0 63 63], [0 -6 7 12],[0 64 -6 15], [1 1 1])
    hold off
    
    set(gca, 'Layer', 'top')

    %%%% second subplot plots the colorbar
    subplot(2,1,2)
    set(gca, 'FontName', 'Calibri', 'YDir','normal')
    fontsize(gca, 16, 'points')
    
    colormap(pmap)
    caxis([cl ch]);
    axis off
    cb = colorbar('north');
    %ylabel(cb,'log10(Resistivity)','FontSize',16)
    ylabel(cb,'\Delta Resistivity (%)','FontSize',16)

    fstr = split(filesRes(j+1).name, '_');
    figName = strcat('diffResPlots\', fstr(1), '_diffRes.png');
    display(figName)
    saveas(figure(j), figName{1});

    close(figure(j))
end