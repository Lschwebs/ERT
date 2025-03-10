% Lena J. Schwebs
% Created on: 02/24/2025
% Updated on: 03/08/2025
% Adapted from Dr. Andrew D. Parsekian 'CP_ERT_Conv.m'
% Import data from DAS-1 resistivity meter *.Data

function data = importDAS1(fLoc)

%% load file into working variable
fname = fLoc; % file name
fID = fopen(fname,'r'); % open and read file

nLn = 1;
while true
    thisline = fgetl(fID);
        if strcmp(thisline,'#data_start'); break; end  %end of file
        nLn = nLn+1;
end
fclose(fID);

HeaderLines = nLn+2; % found number of headder lines, adjusted to beginning of data
fid = fopen(fLoc,'rt');
for i=1:HeaderLines % loop through headerlines with pointer
    fgetl(fID);
end
    
dCnt = 1;
while true
    d = fgetl(fID);
    if strcmp('#data_end',d) == 1 || strcmp('Run Complete',d) ==1 ; break; end
    if strcmp(d(37),'*') %check for type 1 exception
        fgetl(fID);
        elseif strcmp(d(37),'r') % check for type 2 exception "Error_Zero_Current"
            fgetl(fID);
        else
            dd = strsplit(d,[{' '},{'00*,'}]);
            DD(dCnt,:) = [str2num(dd{2}) str2num(dd{3}) str2num(dd{4}) str2num(dd{5}) str2num(dd{6})];% A B M N R
            data(dCnt,:) = [DD(dCnt,2) DD(dCnt,4) DD(dCnt,6) DD(dCnt,8) DD(dCnt,9)];% A B M N R
            dCnt = dCnt+1;
     end
end

%% calculate apparent resistivity
k = zeros(length(data),1);
rho = zeros(length(data),1);

for i = 1:length(data)
    AM = data(i,1) .* data(i,3);
    BM = data(i,2) .* data(i,3);
    AN = data(i,1) .* data(i,4);
    BN = data(i,2) .* data(i,4);
    k(i,1) = (2 .* pi) ./ ( (1 ./ AM) - (1 ./ BM) - (1 ./ AN) + (1 ./ BN) ); % geometric factor
    rho(i,1) = k(i,1)*data(i,5); % apparent resistivity
end

data(:, 6) = rho;

end