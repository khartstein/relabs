function [color, number, orientation, shape] = ChooseStimFeatures(ra)
% RelAbs.ChooseStimFeatures
%
% Description: choose features for a stimulus in RelAbs experiment
%
% Syntax: ra.ChooseStimFeature
%
% ToDo: Change for RelAbs
%
% Updated: 07-23-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

colors      = fieldnames(RA.Param('stim_color'));
numbers     = fieldnames(RA.Param('stim_number'));
orientations= fieldnames(RA.Param('stim_orient'));
shapes      = fieldnames(Ra.Param('stim_shape'));



sameThing = randi(2);
switch sameThing
    case 1 % same shape and color
        shapeInd = randi(2);
        colorInd = randi(2);
        color = colors{colorInd};
        base_rot = shape_rot{shapeInd};
        targ_color = color;
        targ_rot = base_rot;
    case 2 % different
        howDifferent = randi(3);
        switch howDifferent
            case 1 % different shape
                shapeInd = randperm(2);
                colorInd = randi(2);
                base_rot = shape_rot{shapeInd(1)};
                targ_rot = shape_rot{shapeInd(2)};
                color = colors{colorInd};
                targ_color = colors{colorInd};
            case 2 % different color
                shapeInd = randi(2);
                colorInd = randperm(2);
                base_rot = shape_rot{shapeInd};
                targ_rot = base_rot;
                color = colors{colorInd(1)};
                targ_color = colors{colorInd(2)};
            case 3 % different shape and different color
                shapeInd = randperm(2);
                colorInd = randperm(2);
                base_rot = shape_rot{shapeInd(1)};
                targ_rot = shape_rot{shapeInd(2)};
                color = colors{colorInd(1)};
                targ_color = colors{colorInd(2)};
        end
end

end