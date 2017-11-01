function behaveData = CombineRelAbsData(filename)
% CombineRelAbsData
% 
% Description: Combines training and MRI data for RelAbs participants
% 
% Syntax:	res = AnalyzeGroupData('05oct89kh.mat')
% 
% In:
%	filename    - the filename for the MRI session
%
% Out:
% 	behaveData  - the combined struct that is also saved in
%                   'data/combined_behavioral' directory
%
% Notes:        
%   saves a new .mat file with same name as scan data, but in the
%   'data/combined/' directory
%
%
% Updated: 06-01-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)
global strDirData 

% field names for merging/removal
cTrainFieldNames    = {'train_blocktiming', 'train_result', 'train_blipresulttask'         , ...
                       'train_blipresultrest', 'train_runtiming', 'train_practiceresult'   , ...
                       'train_trialinfo', 'train_rest_blip', 'train_block_blip'};
cFields2Remove      = {'session', 'run', 'block', 'prepared'};
                
% load data for subject (prompt for training file name)
sMRI            = load([DirAppend(strDirData, 'MRI_behavioral') filename]);
disp(['MRI data is named ' filename]);
strTrainFile    = input('Name of .mat file for training data? [leave empty to skip]: ', 's');

% merge training data into MRI data
if ~isempty(strTrainFile)
    sTrain          = load([DirAppend(strDirData, 'training_behavioral') strTrainFile]);

    for kField = 1:numel(cTrainFieldNames)
        sMRI.PTBIFO.ra.(cTrainFieldNames{kField}) = sTrain.PTBIFO.ra.(cTrainFieldNames{kField});
    end
    
    % save in data/combined_behavioral folder
    behaveData = sMRI.PTBIFO.ra;
    behaveData = rmfield(behaveData, cFields2Remove);
    
    save([DirAppend(strDirData, 'combined_behavioral') filename], 'behaveData');
end

end