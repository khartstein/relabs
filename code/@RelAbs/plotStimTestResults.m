function [SD_Res2, fixRes] = plotStimTestResults(ra, varargin)
% RelAbs.plotStimTestResults
%
% Description: plot results of ra.testStimFeat
%
% Syntax: [resSD, resFix] = ra.plotStimTestResults()
%
% In:
%   <optional>
%   testRes     -   a structure of results from ra.testStimFeat

%
% Out:
%   SD_Res      -   a structure describing the sdArrays by blockType
%   fixRes      -   a 4 x 5 x 6 array (feature: C N O S x matchType: 0 1 2 3 4
%                       x blockType) with results for the fixation task
%
% Notes:      
%   - If testRes argument is omitted, this function will run ra.testStimFeat
%       on its own
%   - Plots for each blocktype show frequencies of all individual stimulus 
%       features and sd match frequencies for all levels in separate graphs.
%       Ensure that match frequencies are not confounded across levels.
%       - Key for SD arrays: 
%           bNoneSame   : []
%           bOneSame    : s/o/n/c
%           bTwoSame    : so/sn/on/sc/oc/nc
%           bThreeSame  : son/soc/snc/onc
%           bAllSame    : sonc
%
% ToDo:    
%
% Updated: 12-15-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[opt]   = ParseArgs(varargin, 'testRes', [], 'clearPlots', true);

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
SD_Res2     = [];
SD_Res3     = [];
fixMatch    = NaN(4, 36*nRun, nBlock);
fixMatchSum = NaN(4, 5, nBlock);
nGrandCount = zeros(4, 2, nBlock);

s.sd_array2 = cell(1, 36*nBlock*nRun);
s.sd_array3 = cell(1, 36*nBlock*nRun);

for kBlock = 1:nBlock
        
    blockColors         = s.stim_colors(s.blockType == kBlock);
    blockNumbers        = s.stim_numbers(s.blockType == kBlock);
    blockOrientations   = s.stim_orientations(s.blockType == kBlock);
    blockShapes         = s.stim_shapes(s.blockType == kBlock);
    blockFixFeats       = s.fix_feature(s.blockType == kBlock);
    blockFixVals        = s.fix_value(s.blockType == kBlock);

    iTrials             = s.iteration(s.blockType == kBlock);
    
    % logic from level 2 (blockType 3/4)
    for kTrial = 1:length(iTrials)
        bSame2 = [isequaln(blockColors{kTrial}{1}, blockColors{kTrial}{2}),              ...
                  isequaln(blockNumbers{kTrial}{1}, blockNumbers{kTrial}{2}),            ...
                  isequaln(blockOrientations{kTrial}{1}, blockOrientations{kTrial}{2}),  ...
                  isequaln(blockShapes{kTrial}{1}, blockShapes{kTrial}{2})];
        s.sd_array2{iTrials(kTrial)} = bSame2;
    end
    
    % logic from level 3 (blockType 5/6)
    for kTrial = 1:length(iTrials)
        bSame3 = [isequaln(blockColors{kTrial}{1}, blockColors{kTrial}{2}) == isequaln(blockColors{kTrial}{3}, blockColors{kTrial}{4}),                          ...
                 isequaln(blockNumbers{kTrial}{1}, blockNumbers{kTrial}{2}) == isequaln(blockNumbers{kTrial}{3}, blockNumbers{kTrial}{4}),                      ...
                 isequaln(blockOrientations{kTrial}{1}, blockOrientations{kTrial}{2}) == isequaln(blockOrientations{kTrial}{3}, blockOrientations{kTrial}{4}),  ...
                 isequaln(blockShapes{kTrial}{1}, blockShapes{kTrial}{2}) == isequaln(blockShapes{kTrial}{3}, blockShapes{kTrial}{4})];
        s.sd_array3{iTrials(kTrial)} = bSame3;
    end
        
    % stats for SDarrays
    for kLogic = 2:3
        for kSD = 1:length(SD_Names)
            SD_Name             = eval(SD_Names{kSD});
            dims                = size(SD_Name);
            resField            = ['n' SD_Names{kSD}(2:end)];
            tempSD.(resField)   = [];        
            for kUnique = 1:dims(1)
                if isempty(tempSD.(resField))
                    tempSD.(resField) = ...
                            sum(cellfun(@isequaln, s.(['sd_array' num2str(kLogic)])(s.blockType == kBlock),   ...
                            repmat({SD_Name(kUnique, :)}, 1, length(s.(['sd_array' num2str(kLogic)]))/nRun)));
                else
                    tempSD.(resField) = [tempSD.(['n' SD_Names{kSD}(2:end)]);           ...
                             sum(cellfun(@isequaln, s.(['sd_array' num2str(kLogic)])(s.blockType == kBlock),  ...
                             repmat({SD_Name(kUnique, :)}, 1, length(s.(['sd_array' num2str(kLogic)]))/nRun)))];
                end
            end
        end 

        if kLogic == 2 && isempty(SD_Res2)
            SD_Res2          = tempSD;
        elseif kLogic ==2
            SD_Res2(end + 1) = tempSD;
        elseif kLogic == 3 && isempty(SD_Res3)
            SD_Res3          = tempSD;
        elseif kLogic == 3
            SD_Res3(end + 1) = tempSD;
        end
    end
    
    % stats for fixation feature and value by block type
    for kTrial = 1:length(iTrials)    
        featVals        = switch2(blockFixFeats(kTrial), 1, colors, 2, numbers, 3, orientations, 4, shapes);
        trialFixFeat    = featVals(blockFixVals(kTrial));
        trialStimFeats  = switch2(blockFixFeats(kTrial), 1, blockColors, 2, blockNumbers, 3, blockOrientations, 4, blockShapes);
        fixMatch(blockFixFeats(kTrial), kTrial, kBlock) = ...
            sum(cellfun(@isequaln, trialStimFeats{kTrial}, repmat(trialFixFeat, 1, length(blockColors{kTrial}))));
        
        for kFeat = 1:2
            nGrandCount(1,kFeat, kBlock) = nGrandCount(1,kFeat, kBlock) + sum(cellfun(@isequaln, blockColors{kTrial}, repmat(colors(kFeat), 1, 4)));
            nGrandCount(2,kFeat, kBlock) = nGrandCount(2,kFeat, kBlock) + sum(cellfun(@isequaln, blockNumbers{kTrial}, repmat(numbers(kFeat), 1, 4)));
            nGrandCount(3,kFeat, kBlock) = nGrandCount(3,kFeat, kBlock) + sum(cellfun(@isequaln, blockOrientations{kTrial}, repmat(orientations(kFeat), 1, 4)));
            nGrandCount(4,kFeat, kBlock) = nGrandCount(4,kFeat, kBlock) + sum(cellfun(@isequaln, blockShapes{kTrial}, repmat(shapes(kFeat), 1, 4)));
        end
    
    end
    
    for kFixFeat = 1:4
        fixMatchSum(kFixFeat, :, kBlock) = [nansum(fixMatch(kFixFeat, :, kBlock) == 0), nansum(fixMatch(kFixFeat, :, kBlock) == 1), ...
                                            nansum(fixMatch(kFixFeat, :, kBlock) == 2), nansum(fixMatch(kFixFeat, :, kBlock) == 3), ...
                                            nansum(fixMatch(kFixFeat, :, kBlock) == 4)];
    end

end

fixRes = fixMatchSum;

% now for the plotting
sd2ByBlock  = zeros(length(SD_Names), 6, nBlock);
sd3ByBlock  = zeros(length(SD_Names), 6, nBlock);

for kBlock = 1:nBlock
    sd2ByBlock(:, :, kBlock)        = [[SD_Res2(kBlock).nNoneSame, zeros(1,5)]; [SD_Res2(kBlock).nOneSame', zeros(1, 2)]; ...
                                       SD_Res2(kBlock).nTwoSame'; [SD_Res2(kBlock).nThreeSame', zeros(1,2)]; ...
                                       [SD_Res2(kBlock).nAllSame', zeros(1,5)]];
    sd3ByBlock(:, :, kBlock)        = [[SD_Res3(kBlock).nNoneSame, zeros(1,5)]; [SD_Res3(kBlock).nOneSame', zeros(1, 2)]; ...
                                       SD_Res3(kBlock).nTwoSame'; [SD_Res3(kBlock).nThreeSame', zeros(1,2)]; ...
                                       [SD_Res3(kBlock).nAllSame', zeros(1,5)]];
end

if opt.clearPlots
    close all;
end

for kPlot = 1:nBlock
    set(0,'DefaultFigureWindowStyle','docked')
    figure;
    
    ax1 = subplot(4, 1, 1);
    bar(ax1,fixMatchSum(:,:,kPlot)'/216);
    axis([0.5 5.5 0 0.3]);
    xlabel('# of matches');
    set(ax1, 'XTickLabel', {'0', '1', '2', '3', '4'});
    ylabel('% (of 216)');
    title(['fixation task stimulus frequency, block type ' num2str(kPlot)]);
    
    ax2 = subplot(4,1,2);
    bar(ax2,sd2ByBlock(:, :, kPlot)/216)
    axis([0.5 5.5 0 0.2]);
    xlabel('# same')
    set(ax2, 'XTickLabel', {'0', '1', '2', '3', '4'});
    ylabel('% (of 216)');
    title(['same-diff frequencies (level 2 logic), block type ' num2str(kPlot)]);
    
    ax3 = subplot(4,1,3);
    bar(ax3,sd3ByBlock(:, :, kPlot)/216)
    axis([0.5 5.5 0 0.2]);
    xlabel('# same')
    set(ax3, 'XTickLabel', {'0', '1', '2', '3', '4'});
    ylabel('% (of 216)');
    title(['same-diff frequencies (level 3 logic), block type ' num2str(kPlot)]);
    
    ax4 = subplot(4,1,4);
    bar(ax4, nGrandCount(:,:,kPlot)/(216*4));
    axis([0.5 4.5 0.35 0.65]);
    xlabel('stimulus feature')
    set(ax4, 'XTickLabel', {'col', 'num', 'orient', 'shape'})
    ylabel('% (of 864)')
    title(['frequency of all feature values, block type ' num2str(kPlot)']);
end

end