% Script to get good blocks (in which subjects met criterion) from the
% Relabs MRI data.
%
% Notes: creates onset files (overwriting existing files) for each level 
%   for each subject in the 'data/onsets/[SUBCODE]/' directory
%   condition labels are as follows: 1 = 1S, 2 = 1D, 
%   3 = 2S, 4 = 2D, 5 = 3S, 6 = 3D, 7 = JUNK (block not reaching criterion)
%
%   blocks in which subject failed to meet criterion are coded as empty
%   (i.e. column of zeros with same length as run)

ifo = RA.GetSubjectInfo;

[trainRes, mriRes, overallResMRI, overallResTrain, allTrainRes, allMRIRes] = AnalyzeGroupData('bPlotIndi', 0, 'bPlot', 0);

% Standard timing file
stdFile = [0 0                                                 ...
           0 0 0 0 0 0 0 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 0 0 0 ...
           0 0 0 0 0 0 0 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 0 0 0 ...
           0 0 0 0 0 0 0 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 0 0 0 ...
           0 0 0 0 0 0 0 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 0 0 0 ...
           0 0 0 0 0 0 0 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 0 0 0 ...
           0 0 0 0 0 0 0 12 12 12 12 12 12 12 12 12 12 12 12 12 12 12 12 0 0 0];

bGood       = zeros(12,6,20);
bAnalyze    = zeros(12,6,20);

for kSubject = 1:length(ifo)    
    subOnsetsDir = DirAppend(strDirData, 'onsets', ifo(kSubject).code);
    mkdir(subOnsetsDir);
    disp(ifo(kSubject).code);
    for kLevel = 1:6 
        disp(['level ' num2str(kLevel) ' block position in runs 1-12 was ' num2str(allMRIRes{kSubject}(kLevel).PosInRun)]);
        orderInRun = allMRIRes{kSubject}(kLevel).PosInRun;
        s = restruct(allMRIRes{kSubject}(kLevel));
        for kRun = 1:12
            if s(kRun).Accuracy >= 0.75 && s(kRun).nTrials >=3
                bGood(kRun, kLevel, kSubject) = 1;
                bAnalyze(kRun, orderInRun(kRun), kSubject) = 1;
                a   = Replace(stdFile, orderInRun(kRun)+6, 1); 
                a   = Replace(a, a(a ~= 1), 0)';
                % save onset file in subject's onsets directory
                fID = fopen([subOnsetsDir 'run' sprintf('%02d', kRun) '_cond_' num2str(kLevel) '.txt'], 'w');
                fprintf(fID, '%f\n', a);
                fclose(fID);
                % Save empty txt file (i.e.e 158 zeros) as JUNK
                fID = fopen([subOnsetsDir 'run' sprintf('%02d', kRun) '_cond_7.txt'], 'w');
                fprintf(fID, '%f\n', a);
                fclose(fID);
            else
                a   = Replace(stdFile, orderInRun(kRun)+6, 1); 
                a   = Replace(a, a(a ~= 1), 0)';
                % Save txt file as JUNK
                fID = fopen([subOnsetsDir 'run' sprintf('%02d', kRun) '_cond_7.txt'], 'w');
                fprintf(fID, '%f\n', a);
                fclose(fID);
                % Save empty file (i.e. 158 zeros) for this condition in
                % subject's onsets directory
                fID = fopen([subOnsetsDir 'run' sprintf('%02d', kRun) '_cond_' num2str(kLevel) '.txt'], 'w');
                fprintf(fID, '%f\n', zeros(158,1));
                fclose(fID);
            end
        end
    end
    disp('Good blocks unscrambled into level order');
    bGood(:,:,kSubject)
    disp('Good blocks scrambled back into actual run order');
    bAnalyze(:,:,kSubject)
    disp('===========================================================');
end

tSequenceTR = cumsum([
                      RA.Param('time', 'rest')
                      repmat([RA.Param('time', 'prompt'); RA.Param('time', 'wait'); ... 
                      RA.Param('time', 'trialloop'); RA.Param('time', 'timeup'); RA.Param('time', 'rest')], ...
                      [6 1])
                      ]);
tSequenceS = tSequenceTR*RA.Param('time', 'tr')/1000;

nCritMat = mean(bGood, 1);
nCritMat = reshape(nCritMat, [6 20]);
imagesc(nCritMat'); colormap(gray);

 

                