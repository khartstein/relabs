function [subRes] = testStimFeat(ra, varargin)
% RelAbs.testStimFeat
%
% Description: Test ra.ChooseStimFeatures
%
% Syntax: ra.testStimFeat()
%
% In:
%   nIterations     -   number of iterations to run (each is 1 subject)
%
% Out:
%
%
% Notes:            
%                       
%
% ToDo:    
%
% Updated: 12-15-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

% parse the arguments
[opt]   = ParseArgs(varargin, 'nIterations', 1);

% block, run, and trial info
nRun            = RA.Param('exp','runs');
nBlock          = RA.Param('exp', 'blocks');
trialInfo       = ra.Experiment.Info.Get('ra', 'trialinfo');

% get feature values from RA.Param
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

bNotOneSame     = [bTwoSame; bThreeSame; bAllSame; bNoneSame];
bNotThreeSame   = [bOneSame; bTwoSame; bAllSame; bNoneSame];

% things just for the testing function
kIteration      = 0;

subRes = [];

for kRun = 1:nRun
    for kBlock = 1:nBlock
        for kTrial = 1:36
            kIteration = kIteration + 1;
            temp = [];
            [sdArray, bCorrect, numSame, sColors, sNumbers, sOrientations, sShapes, fixFeature, fixValue] = doOne(kBlock);
            
            temp.run                = kRun;
            temp.blockType          = kBlock;
            temp.trial              = kTrial;
            temp.iteration          = kIteration;
            temp.correct            = bCorrect;
            temp.sd_array           = sdArray;
            temp.numSame            = numSame;
            temp.stim_colors        = sColors;
            temp.stim_numbers       = sNumbers;
            temp.stim_orientations  = sOrientations;
            temp.stim_shapes        = sShapes;
            temp.fix_feature        = fixFeature;
            temp.fix_value          = fixValue;
            
            if isempty(subRes)
                subRes         = temp;
            else
                subRes(end+1)  = temp;
            end
        end
    end
end


%------------------------------------------------------------------------------%
function [bSame, bCorrect, numSameCorrect, trialColors, trialNumbers, trialOrientations, trialShapes, kFixFeature, kFixValue] = doOne(blockType)
    
    bCorrect        = trialInfo.bcorrect(kRun, kBlock, kTrial);
    numSameCorrect  = switch2(blockType, {1, 3, 5}, 1, {2, 4, 6}, 3);
    kFixFeature     = trialInfo.fixfeature(kRun, kBlock, kTrial);           % will be an integer 1:4
    kFixValue       = randi(2);                                             % will be an integer 1:2
    
    switch kFixFeature
        case 1
            % color
            val     = colors{kFixValue};
        case 2
            % number
            val     = num2str(numbers{kFixValue});
        case 3
            % orientation
            val     = orientations{kFixValue};
        case 4
            % shape
            val     = shapes{kFixValue};
        otherwise
            error('Invalid index for fixation feature');
    end
            
    % choose same/different values for relevant trial stimulus - the 
    % ChooseStimFeatures function will ignore the bSame array for level 1
    if bCorrect
        bSame   = switch2(blockType, {1, 2}, nan(1,4), ...           
                                     {3, 5}, bOneSame(randi(length(bOneSame)), :), ...
                                     {4, 6}, bThreeSame(randi(length(bThreeSame)), :));
    else
        bSame   = switch2(blockType, {1, 2}, nan(1,4), ...
                                     {3, 5}, bNotOneSame(randi(length(bNotOneSame)), :), ...
                                     {4, 6}, bNotThreeSame(randi(length(bNotThreeSame)), :));
    end
    
    % choose stimuli
    [trialColors, trialNumbers, trialOrientations, trialShapes] = ra.ChooseStimFeatures(bSame, blockType, bCorrect, kFixFeature, kFixValue);
end
%------------------------------------------------------------------------------%
end