% Lena Schwebs
% Created: 11/19/2024
% Updated: 11/19/2024

function resDates = extractDates(fLoc)
%fLoc = ("C:\Users\lschwebs\OneDrive - University of Wyoming\Codes\Github\MRS_Inverison_2025-10-13\MRS_ERT_RawData\");
%% load raw files to extract dates
files = dir(fullfile(fLoc, '*.tx0')) ;    % get all dat files in the folder 

for i = 1:length(files)
    titleStr = strsplit(files(i).name, {'_', '.'});
    dates(i, 1) = titleStr(1); % store datetime
end


resDates = datetime(dates);

end