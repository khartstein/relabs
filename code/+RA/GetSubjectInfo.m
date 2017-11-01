function ifo = GetSubjectInfo()
% RA.GetSubjectInfo
% 
% Description:	get info about the RelAbs subjects
% 
% Syntax:	ifo = RA.GetSubjectInfo()
% 
% In:
% 	kReturn	- the subject numbers of the subjects to load
% 
% Out:
% 	ifo	- a struct of info
% 
% Updated: 06-13-2016
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  All Rights Reserved.
% Modified (heavily) by Kevin Hartstein (kevinhartstein@gmail.com) for
% RelAbs experiment

global strDirBase strDirData

%get list of subjects
subjectList     = restruct(dir(DirAppend(strDirData, 'behavioral', 'combined_behavioral')));
subjectList     = subjectList.name(3:end);
ifo             = struct;

for kSubject=1:numel(subjectList)
    strCode                         = subjectList{kSubject}(1:end-4);
    ifo(kSubject).code              = strCode;
    ifo(kSubject).path.behavioral   = [DirAppend(strDirData, 'behavioral', 'combined_behavioral') strCode '.mat'];
    s = load(DirAppend(strDirData, 'behavioral', [strCode(end-1:end) '.mat']));
    cFields = fieldnames(s.ifoSubject);
    for kField = 1:numel(cFields)
        ifo(kSubject).(cFields{kField}) = s.ifoSubject.(cFields{kField});
    end
end

%create ifo struct and get paths
ifo = restruct(ifo);

ifo.path.functional.raw	= cellfun(@(s) GetPathFunctional(strDirData,s,'run','all'),ifo.code,'uni',false);
ifo.path.functional.pp	= cellfun(@(s,raw) conditional(numel(raw)>0,GetPathFunctional(strDirData,s,'type','pp','run',(1:numel(raw))'),{}),ifo.code,ifo.path.functional.raw,'uni',false);
ifo.path.functional.cat	= cellfun(@(s) GetPathFunctional(strDirData,s,'type','cat'),ifo.code,'uni',false);
ifo.path.diffusion.raw	= cellfun(@(s) GetPathDTI(strDirData,s),ifo.code,'uni',false);
ifo.path.structural.raw	= cellfun(@(s) GetPathStructural(strDirData,s),ifo.code,'uni',false);

ifo = restruct(ifo);