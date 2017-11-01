% Script to get good blocks (in which subjects met criterion) from the
% Relabs MRI data.

ifo = RA.GetSubjectInfo;
[trainRes, mriRes, overallResMRI, overallResTrain, allTrainRes, allMRIRes] = AnalyzeGroupData('bPlotIndi', 0, 'bPlot', 0);

subGood = zeros(12,6,20);

for kSubject = 1:length(ifo)    
    disp(ifo(kSubject).code);
    bGoodMat = zeros(12,6);
    for kLevel = 1:6 
        disp(['level ' num2str(kLevel) ' block position in runs 1-12 was ' num2str(allMRIRes{1}(kLevel).PosInRun)]);
        s = restruct(allMRIRes{kSubject}(kLevel));
        bGood = zeros(12,1);
        for kRun = 1:12
            if s(kRun).Accuracy >= 0.75 && s(kRun).nTrials >=3
                bGood(kRun) = 1;
            end
        end
        bGoodMat(:, kLevel) = bGood;
    end
    subGood(:,:,kSubject) = bGoodMat;
    disp(bGoodMat);
    disp('===========================================================');
end

tSequenceTR = cumsum([
                      RA.Param('time', 'rest')
                      repmat([RA.Param('time', 'prompt'); RA.Param('time', 'wait'); ... 
                      RA.Param('time', 'trialloop'); RA.Param('time', 'timeup'); RA.Param('time', 'rest')], ...
                      [6 1])
                      ]);
tSequenceS = tSequenceTR*RA.Param('time', 'tr')/1000;

nCritMat = mean(subGood, 1);
nCritMat = reshape(nCritMat, [6 20]);
imagesc(nCritMat'); colormap(gray);