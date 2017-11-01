function [] = CombineRelAbsSubjectInfo(inits)
% CombineRelAbsSubjectInfo
% 
% Description: Combines training and MRI subject info for RelAbs participants
% 
% Syntax:	res = AnalyzeGroupData('05oct89kh.mat')
% 
% In:
%	inits       - the subject's initials (e.g. 'kh')
%
% Out:
%
% Notes:        
%   saves a new .mat file with same name as subject's info file, but in the
%   'data/combined/' directory
%
%
% Updated: 06-08-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)
global strDirData 

% field names for merging/removal
cFieldNames    = {'init', 'gender', 'dob', 'handedness', 'mri_block_order', 'train_block_order'};
                
% load data for subject (prompt for training file name)
sMRI            = load([DirAppend(strDirData, 'MRI_behavioral') inits '.mat']);
sTrain          = load([DirAppend(strDirData, 'training_behavioral') inits, '.mat']);
sMerged     = struct;

disp(['merging info for ' inits]);

% merge 
for kField = 1:numel(cFieldNames(1:end-2))
    if any(sMRI.ifoSubject.(cFieldNames{kField}) ~= sTrain.ifoSubject.(cFieldNames{kField}));
        disp(['different information for field ''' cFieldNames{kField} '''.' ]);
        disp('MRI: '); 
        disp(conditional(strcmpi('dob', cFieldNames(kField)), ...
            datestr(ms2serial(sMRI.ifoSubject.(cFieldNames{kField}))), sMRI.ifoSubject.(cFieldNames{kField})));
        disp('Train: '); 
        disp(conditional(strcmpi('dob', cFieldNames(kField)), ...
            datestr(ms2serial(sTrain.ifoSubject.(cFieldNames{kField}))), sTrain.ifoSubject.(cFieldNames{kField})));
        bWhich = input('Press 1 to use MRI info, 2 to use Training info: ');
        sMerged.ifoSubject.(cFieldNames{kField}) = switch2(bWhich, 1, sMRI.ifoSubject.(cFieldNames{kField}), 2, sTrain.ifoSubject.(cFieldNames{kField}), []);
    else
        sMerged.ifoSubject.(cFieldNames{kField}) = sMRI.ifoSubject.(cFieldNames{kField});
    end
end

sMerged.ifoSubject.mri_block_order      = sMRI.ifoSubject.mri_block_order;
sMerged.ifoSubject.train_block_order    = sTrain.ifoSubject.train_block_order;

ifoSubject = sMerged.ifoSubject;

% save in data/combined_behavioral folder
save([strDirData inits '.mat'], 'ifoSubject');

end