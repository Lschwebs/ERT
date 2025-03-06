% Lena J. Schwebs
% Created on: 08/27/2024
% Last Updated: 09/24/2024

% Create new mesh.dat file based on number of resistivity
% values in f001_res.dat for time-lapse inversion in ResIPy

% You need 3 files from ResIPy:
% 1. f001_res_ref.dat or Start_res.dat for file with ALL mesh elements
% 2. f001_res.dat for file with CROPPED mesh elements
% 3. mesh.dat file saved from ResIPy to edit

clear all; close all; clc;

%% load files
ref = load("f001_res_ref.dat"); % resistivity for ALL mesh elements
dat = load("f002_res.dat"); % resistivity for CROPPED mesh elements

ref_xz = [ref(:, 1) ref(:, 2)]; % load x z values
dat_xz = [dat(:, 1) dat(:, 2)]; % load x z values

%% find intersection
[N, ir, id] = intersect(ref_xz, dat_xz, 'rows'); % determine overlapping x z values
ir = sort(ir); % intersecting indices in ref file
id = sort(id); % intersecting indices in data file

%% load original mesh file
mymesh = which('mesh.dat');
fid = fopen(mymesh,'r');

%% count # lines in mesh file
nlines  = 0;

while fgets(fid) ~= -1
    nlines = nlines + 1;
end

frewind(fid);

%% read mesh file content linewise
data = cell(nlines, 1);

for n = 1:nlines
    data{n} = fgetl(fid);
end

line1 = strsplit(data{1}, ' ');
num_triangles = str2double(line1(1)); % number of triangle elements in mesh file
num_points = str2double(line1(2)); % number of coordinate points in mesh file

%% separate elements and coordinates
tridat = cell(num_triangles, 6); % triangle element data
for n = 2:(num_triangles + 1)
    tridat(n-1, :) = strsplit(data{n}, ' ');
end

pointdat = cell(num_points, 4); % triangle coordinate data
for n = (num_triangles + 2):nlines
    pointdat(n-(num_triangles+1), :) = strsplit(data{n}, ' ');
end

%% create new array of mesh elements
triNew = tridat(ir, :); % triangle elements in CROPPED mesh

%% write new mesh file
fileID = fopen('meshNew.dat','w');

formatSpec='%d %d %d \r\n';
fprintf(fileID, formatSpec, length(ir), num_points, 1);

formatSpec='%s %s %s %s %s %s \r\n';
for n = 1:length(ir)
    fprintf(fileID, formatSpec, triNew{n, 1}, triNew{n, 2}, triNew{n, 3}, triNew{n, 4}, triNew{n, 5}, triNew{n, 6});
end

formatSpec='%10s %20s %20s \r\n';
for n = 1:num_points
    fprintf(fileID,formatSpec, pointdat{n, 1}, pointdat{n, 2}, pointdat{n, 3});
end

fclose(fid);
