function [stimColors, stimNumbers, stimOrientations, stimShapes] = ChooseStimFeatures(ra, bSame, blockType, bCorrect, fixFeat, fixVal)
% RelAbs.ChooseStimFeatures
%
% Description: choose stimulus features for a RelAbs trial
%
% Syntax: ra.ChooseStimFeature(bSame)
%
% In:
%   bSame           - a vector containing features (level 2) or 
%                       dimensions (level 3) along  which the 
%                       stimuli should be the same (these are boolean 
%                       values, in alphabetical order: color, number, 
%                       orientation, shape). This variable is ignored for 
%                       level 1 trials (i.e. blockType 1 or 2) 
%   blockType       - the block type. Odd numbers are 1S, evens are 1D
%                       (1=1S, 2=1D, 3=2S, 4=2D, 5=3S, 6=3D)
%   bCorrect        - a boolean specifying whether the answer for the
%                       current trial should be correct (1) or 
%                       incorrect (0)
%   fixFeat         - an integer (1:4) used to let this function know which
%                       feature is being drawn at fixation in the trial.
%                       This variable is used for stimulus selection in
%                       level 1, but ignored in levels 2 and 3.
%   fixVal          - an integer (1 or 2) used to let this function know
%                       which value of the fixFeat variable (e.g. 'light' or 
%                       'dark' for color) is being drawn at fixation
%                       on this trial. Similar to fixFeat, it is used in
%                       level 1 and ignored in levels 2 and 3.
%
% Out:
%   stimColors      - a cell array of RGB values for a stimulus set
%   stimNumbers     - a cell array of strings containing the number of
%                       units for a stimulus set
%   stimOrientations- a cell array of strings containing the orientations 
%                       for a stimulus set
%   stimShapes      - a cell array of strings containing the shapes for 
%                       a stimulus set
%
% Notes:            - the matching output values and dimensions are always
%                       first in the output arguments, followed by
%                       non-matching values and dimensions
%                       This is a bit confusing, so here are some examples:
%                        1. if blockType is 1, bCorrect is 1, fixFeature 
%                           is 1 (color), and fixVal is 1 ('light'),
%                           then the first item in stimColors will match
%                           fixation (i.e. will be light grey)
%                        2. if blockType is 2 and the other arguments are
%                           the same as in example 1, then stimColors(1:3) 
%                           will match fixation
%                       
% ToDo:    
%                   - 
%
% Updated: 12-15-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

% parse the arguments
% [opt]   = ParseArgs(varargin);

% get feature values from RA.Param
colors          = struct2cell(RA.Param('stim_color'));
numbers         = struct2cell(RA.Param('stim_number'));
orientations    = fieldnames(RA.Param('stim_orient'));
shapes          = fieldnames(RA.Param('stim_shape'));

% create normal and flipped array for indexing, values chosen randomly
[stimColors,stimNumbers,stimOrientations,stimShapes] = deal(cell(1,4));
iFeatureFlip    = [];
% nFeature        = length(colors);
% iFeature        = randi(nFeature, [1,4]);
% iFeatureFlip    = Replace(iFeature, [1, 2], [2, 1]);

    switch blockType
        case {1, 2}
            % if called for level 1, choose all random features 
            % (don't use bSame)
            [s1Color, s1Number, s1Orientation, s1Shape] = randFeatures();
            [s2Color, s2Number, s2Orientation, s2Shape] = randFeatures();
            [s3Color, s3Number, s3Orientation, s3Shape] = randFeatures();
            [s4Color, s4Number, s4Orientation, s4Shape] = randFeatures();
        case {3,4}
            % choose feature values for 2 framed stimuli with bSame 
            % mapping and other 2 randomly        
            [s1Color, s1Number, s1Orientation, s1Shape] = randFeatures();
            [s2Color, s2Number, s2Orientation, s2Shape] = mapFeatures(bSame, {s1Color, s1Number, s1Orientation, s1Shape});
            [s3Color, s3Number, s3Orientation, s3Shape] = randFeatures();
            [s4Color, s4Number, s4Orientation, s4Shape] = randFeatures();
        case {5, 6}
            % choose feature values for framed and unframed stimuli according
            % to bSame mapping for match/mismatch between pairs
            [s1Color, s1Number, s1Orientation, s1Shape] = randFeatures();
            [s2Color, s2Number, s2Orientation, s2Shape] = randFeatures();
            bSame2 = [isequal(s1Color, s2Color), s1Number == s2Number, strcmp(s1Orientation, s2Orientation), strcmp(s1Shape, s2Shape)];
            bSame3 = bSame == bSame2;
            [s3Color, s3Number, s3Orientation, s3Shape] = randFeatures();
            [s4Color, s4Number, s4Orientation, s4Shape] = mapFeatures(bSame3, {s3Color, s3Number, s3Orientation, s3Shape});

        otherwise
            % should never get here
            error(['invalid value (' num2str(blockType) ') for blockType']);
    end

    for k = 1:4
        stimColors{k}       = eval(['s' num2str(k) 'Color']);
        stimNumbers{k}      = eval(['s' num2str(k) 'Number']);
        stimOrientations{k} = eval(['s' num2str(k) 'Orientation']);
        stimShapes{k}       = eval(['s' num2str(k) 'Shape']);
    end
    
    if ismember(blockType, [1 2])
        if bCorrect
            nSame = switch2(blockType, 1, 1, 2, 3);
        else
            nSame = switch2(blockType, 1, randFrom([0 2 3 4]), 2, randFrom([0 1 2 4]));
        end
        
        notFixVal = switch2(fixVal, 1, 2, 2, 1);
        
        switch fixFeat
            case 1
                stimColors(1:nSame)             = repmat(colors(fixVal), 1, nSame);
                stimColors(nSame+1:end)         = repmat(colors(notFixVal), 1, 4-nSame); 
            case 2
                stimNumbers(1:nSame)            = repmat(numbers(fixVal), 1, nSame);
                stimNumbers(nSame+1:end)        = repmat(numbers(notFixVal), 1, 4-nSame);
            case 3
                stimOrientations(1:nSame)       = repmat(orientations(fixVal), 1, nSame);
                stimOrientations(nSame+1:end)   = repmat(orientations(notFixVal), 1, 4-nSame);
            case 4
                stimShapes(1:nSame)             = repmat(shapes(fixVal), 1, nSame);
                stimShapes(nSame+1:end)         = repmat(shapes(notFixVal), 1, 4-nSame);
            otherwise
                error(['fixFeat is ' num2str(fixFeat) ', but should be an integer from 1 to 4']);
        end
    end

%------------------------------------------------------------------------------%
function [colorOut, numberOut, orientationOut, shapeOut] = randFeatures()
    % choose indices randomly
    nFeature        = length(colors);
    iFeature        = randi(nFeature, [1,4]);
    iFeatureFlip    = mod(iFeature, 2) + 1;
    
    % assign feature values to output
    colorOut       = colors{iFeature(1)};
    numberOut      = numbers{iFeature(2)};
    orientationOut = orientations{iFeature(3)};
    shapeOut       = shapes{iFeature(4)};
end
%------------------------------------------------------------------------------%
function [colorOut, numberOut, orientationOut, shapeOut] = mapFeatures(bSameN, cBaseSet)
    % choose a set of feature values in a way that maps to a given set via
    % a bSame array
    if bSameN(1)
        colorOut = cBaseSet{1};
    else
        colorOut = colors{iFeatureFlip(1)};
    end

    if bSameN(2)
        numberOut = cBaseSet{2};
    else
        numberOut = numbers{iFeatureFlip(2)};
    end

    if bSameN(3)
        orientationOut = cBaseSet{3};
    else
        orientationOut = orientations{iFeatureFlip(3)};
    end

    if bSameN(4)
        shapeOut = cBaseSet{4};
    else
        shapeOut = shapes{iFeatureFlip(4)};
    end
end
%------------------------------------------------------------------------------%
end