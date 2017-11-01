function res = AnalyzeOneMRI(resFile, varargin)
% AnalyzeOneMRI
% 
% Description: Analyze data from one subject's MRI run in the RelAbs
%   experiment
% 
% Syntax:	res = AnalyzeOneMRI('05oct89kh.mat')
% 
% In:
%	resFile     - the name (w/ full path) of the file to use for the
%                   analysis
% <options>
%   bplot       - a boolean specifying whether to plot results by run
%
% Out:
% 	res         - a struct with results from this subject's mri
%                   session
%
% ToDo:          
%               - RT stuff
%               - Need blocks in which participants met criteria in order
%                   they were experienced by the participant.
%
% Updated: 10-12-2017
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt = ParseArgs(varargin, 'bPlot', false);

% load subject's data
s = load(resFile);
disp(['analyzing MRI data for ' resFile(end-12:end)]);

[B1,B2,B3,B4,B5,B6] = deal([]);
nRuns               = size(s.behaveData.mri_result, 1);
nLevels             = size(s.behaveData.mri_result, 2);

[B1BlipRest, B1BlipTask, B2BlipRest, B2BlipTask, B3BlipRest, B3BlipTask, ...
 B4BlipRest, B4BlipTask, B5BlipRest, B5BlipTask, B6BlipRest, B6BlipTask, ...
 B1PosInRun, B2PosInRun, B3PosInRun, B4PosInRun, B5PosInRun, B6PosInRun] = deal([]);

% split data by level
for kRun = 1:nRuns
    for kBlock = 1:nLevels
        blockData       = s.behaveData.mri_result{kRun, kBlock};
        
        switch blockData(1).level
            case 1
                B1 = [B1, blockData];
                B1BlipRest  = [B1BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B1BlipTask  = [B1BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B1PosInRun  = [B1PosInRun, kBlock];
            case 2
                B2 = [B2, blockData];
                B2BlipRest  = [B2BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B2BlipTask  = [B2BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B2PosInRun  = [B2PosInRun, kBlock];
            case 3
                B3 = [B3, blockData];
                B3BlipRest  = [B3BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B3BlipTask  = [B3BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B3PosInRun  = [B3PosInRun, kBlock];
            case 4
                B4 = [B4, blockData];
                B4BlipRest  = [B4BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B4BlipTask  = [B4BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B4PosInRun  = [B4PosInRun, kBlock];
            case 5
                B5 = [B5, blockData];
                B5BlipRest  = [B5BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B5BlipTask  = [B5BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B5PosInRun  = [B5PosInRun, kBlock];
            case 6
                B6 = [B6, blockData];
                B6BlipRest  = [B6BlipRest, s.behaveData.mri_blipresultrest(kRun, kBlock)];
                B6BlipTask  = [B6BlipTask, s.behaveData.mri_blipresulttask(kRun, kBlock)];
                B6PosInRun  = [B6PosInRun, kBlock];
            otherwise
                error(['level labels must be integer 1-6.' ...
                    ' Current value is ' num2str(blockData(1).level) ...
                    ' for block number ' num2str(kBlock)]);
        end
    end
end

% remove repeat trials and make dropped RTs into NaNs
B1 = restruct(noRepeats(B1)); B2 = restruct(noRepeats(B2)); B3 = restruct(noRepeats(B3)); 
B4 = restruct(noRepeats(B4)); B5 = restruct(noRepeats(B5)); B6 = restruct(noRepeats(B6));

% count and NaNify empty RTs
[B1.rt, B1Empties] = fixRT(B1.rt);
disp([num2str(B1Empties) ' empty RTs for level 1 became NaNs']);
[B2.rt, B2Empties] = fixRT(B2.rt);
disp([num2str(B2Empties) ' empty RTs for level 2 became NaNs']);
[B3.rt, B3Empties] = fixRT(B3.rt);
disp([num2str(B3Empties) ' empty RTs for level 3 became NaNs']);
[B4.rt, B4Empties] = fixRT(B4.rt);
disp([num2str(B4Empties) ' empty RTs for level 4 became NaNs']);
[B5.rt, B5Empties] = fixRT(B5.rt);
disp([num2str(B5Empties) ' empty RTs for level 5 became NaNs']);
[B6.rt, B6Empties] = fixRT(B6.rt);
disp([num2str(B6Empties) ' empty RTs for level 6 became NaNs']);

[B1AccMeans, B1nTrials, B1nCorrect] = getMeans(B1, 'correct');
[B2AccMeans, B2nTrials, B2nCorrect] = getMeans(B2, 'correct');
[B3AccMeans, B3nTrials, B3nCorrect] = getMeans(B3, 'correct');
[B4AccMeans, B4nTrials, B4nCorrect] = getMeans(B4, 'correct');
[B5AccMeans, B5nTrials, B5nCorrect] = getMeans(B5, 'correct');
[B6AccMeans, B6nTrials, B6nCorrect] = getMeans(B6, 'correct');

B1RTMeans = getMeans(B1, 'rt');
B2RTMeans = getMeans(B2, 'rt');
B3RTMeans = getMeans(B3, 'rt');
B4RTMeans = getMeans(B4, 'rt');
B5RTMeans = getMeans(B5, 'rt');
B6RTMeans = getMeans(B6, 'rt');

% return results in a structure
for kLevel = 1:nLevels
    res(kLevel) = struct('Level', kLevel, ...
                         'Accuracy', eval(['B' num2str(kLevel) 'AccMeans']),    ...
                         'RTs', eval(['B' num2str(kLevel) 'RTMeans']),          ...
                         'nTrials', eval(['B' num2str(kLevel) 'nTrials']),      ...
                         'nCorrect', eval(['B' num2str(kLevel) 'nCorrect']),    ...
                         'restBlip', eval(['B' num2str(kLevel) 'BlipRest']),    ...
                         'taskBlip', eval(['B' num2str(kLevel) 'BlipTask']),    ...
                         'PosInRun', eval(['B' num2str(kLevel) 'PosInRun']));
end

% plot results
colorList = ['b', 'g', 'r', 'c', 'm', 'y'];

if opt.bPlot
    figure;
    % percent correct
    % ax1 = subplot(3,1,1);
    subplot(3,1,1);
    hold on;
    for kLevel = 1:nLevels
        plot(1:nRuns, eval(['B' num2str(kLevel) 'AccMeans']), colorList(kLevel));
    end
    xlabel('run');
    ylabel('Mean accuracy (%)');
    title('Mean accuracy by run');
    legend('1S', '1D', '2S', '2D', '3S', '3D', 'Location', 'SouthWest');

    % reaction time
    % ax2 = subplot(3,1,2);
    subplot(3,1,2);
    hold on;
    for kLevel = 1:nLevels
        plot(1:nRuns, eval(['B' num2str(kLevel) 'RTMeans']), colorList(kLevel));
    end
    xlabel('run');
    ylabel('mean RT');
    title('Reaction time by run');

    % number of trials completed
    % ax3 = subplot(3,1,3);
    subplot(3,1,3);
    hold on;
    for kLevel = 1:nLevels
        plot(1:nRuns, eval(['B' num2str(kLevel) 'nTrials']), colorList(kLevel));
    end
    xlabel('run');
    ylabel('Number of trials completed by run');
    title('Number of trials completed');
end

%-------------------------------------------------------------------------%
function [fixedRT, emptyCount] = fixRT(RTdata)
    emptyCount = 0;
    if iscell(RTdata)
        fixedRT = zeros(size(RTdata));
        for kTrial = 1:numel(RTdata)
            if ~isempty(RTdata{kTrial})
                fixedRT(kTrial) = RTdata{kTrial};
            else
                fixedRT(kTrial) = NaN;
                emptyCount = emptyCount + 1;
            end
        end
    else
        fixedRT = RTdata;
    end
end
%-------------------------------------------------------------------------%
function [blockResults] = noRepeats(blockResults)
    % identify repeated trials
    repeats = [];
    for k = 2:length(blockResults)
        if blockResults(k).trial == blockResults(k-1).trial
            repeats = [repeats, k];
        end
    end
    nRepeats = numel(repeats);
    % remove repeats
    while ~isempty(repeats)
        blockResults = [blockResults(1:repeats(1) - 1), blockResults(repeats(1) + 1: end)];
        repeats = repeats(2:end) - 1;
    end
    if nRepeats > 0
        disp(['removed ' num2str(nRepeats) ' repeats from level ' num2str(blockResults(1).level)]);
    end
end
%-------------------------------------------------------------------------%
function [blockMeans, nTrials, nCorrect] = getMeans(blockResults, fName)
    % get run means and number of trials completed for plotting
    [blockMeans, nCorrect, nTrials] = deal([]);
    
    for jRun = 1:max(blockResults.run)
       blockMeans  = [blockMeans, nanmean(blockResults.(fName)(blockResults.run == jRun))];
       if strcmpi(fName, 'correct')
            nCorrect    = [nCorrect, sum(blockResults.(fName)(blockResults.run == jRun))];
            nTrials     = [nTrials, sum(blockResults.run == jRun)];
       end
    end
end
%-------------------------------------------------------------------------%
end