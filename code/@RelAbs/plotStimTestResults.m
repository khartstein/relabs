function [SD_Res, fixRes] = plotStimTestResults(ra, varargin)
% RelAbs.plotStimTestResults
%
% Description: plot results of ra.testStimFeat
%
% Syntax: [resSD, resFix] = ra.plotStimTestResults()
%
% In:
%   <optional>
%   testRes     -   a structure of results from ra.testStimFeat
%   levelSD     -   the level at which to perform the SD comparison
%                   (2 or 3, default = 2). The (1x4) SD arrays mean different 
%                   things in different levels. In level 2 (blockType 3/4)
%                   the boolean specifies which features [C N O S] match between
%                   stimulus 1 and 2 (the framed stimuli). In level 3
%                   (blockType 5/6) the boolean specifies which feature
%                   dimensions share match/mismatch values. Setting this
%                   argument to 2 will recode SD arrays in level 1 and 3
%                   blocks (blockType 1/2/5/6) into the logic of level 2.
%                   Setting it to 3 will recode level 1 and 2 blocks
%                   (1/2/3/4) into the logic of level 3. 
%
% Out:
%   SD_Res      -   a structure describing the sdArrays by blockType
%   fixRes      -   a 4 x 5 x 6 array (feature: C N O S x matchType: 0 1 2 3 4
%                       x blockType) with results for the fixation task
%
% Notes:      
%   - If testRes argument is omitted, this function will run ra.testStimFeat
%       on its own
%   - Plots for each blocktype show SD_Array frequency as a function of 
%       match type (defined based on levelSD argument) and frequency of 
%       trials for the fixation task as a function of fixation feature and
%       number of matching stimuli
%       - Key for SD arrays: 
%           bNoneSame   : []
%           bOneSame    : s/o/n/c
%           bTwoSame    : so/sn/on/sc/oc/nc
%           bThreeSame  : son/soc/snc/onc
%           bAllSame    : sonc
%
% ToDo:    
%   - Add meaningful output for levelSD = 1 (recode sd_array to mean which
%       features match fixation)
%
% Updated: 12-14-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[opt]   = ParseArgs(varargin, 'testRes', [], 'levelSD', 2);

if isempty(opt.testRes)
    opt.testRes = ra.testStimFeat();
end

s = restruct(opt.testRes);
clear('opt.testRes');

% design info
nRun            = RA.Param('exp','runs');
nBlock          = RA.Param('exp', 'blocks');

% features and values
colors          = struct2cell(RA.Param('stim_color'));
numbers         = struct2cell(RA.Param('stim_number'));
orientations    = fieldnames(RA.Param('stim_orient'));
shapes          = fieldnames(RA.Param('stim_shape'));

% same/different arrays
bOneSame        = unique(perms([1 0 0 0]), 'rows');
bTwoSame        = unique(perms([0 0 1 1]), 'rows');
bThreeSame      = unique(perms([0 1 1 1]), 'rows');
bAllSame        = [1 1 1 1];
bNoneSame       = [0 0 0 0];

SD_Names    = {'bOneSame', 'bTwoSame', 'bThreeSame', 'bAllSame', 'bNoneSame'};
fixList     = {'colorFix', 'numberFix', 'orientationFix', 'shapeFix'};
fixRes      = [];
SD_Res      = [];
fixMatch    = NaN(4, 36*nRun, nBlock);
fixMatchSum = NaN(4, 5, nBlock);

for kBlock = 1:nBlock
        
    changeBlocks = switch2(opt.levelSD, 1, [3 4 5 6], 2, [1 2 5 6], 3, [1 2 3 4], []);
    blockColors         = s.stim_colors(s.blockType == kBlock);
    blockNumbers        = s.stim_numbers(s.blockType == kBlock);
    blockOrientations   = s.stim_orientations(s.blockType == kBlock);
    blockShapes         = s.stim_shapes(s.blockType == kBlock);
    blockFixFeats       = s.fix_feature(s.blockType == kBlock);
    blockFixVals        = s.fix_value(s.blockType == kBlock);

    iTrials             = s.iteration(s.blockType == kBlock);
    
    if ismember(kBlock, changeBlocks)
        switch opt.levelSD
            case 1
                % logic for each level independently
                % leave SDarrays as they are (NaN's for 1/2, feature
                % match for 3/4, dimensions match for 5/6)
            case 2
                % logic from level 2 (blockType 3/4)
                for kTrial = 1:length(iTrials)
                    bSame = [isequaln(blockColors{kTrial}{1}, blockColors{kTrial}{2}),              ...
                             isequaln(blockNumbers{kTrial}{1}, blockNumbers{kTrial}{2}),            ...
                             isequaln(blockOrientations{kTrial}{1}, blockOrientations{kTrial}{2}),  ...
                             isequaln(blockShapes{kTrial}{1}, blockShapes{kTrial}{2})];
                    s.sd_array{iTrials(kTrial)} = bSame;
                end
            case 3
                % logic from level 3(blockType 5/6)
                for kTrial = 1:length(iTrials)
                    bSame = [isequaln(blockColors{kTrial}{1}, blockColors{kTrial}{2}) == isequaln(blockColors{kTrial}{3}, blockColors{kTrial}{4}),                          ...
                             isequaln(blockNumbers{kTrial}{1}, blockNumbers{kTrial}{2}) == isequaln(blockNumbers{kTrial}{3}, blockNumbers{kTrial}{4}),                      ...
                             isequaln(blockOrientations{kTrial}{1}, blockOrientations{kTrial}{2}) == isequaln(blockOrientations{kTrial}{3}, blockOrientations{kTrial}{4}),  ...
                             isequaln(blockShapes{kTrial}{1}, blockShapes{kTrial}{2}) == isequaln(blockShapes{kTrial}{3}, blockShapes{kTrial}{4})];
                    s.sd_array{iTrials(kTrial)} = bSame;
                end
        end
    end
        
    % stats for SDarrays
    for kSD = 1:length(SD_Names)
        SD_Name             = eval(SD_Names{kSD});
        dims                = size(SD_Name);
        resField            = ['n' SD_Names{kSD}(2:end)];
        tempSD.(resField)   = [];        
        for kUnique = 1:dims(1)
            if isempty(tempSD.(resField))
                tempSD.(resField) = ...
                        sum(cellfun(@isequaln, s.sd_array(s.blockType == kBlock),   ...
                        repmat({SD_Name(kUnique, :)}, 1, length(s.sd_array)/nRun)));
            else
                tempSD.(resField) = [tempSD.(['n' SD_Names{kSD}(2:end)]);           ...
                         sum(cellfun(@isequaln, s.sd_array(s.blockType == kBlock),  ...
                         repmat({SD_Name(kUnique, :)}, 1, length(s.sd_array)/nRun)))];
            end
        end
    end 
    
    if isempty(SD_Res)
        SD_Res          = tempSD;
    else
        SD_Res(end + 1) = tempSD;
    end
    
    % stats for fixation feature and value by block type
    for kTrial = 1:length(iTrials)    
        featVals        = switch2(blockFixFeats(kTrial), 1, colors, 2, numbers, 3, orientations, 4, shapes);
        trialFixFeat    = featVals(blockFixVals(kTrial));
        trialStimFeats  = switch2(blockFixFeats(kTrial), 1, blockColors, 2, blockNumbers, 3, blockOrientations, 4, blockShapes);
        fixMatch(blockFixFeats(kTrial), kTrial, kBlock) = ...
            sum(cellfun(@isequaln, trialStimFeats{kTrial}, repmat(trialFixFeat, 1, length(blockColors{kTrial}))));
    end
    
%     for kFeat = 1:length(fixList)
%             tempFix.(fixList{kFeat})   = [sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 1), ...
%                                           sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 0); ...
%                                           sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 1 & s.fix_value == 1), ...
%                                           sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 0 & s.fix_value == 1); ...
%                                           sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 1 & s.fix_value == 2), ...
%                                           sum(s.fix_feature == kFeat & s.blockType == kBlock & s.correct == 0 & s.fix_value == 2)];
%     end
%     
%     if isempty(fixRes)
%         fixRes = tempFix;
%     else 
%         fixRes(end+1) = tempFix;
%     end
    
    for kFixFeat = 1:4
        fixMatchSum(kFixFeat, :, kBlock) = [nansum(fixMatch(kFixFeat, :, kBlock) == 0), nansum(fixMatch(kFixFeat, :, kBlock) == 1), ...
                                            nansum(fixMatch(kFixFeat, :, kBlock) == 2), nansum(fixMatch(kFixFeat, :, kBlock) == 3), ...
                                            nansum(fixMatch(kFixFeat, :, kBlock) == 4)];
    end

end

fixRes = fixMatchSum;

% now for the plotting
sdByBlock   = zeros(length(SD_Names), 6, nBlock);
% fixByBlock  = zeros(4, 4, nBlock);

for kBlock = 1: nBlock
    sdByBlock(:, :, kBlock)         = [[SD_Res(kBlock).nNoneSame, zeros(1,5)]; [SD_Res(kBlock).nOneSame', zeros(1, 2)]; ...
                                       SD_Res(kBlock).nTwoSame'; [SD_Res(kBlock).nThreeSame', zeros(1,2)]; ...
                                       [SD_Res(kBlock).nAllSame', zeros(1,5)]];
%     if kBlock <= 2
%         fixByBlock(:, :, kBlock)    = [[fixRes(kBlock).colorFix(2, :), fixRes(kBlock).colorFix(3, :)]; ...
%                                        [fixRes(kBlock).numberFix(2, :), fixRes(kBlock).numberFix(3, :)]; ...
%                                        [fixRes(kBlock).orientationFix(2, :), fixRes(kBlock).orientationFix(3, :)]; ...
%                                        [fixRes(kBlock).shapeFix(2, :), fixRes(kBlock).shapeFix(3, :)]];
%     else
%         fixByBlock(:, :, kBlock)    = [[0, sum(fixRes(kBlock).colorFix(2, :)), 0, sum(fixRes(kBlock).colorFix(3, :))]; ...
%                                        [0, sum(fixRes(kBlock).numberFix(2, :)), 0, sum(fixRes(kBlock).numberFix(3, :))]; ...
%                                        [0, sum(fixRes(kBlock).orientationFix(2,:)), 0, sum(fixRes(kBlock).orientationFix(3,:))]; ...
%                                        [0, sum(fixRes(kBlock).shapeFix(2, :)), 0, sum(fixRes(kBlock).shapeFix(3, :))]];
%     end
end

for kPlot = 1:nBlock
    figure;
    ax1 = subplot(2,1,1);
    bar(ax1,sdByBlock(:, :, kPlot)/216)
    axis([0.5 5.5 0 0.2]);
    xlabel('SD Values')
    ylabel('frequency (% of 216 trials)');
    title(['same-diff array frequencies, block type ' num2str(kPlot)]);
    
    ax2 = subplot(2, 1, 2);
    bar(ax2,fixMatchSum(:,:,kPlot)'/216);
    axis([0.5 5.5 0 0.3]);
    xlabel('Fixation Feature');
    ylabel('frequency (% of 216 trials)');
    title(['fixation task stimulus frequency, block type ' num2str(kPlot)]);
%     legend('Correct', 'Incorrect', 'Location', 'SouthEastOutside');
end

end