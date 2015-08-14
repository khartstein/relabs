function res = Trial(ra, blockType, varargin)
% RelAbs.Trial
% 
% Description:	run a single RelAbs trial
% 
% Syntax:	res = ra.Trial(blockType)
% 
% In:
%	blockType   - The type of block to pull a trial from.
%                   (1=1s,2=1d,3=2s,4=2d,5=3s,6=3d,7=4s,8=4d)
%
% Out:
% 	res	- a struct of results
%
% Updated: 08-05-2015

% [dummy] = ParseArgs(varargin, []);

topCenter       = RA.Param('screenlocs' , 'topcenter');
bottomCenter    = RA.Param('screenlocs' , 'bottomcenter');
radius          = RA.Param('stim_size'  , 'circradius');
squareSide      = RA.Param('stim_size'  , 'sqside');
smallXOff       = RA.Param('smallXOffset');
largeXOff       = RA.Param('largeXOffset');
smallYOff       = RA.Param('smallYOffset');
largeYOff       = RA.Param('largeYOffset');

% find correct/incorrect keys
kButtYes = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo = cell2mat(ra.Experiment.Input.Get('no'));

% same/different arrays
bOneSame    = unique(perms([1 0 0 0]), 'rows');
bTwoSame    = unique(perms([0 0 1 1]), 'rows');
bThreeSame  = unique(perms([0 1 1 1]), 'rows');
bAllSame    = [1 1 1 1];
bNoneSame   = [0 0 0 0];

% random numSame
numSame = randi(4);
numSameYes = switch2(blockType,{1, 3, 5, 7}, 1, {2, 4, 6, 8}, 3);

    % choose stimuli for the trial
    bSame1 = switch2(numSame, 0, bNoneSame                          , ...  
                        1, bOneSame(randi(length(bOneSame)),:)      , ...
                        2, bTwoSame(randi(length(bTwoSame)),:)      , ...
                        3, bThreeSame(randi(length(bThreeSame)),:)  , ...
                        4, bAllSame);
                    
    if ismember(blockType, [5 6 7 8])
        bSame2 = zeros(1, length(bSame1));
        iChange = randFrom(1:4, numSame); 
        for n = 1:length(bSame1)
            if ismember(n, iChange) && bSame1(n) == 0
                bSame2(n) = 1;
            elseif ismember(n, iChange) && bSame1(n) == 1
                bSame2(n) = 0;
            else
                bSame2(n) = bSame1(n); 
            end
        end
    end
    
    % Choose features and show the stimulus
    [color, number, orientation, shape] = ra.ChooseStimFeatures(bSame1);
    if ismember(blockType, [7 8])
        [color2, number2, orientation2, shape2] = ra.ChooseStimFeatures(bSame2);
    end
 
    % draw stimulus
    DrawStimulus;
    
    % flip stimulus and start timer
    bResponse = false;
    tTrialStart = ra.Experiment.Window.Flip;
    	
    % wait for response, then flip the blank screen
    while ~bResponse        
        [bResponse, ~, tRes, kPressed] = ra.Experiment.Input.DownOnce('response');
    end
    
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip;
    
    if kPressed == kButtYes
        sResponse = 'Yes';
    elseif kPressed == kButtNo
        sResponse = 'No';
    else 
        sResponse = 'Incorrect Key';
    end
    
    % record trial results
    res.level        = blockType;
    res.color        = color;
    res.number       = number;
    res.orientation  = orientation;
    res.shape        = shape;
    res.response     = sResponse;
    res.rt           = tRes-tTrialStart;
    res.numSame      = numSame;
    res.correct      = (numSameYes == numSame && ismember(kPressed,kButtYes))...
                        ||(numSameYes ~= numSame && ismember(kPressed,kButtNo));
    
    % feedback
    DoFeedback;    

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum)
    if ismember(blockType, [1 2 3 4])
        center = switch2(stimNum, 1, topCenter, 2, bottomCenter, [0 0]);
    elseif ismember(blockType, [5 6 7 8])
        center = switch2(stimNum, 1, topCenter - [6 0], 2, bottomCenter - [6 0], ...
            3, topCenter + [6 0], 4, bottomCenter + [6 0]);
    end
    smallOffset = switch2(orientation{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(orientation{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    bitLoc = {center-largeOffset, center-smallOffset,center+smallOffset, center+largeOffset};
    if strcmpi(shape{stimNum},'rectangle')
        ra.Experiment.Show.Rectangle(color{stimNum}, squareSide, bitLoc{2});
        ra.Experiment.Show.Rectangle(color{stimNum}, squareSide, bitLoc{3});
            if number{stimNum} == 4
                ra.Experiment.Show.Rectangle(color{stimNum}, squareSide, bitLoc{1});
                ra.Experiment.Show.Rectangle(color{stimNum}, squareSide, bitLoc{4});    
            end
    elseif strcmpi(shape{stimNum}, 'circle')
        ra.Experiment.Show.Circle(color{stimNum}, radius, bitLoc{2});
        ra.Experiment.Show.Circle(color{stimNum}, radius, bitLoc{3});
            if number{stimNum} == 4
                ra.Experiment.Show.Circle(color{stimNum}, radius, bitLoc{1});
                ra.Experiment.Show.Circle(color{stimNum}, radius, bitLoc{4});
            end
    else
            error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL1Box(stimNum)
    oriDims = switch2(orientation{stimNum}, 'vertical', [.125*squareSide squareSide], ...
                'horizontal', [squareSide, .125*squareSide]);
    iLoc = randperm(4);
    boxLocs = {bottomCenter-largeXOff, bottomCenter-smallXOff, ...
        bottomCenter+smallXOff, bottomCenter+largeXOff};
    % color
    ra.Experiment.Show.Rectangle(color{stimNum}, squareSide, boxLocs{iLoc(1)});
    % number
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>'...
        num2str(number{stimNum}) '</color></style></size>'], ...
        (boxLocs{iLoc(4)} + [0 .5]));
    % orientation
    ra.Experiment.Show.Rectangle('black', oriDims, boxLocs{iLoc(2)});
    % shape 
    if strcmpi(shape{stimNum}, 'rectangle')
        ra.Experiment.Show.Rectangle('black', squareSide, boxLocs{iLoc(3)}); 
    elseif strcmpi(shape{stimNum}, 'circle')
        ra.Experiment.Show.Circle('black', radius, boxLocs{iLoc(3)});
    else
        error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL3Box()
    boxLocs = {[6 0]-largeXOff, [6 0]-smallXOff, ...
        [6 0]+smallXOff, [6 0]+largeXOff};
    SD = Replace(bSame2, [0 1], ['D' 'S']);
    sLabels = ['C' '#' 'O' 'S'];
    for loc = 1:4
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>' char(SD(loc)) '</color></style></size>'], ...
        (boxLocs{loc} + [0 1.5]));
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:red>' sLabels(loc) '</color></style></size>'], ...
        (boxLocs{loc} - [0 0.5]));
    end
end
%------------------------------------------------------------------------------%
function [] = DrawStimulus()
    ra.Experiment.Show.Fixation;
    switch blockType
        case {1 2}
            DrawSet(1);
            DrawL1Box(2);
        case {3 4}
            DrawSet(1);
            DrawSet(2);
        case {5 6}
            DrawSet(1);
            DrawSet(2);
            DrawL3Box();
        case {7 8}
            color = [color, color2];
            number = [number, number2];
            orientation = [orientation, orientation2];
            shape = [shape, shape2];
            for k = 1:4
                DrawSet(k);
            end
        otherwise
            error('blockType must be an integer between 1 and 8!');
    end    
end
%------------------------------------------------------------------------------%
function [] = DoFeedback()
    
    % add log
    strCorrect	= conditional(res.correct,'y','n');
    ra.Experiment.AddLog(['feedback (' strCorrect ')']);
	
	% get and format string for feedback
    if res.correct
        strFeedback	= 'Yes!';
        strColor	= 'green';
    else
        strFeedback	= 'No!';
        strColor	= 'red';
    end
	
	strText	= ['<color:' strColor '>' strFeedback '</color>']; 
	
    % show feedback
	ra.Experiment.Show.Text(strText);
    ra.Experiment.Window.Flip;
    WaitSecs(1.0);
end
%------------------------------------------------------------------------------%
end
