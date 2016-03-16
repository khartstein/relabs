function [] = ShowStim(ra, stimOrder, colorList, numberList, orientationList, shapeList, varargin)
% RelAbs.ShowStim
%
% Description: Show a single trial in the RelAbs experiment 
% 
% Syntax:	ra.ShowStim;
% 
% In:
%   <options>
%   window      - (main) the window on which to show the prompt
% Out:
% 	
% ToDo:         -
%
% Updated: 02-17-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt = ParseArgs(varargin, 'window', 'main');

% screen locations
stimOff         = RA.Param('stim_size' , 'offset');
squareSide      = RA.Param('stim_size' , 'sqside');
smallXOff       = RA.Param('smallXOffset');
largeXOff       = RA.Param('largeXOffset');
smallYOff       = RA.Param('smallYOffset');
largeYOff       = RA.Param('largeYOffset');

% info for frames
frameColor      = RA.Param('color', 'frame');
frameSize       = RA.Param('framesize');

% draw the stimuli
for k = 1:4
    DrawSet(k, stimOrder(k));
end

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum, stimPos)
    % find screen coordinates
    center = switch2(stimPos, 1, [stimOff, -stimOff], 2, [-stimOff, -stimOff], ...
            3, [-stimOff, stimOff], 4, [stimOff, stimOff]);
    smallOffset = switch2(orientationList{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(orientationList{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    
    % find location and shape (i.e. rotation of square for square/diamond)
    bitLoc = {center-largeOffset, center-smallOffset, center+smallOffset, center+largeOffset};
    bitRot = switch2(shapeList{stimNum}, 'square', 0, 'diamond', 45);
    
    % draw stimulus
    ra.Experiment.Show.Rectangle(colorList{stimNum}, squareSide, bitLoc{2}, bitRot, 'window', opt.window);
    ra.Experiment.Show.Rectangle(colorList{stimNum}, squareSide, bitLoc{3}, bitRot, 'window', opt.window);
    if numberList{stimNum} == 4
        ra.Experiment.Show.Rectangle(colorList{stimNum}, squareSide, bitLoc{1}, bitRot, 'window', opt.window);
        ra.Experiment.Show.Rectangle(colorList{stimNum}, squareSide, bitLoc{4}, bitRot, 'window', opt.window);    
    end
    
    % draw frame - frames are drawn for correct stimuli, but in random
    % positions (the quadrants result from stimOrder in DoTrial)
    if ismember(stimNum, [1 2])
        ra.Experiment.Show.Rectangle(frameColor, frameSize, center, 'window', opt.window, 'border', true)
    end
end
%------------------------------------------------------------------------------%
end
