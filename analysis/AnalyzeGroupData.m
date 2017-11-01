function [trainRes, mriRes, overallResMRI, overallResTrain, allTrainRes, allMRIRes] = AnalyzeGroupData(varargin)
% AnalyzeGroupData
% 
% Description: Analyze behavioral data from RelAbs experiment
% 
% Syntax:	res = AnalyzeGroupData('MRI')
% 
% In:
%   <options>
%   bPlot       - a boolean specifying whether to plot the overall means
%                   for Accuracy, RT, and number of trials completed
%                   (default is false)
%   bPlotIndi   - a boolean specifying whether to plot the individual means
%                   for the same stuff as bPlot (default is false)
%   plotSession - a string indicating which session of data to use for
%                   plots. Must be 'mri' (default) or 'train' 
%       
% Out:
% 	trainRes    - a struct containing mean accuracy, mean number of trials
%                   completed, and number of runs obtaining criterion for 
%                   each level of the training session
% 	mriRes      - a struct containing mean accuracy, mean number of trials
%                   completed, and number of runs obtaining criterion for 
%                   each level of the mri session
%   allTrainRes - The full behavioral training results for all participants 
%                   by run (a cell of outputs from AnalyzeOneTrain)
%   allMRIRes   - The full behavioral MRI results for all participants 
%                   by run (a cell of outputs from AnalyzeOneMRI)
%   overallResMRI   - a struct with a bunch of matrices that contain all the
%                       overall subject means for the MRI data
%   overallResMRI   - a struct with a bunch of matrices that contain all the
%                       overall subject means for the training data
%
% ToDo:          
%               - big array of booleans for each subject by run and block
%                   for which blocks met criterion (will be used for 
%                   selecting MRI data to use in analysis). Should be in
%                   order that the subject experienced.
%               - graphs with error bars for group data
%
% Updated: 10-12-2017
% Written by Kevin Hartstein (kevinhartstein@gmail.com) 

opt = ParseArgs(varargin, 'bPlot', false, 'bPlotIndi', false, 'plotSession', 'mri');

ifo             = restruct(RA.GetSubjectInfo);
cPathBehavioral = ifo.path.behavioral'; 

allTrainRes = cellfun(@AnalyzeOneTrain,cPathBehavioral, 'UniformOutput', false);
allMRIRes   = cellfun(@AnalyzeOneMRI, cPathBehavioral, 'UniformOutput', false);

if numel(allTrainRes) ~= numel(allMRIRes)
    error('number of participants is different between training and MRI');
end

disp('finding means and number of criterion blocks for training data');
trainRes    = doStats(allTrainRes);
disp('finding means and number of criterion blocks for MRI data');
mriRes      = doStats(allMRIRes);

% find overall means for accuracy, RTs, blip task
overallAccMRI          = zeros(length(mriRes), 6);
overallRTMRI           = zeros(length(mriRes), 6);
overallnTrialsMRI      = zeros(length(mriRes), 6);
overallnCorrectMRI     = zeros(length(mriRes), 6);
overallnCritMRI        = zeros(length(mriRes), 6);
overallnBlipRestMRI    = zeros(length(mriRes), 6);
overallBlipRTRestMRI   = zeros(length(mriRes), 6);
overallnBlipTaskMRI    = zeros(length(mriRes), 6);
overallBlipRTTaskMRI   = zeros(length(mriRes), 6);

overallAccTrain          = zeros(length(mriRes), 6);
overallRTTrain           = zeros(length(mriRes), 6);
overallnTrialsTrain      = zeros(length(mriRes), 6);
overallnCorrectTrain     = zeros(length(mriRes), 6);
overallnCritTrain        = zeros(length(mriRes), 6);
overallnBlipRestTrain    = zeros(length(mriRes), 6);
overallBlipRTRestTrain   = zeros(length(mriRes), 6);
overallnBlipTaskTrain    = zeros(length(mriRes), 6);
overallBlipRTTaskTrain   = zeros(length(mriRes), 6);

for kSubMriRes = 1:length(mriRes)
    overallAccMRI(kSubMriRes, :)          = mriRes(kSubMriRes).Accuracy;
    overallRTMRI(kSubMriRes, :)           = mriRes(kSubMriRes).RTs;
    overallnTrialsMRI(kSubMriRes, :)      = mriRes(kSubMriRes).nTrials;
    overallnCorrectMRI(kSubMriRes, :)     = mriRes(kSubMriRes).nCorrect;
    overallnCritMRI(kSubMriRes, :)        = mriRes(kSubMriRes).nCrit;      
    overallnBlipRestMRI(kSubMriRes, :)    = mriRes(kSubMriRes).nBlipRest;
    overallBlipRTRestMRI(kSubMriRes, :)   = mriRes(kSubMriRes).blipRTRest;
    overallnBlipTaskMRI(kSubMriRes, :)    = mriRes(kSubMriRes).nBlipTask;
    overallBlipRTTaskMRI(kSubMriRes, :)   = mriRes(kSubMriRes).blipRTTask;
end

for kSubTrainRes = 1:length(trainRes)
    overallAccTrain(kSubTrainRes, :)          = trainRes(kSubTrainRes).Accuracy;
    overallRTTrain(kSubTrainRes, :)           = trainRes(kSubTrainRes).RTs;
    overallnTrialsTrain(kSubTrainRes, :)      = trainRes(kSubTrainRes).nTrials;
    overallnCorrectTrain(kSubTrainRes, :)     = trainRes(kSubTrainRes).nCorrect;
    overallnCritTrain(kSubTrainRes, :)        = trainRes(kSubTrainRes).nCrit;      
    overallnBlipRestTrain(kSubTrainRes, :)    = trainRes(kSubTrainRes).nBlipRest;
    overallBlipRTRestTrain(kSubTrainRes, :)   = trainRes(kSubTrainRes).blipRTRest;
    overallnBlipTaskTrain(kSubTrainRes, :)    = trainRes(kSubTrainRes).nBlipTask;
    overallBlipRTTaskTrain(kSubTrainRes, :)   = trainRes(kSubTrainRes).blipRTTask;
end

overallResMRI       = struct('Accuracy', overallAccMRI, 'RT', overallRTMRI, ...
                        'nTrials', overallnTrialsMRI, 'nCrit', overallnCritMRI, ...
                        'nCorrect', overallnCorrectMRI, 'nBlipRest', overallnBlipRestMRI, ...
                        'blipRTRest', overallBlipRTRestMRI, 'nBlipTask', overallnBlipTaskMRI, ...
                        'blipRTTask', overallBlipRTTaskMRI);
overallResTrain     = struct('Accuracy', overallAccTrain, 'RT', overallRTTrain, ...
                        'nTrials', overallnTrialsTrain, 'nCrit', overallnCritTrain, ...
                        'nCorrect', overallnCorrectTrain, 'nBlipRest', overallnBlipRestTrain, ...
                        'blipRTRest', overallBlipRTRestTrain, 'nBlipTask', overallnBlipTaskTrain, ...
                        'blipRTTask', overallBlipRTTaskTrain);

if strcmpi(opt.plotSession, 'MRI')
    doPlots(overallResMRI);
elseif any(strcmpi(opt.plotSession, {'train', 'training', 'psychophysics'}))
    doPlots(overallResTrain);
else
    error('Bad argument enterred for plotSession option - should be ''mri'' or ''train''');
end
                    
%-------------------------------------------------------------------------%
function res = doStats(sessionResults)
    res = [];
    
    for kSub = 1:numel(sessionResults)
        subCur      = [];
        for kLevel = 1:6
            if isempty(subCur)
                subCur.file         = ifo.code{kSub};
                subCur.Level        = sessionResults{kSub}(kLevel).Level;
                subCur.Accuracy     = nanmean(sessionResults{kSub}(kLevel).Accuracy);
                subCur.RTs          = nanmean(sessionResults{kSub}(kLevel).RTs);
                subCur.nTrials      = nanmean(sessionResults{kSub}(kLevel).nTrials);
                subCur.nCrit        = sum((sessionResults{kSub}(kLevel).Accuracy >= .75) & (sessionResults{kSub}(kLevel).nTrials >= 3));
                subCur.nCorrect     = nanmean(sessionResults{kSub}(kLevel).nCorrect);
                subCur.nBlipRest    = sum(~isnan(sessionResults{kSub}(kLevel).restBlip));
                subCur.blipRTRest   = nanmean(sessionResults{kSub}(kLevel).restBlip);
                subCur.nBlipTask    = sum(~isnan(sessionResults{kSub}(kLevel).taskBlip));
                subCur.blipRTTask   = nanmean(sessionResults{kSub}(kLevel).taskBlip);
            else
                subCur.Level        = [subCur.Level sessionResults{kSub}(kLevel).Level];
                subCur.Accuracy     = [subCur.Accuracy nanmean(sessionResults{kSub}(kLevel).Accuracy)];
                subCur.RTs          = [subCur.RTs nanmean(sessionResults{kSub}(kLevel).RTs)];
                subCur.nTrials      = [subCur.nTrials nanmean(sessionResults{kSub}(kLevel).nTrials)];
                subCur.nCrit        = [subCur.nCrit sum((sessionResults{kSub}(kLevel).Accuracy >= .75) & (sessionResults{kSub}(kLevel).nTrials >= 3))];
                subCur.nCorrect     = [subCur.nCorrect nanmean(sessionResults{kSub}(kLevel).nCorrect)];
                subCur.nBlipRest    = [subCur.nBlipRest sum(~isnan(sessionResults{kSub}(kLevel).restBlip))];
                subCur.blipRTRest   = [subCur.blipRTRest nanmean(sessionResults{kSub}(kLevel).restBlip)];
                subCur.nBlipTask    = [subCur.nBlipTask sum(~isnan(sessionResults{kSub}(kLevel).taskBlip))];
                subCur.blipRTTask   = [subCur.blipRTTask nanmean(sessionResults{kSub}(kLevel).taskBlip)];
            end
        end
        
        if isempty(res)
            res = subCur;
        else 
            res(end+1) = subCur;
        end
    end
end
%-------------------------------------------------------------------------%
function [] = doPlots(sessionOverallData)
    if opt.bPlot
        % plots
        figure;

        % percent correct
        subplot(3,1,1)
        hold on;
        bar(1:6, nanmean(sessionOverallData.Accuracy))
        xlabel('level');
        ylabel('Mean accuracy (%)');
        title('Mean accuracy by level');

        % reaction time
        subplot(3,1,2);
        hold on;
        bar(1:6, nanmean(sessionOverallData.RT));
        xlabel('level');
        ylabel('mean RT');
        title('Reaction time by level');

        % number of trials completed
        subplot(3,1,3);
        hold on;
        bar(1:6, nanmean(sessionOverallData.nTrials));
        xlabel('level');
        ylabel('Number of trials completed by level');
        title('Number of trials completed');
    end

    colorList = {[240,163,255],[0,117,220],[153,63,0],[76,0,92],[25,25,25],[0,92,49],[43,206,72],[255,204,153],[128,128,128], ...
                 [148,255,181],[143,124,0],[157,204,0],[194,0,136],[0,51,128],[255,164,5],[255,168,187],[66,102,0],[255,0,16], ...
                 [94,241,242],[0,153,143],[224,255,102],[116,10,255],[153,0,0],[255,255,128],[255,255,0],[255,80,5]};

    if opt.bPlotIndi
        figure;
        % percent correct
        hold on;
        for kRow = 1:size(sessionOverallData.Accuracy, 1)
            plot(1:6, sessionOverallData.Accuracy(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Mean accuracy (%)');
        title('Mean accuracy by level');

        % reaction time
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.RT, 1)
            plot(1:6, sessionOverallData.RT(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('mean RT');
        title('Reaction time by level');

        % number of trials completed
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.nTrials, 1)
            plot(1:6, sessionOverallData.nTrials(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Number of trials completed by level');
        title('Number of trials completed');

        % number of trials completed
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.nCorrect, 1)
            plot(1:6, sessionOverallData.nCorrect(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Number of correct trials by level');
        title('Number correct');
        
        % number of trials reaching criterion
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.nCrit, 1)
            plot(1:6, sessionOverallData.nCrit(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Number of runs reaching criterion by level');
        title('Number of runs reaching criterion');

        % number of blips detected during rest
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.nBlipRest, 1)
            plot(1:6, sessionOverallData.nBlipRest(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Number of runs in which fixation blips were detected during rest');
        title('Detection of fixation blips during rest');

        % number of blips detected during rest
        figure;
        hold on;
        for kRow = 1:size(sessionOverallData.nBlipTask, 1)
            plot(1:6, sessionOverallData.nBlipTask(kRow, :), 'Color', colorList{kRow}/256);
        end
        xlabel('level');
        ylabel('Number of runs in which fixation blips were detected during task');
        title('Detection of fixation blips during task');
    end
end
%-------------------------------------------------------------------------%
end