function [color, number, orientation, shape] = ChooseStimFeatures(ra, bSame)
% RelAbs.ChooseStimFeatures
%
% Description: choose features for a stimulus in RelAbs experiment
%
% Syntax: ra.ChooseStimFeature(bSame)
%
% In:
%   bSame           - a vector containing dimension(s) along  which the 
%                       stimuli should be the same (these are boolean 
%                       values, in alphabetical order: color, number, 
%                       orientation, shape)
%
% Out:
%   color           - a cell of 2 strings containing the colors for
%                       a stimulus set
%   number          - a cell of 2 strings containing the number of
%                       units for a stimulus set
%   orientation     - a cell of 2 strings containing the orientations 
%                       for a stimulus set
%   shape           - a cell of 2 strings containing the shapes for 
%                       a stimulus set
%
% Notes:    - Only implemented for features with 2 values (call twice for
%               levels 3 and 4)
%
% ToDo:    
%           - Maybe choose stimuli using blockdesign instead of randomly
%
% Updated: 08-03-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

colors      = fieldnames(RA.Param('stim_color'));
numbers     = struct2cell(RA.Param('stim_number'));
orientations= fieldnames(RA.Param('stim_orient'));
shapes      = fieldnames(RA.Param('stim_shape'));

[color,number,orientation,shape] = deal(cell(1,2));
nFeature = length(colors);
iFeature = randi(nFeature, [1,4]);
iFeatureFlip = Replace(iFeature, [1, 2], [2, 1]);

% choose feature values for first stimulus
color{1}        = colors{iFeature(1)};
number{1}       = numbers{iFeature(2)};
orientation{1}  = orientations{iFeature(3)};
shape{1}        = shapes{iFeature(4)};

% choose feature values for second stimulus
if bSame(1)
    color{2} = color{1};
else
    color{2} = colors{iFeatureFlip(1)};
end

if bSame(2)
    number{2} = number{1};
else
    number{2} = numbers{iFeatureFlip(2)};
end

if bSame(3)
    orientation{2} = orientation{1};
else
    orientation{2} = orientations{iFeatureFlip(3)};
end

if bSame(4)
    shape{2} = shape{1};
else
    shape{2} = shapes{iFeatureFlip(4)};
end

end