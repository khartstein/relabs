function [blockRes, loopTiming] = TrialLoop(ra, blockType)
% RelAbs.TrialLoop
% 
% Description:	run a loop of RelAbs trials
% 
% Syntax:	res = ra.TrialLoop(blockType)
% 
% In:
%	blockType   - the block type. Odd numbers are 1S, evens are 1D
%                   (1=1S, 2=1D, 3=2S, 4=2D, 5=3S, 6=3D)
%
% Out:
% 	blockRes    - a struct of results for the current block
%   loopTiming  - a struct of timing information from 
%                   ra.Experiment.Sequence.Loop
%
% ToDo:         
%               - blipping fixation task
%
% Updated: 11-03-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

tLoopStart = PTB.Now;

% get feature values from RA.Param
colors          = struct2cell(RA.Param('stim_color'));
numbers         = struct2cell(RA.Param('stim_number'));
orientations    = fieldnames(RA.Param('stim_orient'));
shapes          = fieldnames(RA.Param('stim_shape'));

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

% timing info
t               = RA.Param('time');
maxLoopTime     = t.trialloop;

% block, run, and trial info
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

% stimulus to quadrant orders
stimOrders      = unique(perms(1:4), 'rows');

% each row is a possible SD array, each cateogry (bSameOne, bSame2, etc.) 
% has the same number of rows (least common multiple is 12)
% SHOULD ALL INCORRECT ANSWERS BE EQUALLY LIKELY? no

% Not equally likely:
bNotOneSame     = [bTwoSame; bThreeSame; bAllSame; bNoneSame];
bNotThreeSame   = [bOneSame; bTwoSame; bAllSame; bNoneSame];

% Equally likely:
% bNotOneSame     = [repmat(bTwoSame, 2, []);     ...
%                    repmat(bThreeSame, 3, []);   ...
%                    repmat(bAllSame, 12, []);    ... 
%                    repmat(bNoneSame, 12, [])];
% bNotThreeSame   = [repmat(bOneSame, 3, []);     ...
%                    repmat(bTwoSame, 2, []);     ...
%                    repmat(bAllSame, 12, []);    ... 
%                    repmat(bNoneSame, 12, [])];
% bAllPossibleSD  = [bOneSame; bTwoSame; bThreeSame; bAllSame; bNoneSame];
                   

% initialize some things
blockRes        = [];
kTrial          = 0;
nCorrect        = 0;
[trialColors,trialNumbers,trialOrientations,trialShapes] = deal(cell(1,4));

% because fake scanner
tUnit           = 'ms';
maxLoopTime     = maxLoopTime*t.tr;

% loop through trials until maxLoopTime is reached
[tStart, tEnd, tLoop, bAbort, kResponse, tResponse] = ra.Experiment.Sequence.Loop(@DoTrial, @DoNext, ...
            'tunit'         ,       tUnit           , ...
            'tbase'         ,       'sequence'      , ...
            'fwait'         ,       @loopWait       , ...
            'return'        ,       't');    
        
%             'tend'          ,       maxLoopTime     , ...
        
% save loop timing for output
loopTiming = struct('tStart', tStart, 'tEnd', tEnd, 'tLoop', tLoop, 'bAbort', bAbort);

% blank the screen
ra.Experiment.Show.Blank('fixation', true);
ra.Experiment.Window.Flip;

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum, stimPos)
    % find screen coordinates
    center = switch2(stimPos, 1, [stimOff, -stimOff], 2, [-stimOff, -stimOff], ...
            3, [-stimOff, stimOff], 4, [stimOff, stimOff]);
    smallOffset = switch2(trialOrientations{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(trialOrientations{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    
    % find locoation and rotation (i.e. square/diamond)
    bitLoc = {center-largeOffset, center-smallOffset, center+smallOffset, center+largeOffset};
    bitRot = switch2(trialShapes{stimNum}, 'square', 0, 'diamond', 45);
    
    % draw stimuls
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{2}, bitRot);
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{3}, bitRot);
    if trialNumbers{stimNum} == 4
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{1}, bitRot);
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{4}, bitRot);    
    end
    
    % draw frame - frames are drawn for correct stimuli, but in random
    % positions (the quadrants result from stimOrder in DoTrial
    if ismember(stimNum, [1 2])
        ra.Experiment.Show.Rectangle(frameColor, frameSize, center, 'border', true)
    end
end
%------------------------------------------------------------------------------%
function [NaN] = DoTrial(tNow, NaN)
    kTrial      = kTrial+1;
    ra.Experiment.AddLog(['trial ' num2str(kTrial)]);
    
    % get trial info
    bCorrect        = trialInfo.bcorrect(kRun, kBlock, kTrial);
    numSameCorrect  = switch2(blockType, {1, 3, 5}, 1, {2, 4, 6}, 3);
    % frameType       = trialInfo.frametype(kRun, kBlock, kTrial);
    kFixFeature     = trialInfo.fixfeature(kRun, kBlock, kTrial);           % will be an integer 1:4
    kFixValue       = randi(2);
    
    switch kFixFeature
        case 1
            % color
            val     = colors{kFixValue};
            ra.Experiment.Show.Circle(val, 0.25, [0,0])
        case 2
            % number
            val     = num2str(numbers{kFixValue});
            ra.Experiment.Show.Text(['<color: black><size: 0.5>' val '</color></size>'], [0,0]);
        case 3
            % orientation
            val     = switch2(orientations{kFixValue}, 'horizontal', [0.5, 0.125], 'vertical', [0.125, 0.5]);
            ra.Experiment.Show.Rectangle('black', val, [0, 0]);
        case 4
            % shape
            val     = shapes{kFixValue};
            if strcmpi(val, 'square') 
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0]);
            elseif strcmpi(val, 'diamond')
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0], 45);
            end
        otherwise
            error('Invalid index for fixation feature');
    end
            
    % choose same/different values for relevant trial stimulus - the 
    % ChooseStimFeatures function will ignore the bSame array for level 1
    if bCorrect
        bSame   = switch2(blockType, {1, 2}, zeros(1,4), ...           
                                     {3, 5}, bOneSame(randi(length(bOneSame)), :), ...
                                     {4, 6}, bThreeSame(randi(length(bThreeSame)), :));
    else
        bSame   = switch2(blockType, {1, 2}, zeros(1,4), ...
                                     {3, 5}, bNotOneSame(randi(length(bNotOneSame)), :), ...
                                     {4, 6}, bNotThreeSame(randi(length(bNotThreeSame)), :));
    end
    
    % choose stimuli
    [trialColors, trialNumbers, trialOrientations, trialShapes] = ra.ChooseStimFeatures(bSame, blockType, bCorrect, kFixFeature, kFixValue);

    % choose which stimuli go in which quadrant
    stimOrder = stimOrders(randi(length(stimOrders)), :);
    
    % draw the stimuli
    for k = 1:4
        DrawSet(k, stimOrder(k));
    end
    
    % initialize kResponse and flip
    kResponse = [];
    tFlip = ra.Experiment.Window.Flip;

    % get response (ok to do this with PTB.Now or use
    % ra.Experiment.Scanner.TR() ?
    while isempty(kResponse) && PTB.Now - tLoopStart < maxLoopTime - 1
        [~,~,tResponse,kResponse]	= ra.Experiment.Input.DownOnce('response');
    end
    
    % determine whether answer is correct
    if ismember(kResponse, kButtYes)
        sResponse = 'Yes';
    elseif ismember(kResponse, kButtNo)
        sResponse = 'No';
    elseif isempty(kResponse)
        sResponse = 'No response';
        kResponse = NaN;
    else
        sResponse = 'Incorrect Key';
    end
    
    % record trial results
    trialRes.level          = blockType;
    trialRes.trial          = kTrial;
    trialRes.color          = trialColors;
    trialRes.number         = trialNumbers;
    trialRes.orientation    = trialOrientations;
    trialRes.shape          = trialShapes;
    trialRes.fixValue       = val; 
    trialRes.response       = sResponse;
    trialRes.kResponse      = kResponse;
    trialRes.numSame        = sum(bSame);
    trialRes.numSameCorrect = numSameCorrect;
    trialRes.rt             = tResponse - tFlip; 
    trialRes.correct        = (bCorrect && ismember(kResponse,kButtYes))...
                            ||(~bCorrect && ismember(kResponse,kButtNo));

    if isempty(blockRes)
        blockRes        = trialRes;
    else
        blockRes(end+1) = trialRes;
    end 
    
    if maxLoopTime - tNow > 1
        DoFeedback;
    else
        ra.Experiment.Show.Blank('fixation', true);
        ra.Experiment.Window.Flip;
    end
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
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
    WaitSecs(0.9835); % Do this without WaitSecs?
end 
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = DoNext(tNow)
    % abort if current time greater than allowed
    if tNow > maxLoopTime
        bAbort      = true;
        bContinue   = false;
    elseif isempty(blockRes(end).kResponse)
        bAbort = false;
        bContinue = false;
    else
        bAbort = false;
        bContinue = true;
    end
end
%------------------------------------------------------------------------------%
function [bAbort] = loopWait(tNow, NaN)
    % FIX - this function doesn't get called even though it is supplied as
    % as the fWait function in ra.Sequence.Loop
    
    % abort if current time greater than allowed
    if tNow > maxLoopTime
        bAbort = true;
    else
        bAbort = false;
    end

% 	[~,~,~,kResponse]   = ra.Experiment.Input.DownOnce('response');
% 	
% 	tResponse           = conditional(isempty(kResponse),[],tNow);
% 	
% 	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end
%------------------------------------------------------------------------------%
end