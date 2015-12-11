function [blockRes, loopTiming] = Trial(ra, blockType)
% RelAbs.Trial
% 
% Description:	run a single RelAbs trial
% 
% Syntax:	res = ra.Trial(blockType, kTrial)
% 
% In:
%	blockType   - The type of block to pull a trial from.
%                   (1=1s,2=1d,3=2s,4=2d,5=3s,6=3d,7=4s,8=4d)
%
% Out:
% 	res         - a struct of results
%
% ToDo:         - 
%
% Updated: 09-04-2014

topCenter       = RA.Param('screenlocs' , 'topcenter');
bottomCenter    = RA.Param('screenlocs' , 'bottomcenter');
radius          = RA.Param('stim_size'  , 'circradius');
squareSide      = RA.Param('stim_size'  , 'sqside');
smallXOff       = RA.Param('smallXOffset');
largeXOff       = RA.Param('largeXOffset');
smallYOff       = RA.Param('smallYOffset');
largeYOff       = RA.Param('largeYOffset');

% timing info
t               = RA.Param('time');
maxLoopTime     = t.tr*t.trialloop;

% block, run, and trial information
kRun            = ra.Experiment.Info.Get('ra', 'run');
kBlock          = ra.Experiment.Info.Get('ra', 'block');
trialInfo       = ra.Experiment.Info.Get('ra', 'trialinfo');

% find correct/incorrect keys
kButtYes        = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo         = cell2mat(ra.Experiment.Input.Get('no'));

% same/different arrays
bOneSame        = unique(perms([1 0 0 0]), 'rows');
bTwoSame        = unique(perms([0 0 1 1]), 'rows');
bThreeSame      = unique(perms([0 1 1 1]), 'rows');
bAllSame        = [1 1 1 1];
bNoneSame       = [0 0 0 0];

blockRes        = [];
kTrial          = 0;
nCorrect        = 0;
tUnit = 'ms';

[trialColors,trialNumbers,trialOrientations,trialShapes] = deal(cell(1,4));


% loop through trials until maxLoopTime is reached
[tStart, tEnd, tLoop, bAbort] = ra.Experiment.Sequence.Loop(@DoTrial, @DoNext, ...
            'tunit'         ,       tUnit);    

% save loop timing for output
loopTiming = struct('tStart', tStart, 'tEnd', tEnd, 'tLoop', tLoop, 'bAbort', bAbort);

% blank the screen
ra.Experiment.Show.Blank('fixation', true);
ra.Experiment.Window.Flip;            

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum, varargin)
    % handle screen coordinates
    center = switch2(stimNum, 1, topCenter - [6 0], 2, bottomCenter - [6 0], ...
            3, topCenter + [6 0], 4, bottomCenter + [6 0]);
    smallOffset = switch2(trialOrientations{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(trialOrientations{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    bitLoc = {center-largeOffset, center-smallOffset, center+smallOffset, center+largeOffset};
    
    if strcmpi(trialShapes{stimNum},'rectangle')
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{2});
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{3});
            if trialNumbers{stimNum} == 4
                ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{1});
                ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{4});    
            end
    elseif strcmpi(trialShapes{stimNum}, 'circle')
        ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{2});
        ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{3});
            if trialNumbers{stimNum} == 4
                ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{1});
                ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{4});
            end
    else
            error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL1Box(stimNum)
    oriDims = switch2(trialOrientations{stimNum}, 'vertical', [.125*squareSide squareSide], ...
                'horizontal', [squareSide, .125*squareSide]);
    iLoc = randperm(4);
    boxLocs = {bottomCenter+[0 6]-largeXOff,bottomCenter+[0 6]-smallXOff, ...
        bottomCenter+[0 6]+smallXOff, bottomCenter+[0 6]+largeXOff};
    % color
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, boxLocs{iLoc(1)});
    % number
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>'...
        num2str(trialNumbers{stimNum}) '</color></style></size>'], ...
        (boxLocs{iLoc(4)} + [0 .5]));
    % orientation
    ra.Experiment.Show.Rectangle('black', oriDims, boxLocs{iLoc(2)});
    % shape 
    if strcmpi(trialShapes{stimNum}, 'rectangle')
        ra.Experiment.Show.Rectangle('black', squareSide, boxLocs{iLoc(3)}); 
    elseif strcmpi(trialShapes{stimNum}, 'circle')
        ra.Experiment.Show.Circle('black', radius, boxLocs{iLoc(3)});
    else
        error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL3Box()
    % replace text with icons
    boxLocs = {topCenter-[0 6]-largeXOff,topCenter-[0 6]-smallXOff, ...
        topCenter-[0 6]+smallXOff, topCenter-[0 6]+largeXOff};
    SD = ['D' 'S', 'S', 'D'];
    cLabelIms = {ra.colorIcon, ra.numberIcon, ra.orientationIcon, ra.shapeIcon};
    for loc = 1:4
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>' char(SD(loc)) '</color></style></size>'], ...
        (boxLocs{loc} + [0 1.5]));
    ra.Experiment.Show.Image(cLabelIms{loc}, (boxLocs{loc} - [0 1.5]), 1.5);
    end
end
%------------------------------------------------------------------------------%
function [NaN] = DoTrial(tNow, NaN)
    kTrial      = kTrial+1;
    ra.Experiment.AddLog(['trial ' num2str(kTrial)]);
    
    % get trial info
    numSame = trialInfo.numSame(kRun, kBlock, kTrial);
    numSameYes = switch2(blockType, {1, 3, 5, 7}, 1, {2, 4, 6, 8}, 3);

    % choose stimuli for the trial
    bSame = switch2(numSame, 0, bNoneSame                           , ...  
                        1, bOneSame(randi(length(bOneSame)),:)      , ...
                        2, bTwoSame(randi(length(bTwoSame)),:)      , ...
                        3, bThreeSame(randi(length(bThreeSame)),:)  , ...
                        4, bAllSame);

    [trialColors,trialNumbers,trialOrientations,trialShapes] = ra.ChooseStimFeatures(bSame, numSame);

    % draw the stimuli
    for k = 1:4
        DrawSet(k);
    end

    % draw boxes for levels 1 and 3
    DrawL1Box(2);
    DrawL3Box();

    % initialize kResponse and flip
    kResponse = [];
    tFlip = ra.Experiment.Window.Flip;
    
    % get response
    while isempty(kResponse) && tNow < maxLoopTime
        [~,~,tResponse,kResponse]	= ra.Experiment.Input.DownOnce('response');
    end

    % determine whether answer is correct
    if ismember(kResponse, kButtYes)
        sResponse = 'Yes';
    elseif ismember(kResponse, kButtNo)
        sResponse = 'No';
    elseif isempty(kResponse)
        sResponse = 'No response';
    else
        sResponse = 'Incorrect Key';
    end
    
    % record trial results
    trialRes.level       = blockType;
    trialRes.color       = trialColors;
    trialRes.number      = trialNumbers;
    trialRes.orientation = trialOrientations;
    trialRes.shape       = trialShapes;
    trialRes.response    = sResponse;
    trialRes.kResponse   = kResponse;
    trialRes.numSame     = numSame;
    trialRes.numSameYes  = numSameYes;
    trialRes.rt          = tResponse - tFlip; 
    trialRes.correct     = (numSameYes == numSame && ismember(kResponse,kButtYes))...
                        ||(numSameYes ~= numSame && ismember(kResponse,kButtNo));

    if isempty(blockRes)
        blockRes        = trialRes;
    else
        blockRes(end+1) = trialRes;
    end
    
    DoFeedback;
end
%------------------------------------------------------------------------------%
function [] = DoFeedback()
    % add a log message
    nCorrect	= nCorrect + blockRes(end).correct;
    strCorrect	= conditional(blockRes(end).correct,'y','n');
    strTally	= [num2str(nCorrect) '/' num2str(kTrial)];
    
    ra.Experiment.AddLog(['feedback (' strCorrect ', ' strTally ')']);
	
	% get the message and change in winnings
		if blockRes(end).correct
			strFeedback	= 'Yes!';
			strColor	= 'green';
			dWinning	= RA.Param('rewardpertrial');
        else
			strFeedback	= 'No!';
			strColor	= 'red';
            dWinning	= -RA.Param('penaltypertrial');
        end
        
	% update the winnings and show feedback
    ra.reward	= max(ra.reward + dWinning, RA.Param('reward','base'));
    strText	= ['<color:' strColor '>' strFeedback ' (' StringMoney(dWinning,'sign',true) ')</color>\n\nCurrent total: ' StringMoney(ra.reward)]; 
        
	ra.Experiment.Show.Text(strText);
    ra.Experiment.Window.Flip;
    WaitSecs(1.0); % Do this without WaitSecs?
end 
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = DoNext(tNow)
    % abort if current time is greater than block time
    if tNow > maxLoopTime
        bAbort      = true;
        bContinue   = false;
    elseif isempty(blockRes(end).kResponse) % maybe need while loop instead?
        bAbort = false;
        bContinue = false;
    else
        bAbort = false;
        bContinue = true;
    end
end
%------------------------------------------------------------------------------%
end