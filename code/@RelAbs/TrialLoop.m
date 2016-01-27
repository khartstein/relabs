function [blockRes, loopTiming] = TrialLoop(ra, blockType, varargin)
% RelAbs.TrialLoop
% 
% Description:	run a loop of RelAbs trials
% 
% Syntax:	res = ra.TrialLoop(blockType, 'bPractice', false)
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
%               - 
%
% Updated: 01-27-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)
[tStart, opt] = ParseArgs(varargin, [], 'testing', false);

bPractice = isempty(tStart) && ~opt.testing;

% get feature values from RA.Param
colors          = struct2cell(RA.Param('stim_color'));
numbers         = struct2cell(RA.Param('stim_number'));
orientations    = fieldnames(RA.Param('stim_orient'));
shapes          = fieldnames(RA.Param('stim_shape'));

% get background color
backColor       = RA.Param('color', 'back');

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
maxLoopTime     = switch2(bPractice, false, t.trialloop, true, inf);

% block, run, and trial info
kRun            = ra.Experiment.Info.Get('ra', 'run');
kBlock          = ra.Experiment.Info.Get('ra', 'block');
trialInfo       = ra.Experiment.Info.Get('ra', 'trialinfo');

% blip info and texture
tBlipBlock      = ra.Experiment.Info.Get('ra', 'block_blip');
blipResTask     = ra.Experiment.Info.Get('ra', 'blipresulttask');
blipTimer       = PTB.Now;
bBlipOver       = false;
blipTime        = tBlipBlock(kRun, kBlock)*1000;
kFixFeature     = [];
kFixValue       = [];
kBlipResponse   = [];
bChangeWait     = false;

% find correct/incorrect keys
kButtYes        = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo         = cell2mat(ra.Experiment.Input.Get('no'));
kButtBlip       = cell2mat(ra.Experiment.Input.Get('blip'));

% same/different arrays
bOneSame        = unique(perms([1 0 0 0]), 'rows');
bTwoSame        = unique(perms([0 0 1 1]), 'rows');
bThreeSame      = unique(perms([0 1 1 1]), 'rows');
bAllSame        = [1 1 1 1];
bNoneSame       = [0 0 0 0];

% stimulus to quadrant orders
stimOrders      = unique(perms(1:4), 'rows');

% bSame possibilities for incorrect answers
bNotOneSame     = [bTwoSame; bThreeSame; bAllSame; bNoneSame];
bNotThreeSame   = [bOneSame; bTwoSame; bAllSame; bNoneSame];

% initialize some things
blockRes        = [];
bMorePractice   = [];
kTrial          = 0;
nCorrect        = 0;
[trialColors,trialNumbers,trialOrientations,trialShapes] = deal(cell(1,4));

% if practice, use ms
if bPractice || opt.testing
    tStart		= PTB.Now;
    maxLoopTime = maxLoopTime*t.tr;
    tUnit       = 'ms';
else
    tUnit       = 'tr';
end

if bPractice
    ra.Experiment.Scanner.StartScan
end

% loop through trials until maxLoopTime is reached
[tStart, tEnd, tLoop, bAbort, kResponse, tResponse] = ra.Experiment.Sequence.Loop(@DoTrial, @DoNext, ...
            'tunit'         ,       tUnit           , ...
            'tStart'        ,       tStart          , ...
            'fwait'         ,       @loopWait       , ...
            'return'        ,       't');
        
% save loop timing for output
loopTiming = struct('tStart', tStart, 'tEnd', tEnd, 'tLoop', tLoop, 'bAbort', bAbort);

if bPractice
    ra.Experiment.Scanner.StopScan
end

% blank the screen
ra.Experiment.Show.Fixation('color', 'black');
ra.Experiment.Window.Flip;

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum, stimPos)
    % find screen coordinates
    center = switch2(stimPos, 1, [stimOff, -stimOff], 2, [-stimOff, -stimOff], ...
            3, [-stimOff, stimOff], 4, [stimOff, stimOff]);
    smallOffset = switch2(trialOrientations{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(trialOrientations{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    
    % find location and shape (i.e. rotation of square for square/diamond)
    bitLoc = {center-largeOffset, center-smallOffset, center+smallOffset, center+largeOffset};
    bitRot = switch2(trialShapes{stimNum}, 'square', 0, 'diamond', 45);
    
    % draw stimulus
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{2}, bitRot);
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{3}, bitRot);
    if trialNumbers{stimNum} == 4
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{1}, bitRot);
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{4}, bitRot);    
    end
    
    % draw frame - frames are drawn for correct stimuli, but in random
    % positions (the quadrants result from stimOrder in DoTrial)
    if ismember(stimNum, [1 2])
        ra.Experiment.Show.Rectangle(frameColor, frameSize, center, 'border', true)
    end
end
%------------------------------------------------------------------------------%
function [NaN] = DoTrial(tNow, NaN)
    kTrial      = kTrial + 1;
    ra.Experiment.AddLog(['trial ' num2str(kTrial)]);
    
    % get trial info
    bCorrect        = trialInfo.bcorrect(kRun, kBlock, kTrial);
    numSameCorrect  = switch2(blockType, {1, 3, 5}, 1, {2, 4, 6}, 3);
    % frameType       = trialInfo.frametype(kRun, kBlock, kTrial);
    kFixFeature     = trialInfo.fixfeature(kRun, kBlock, kTrial);           % will be an integer 1:4, set to 5 during feedback for blip task
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
 
    tFlip = ra.Experiment.Window.Flip2;

    % blip during task
    if PTB.Now - blipTimer > blipTime && ~bBlipOver
        DoBlip;
        tBlip = PTB.Now;
        while isempty(kBlipResponse) && PTB.Now - tBlip < 700
            [~,~,~,kBlipResponse]	= ra.Experiment.Input.DownOnce('response');
        end
        bBlipOver = true;
        
        % determine whether blip response is correct and save
        if ismember(kBlipResponse, kButtBlip)
            blipResTask(kRun, kBlock) = 1;
        elseif ~isempty(kButtBlip)
            blipResTask(kRun, kBlock) = 9;
        else
            blipResTask(kRun, kBlock) = 0;
        end
        ra.Experiment.Info.Set('ra', 'blipresulttask', blipResTask);
    end
    
    ra.Experiment.Show.Blank('fixation', false);
    
    kResponse = [];
    while isempty(kResponse) && PTB.Now - tStart < maxLoopTime - 1             % this should probably be done in the fWait function
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
        if bPractice
            yn              = ra.Experiment.Show.Prompt('Again?','choice',{'y','n'});
            bMorePractice	= isequal(yn,'y');
        end
    else
        ra.Experiment.Show.Fixation('color', 'black');
        ra.Experiment.Window.Flip;
    end
end
%------------------------------------------------------------------------------%
function [] = DoFeedback()
    kFixFeature = 5;
    
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
    if ~bPractice
        ra.reward	= max(ra.reward + dWinning, RA.Param('reward','base'));
        strText	= ['<color:' strColor '>' strFeedback ' (' StringMoney(dWinning,'sign',true) ')</color>\n\nCurrent total: ' StringMoney(ra.reward)]; 
        ra.Experiment.Show.Fixation('color', 'black');
    else
        strText	= ['<color:' strColor '>' strFeedback '</color>']; 
    end
    
    if isnan(kResponse)
        ra.Experiment.Show.Fixation('color', 'black');
    else
        ra.Experiment.Show.Text(strText);
    end
    
    ra.Experiment.Window.Flip2;
    
    % blip during feedback
    if PTB.Now - blipTimer > blipTime && ~bBlipOver
        DoBlip;
        tBlip = PTB.Now;
        while isempty(kBlipResponse) && PTB.Now - tBlip < 700
            [~,~,~,kBlipResponse]	= ra.Experiment.Input.DownOnce('response');
        end
        bBlipOver = true;
        bChangeWait = true;
        
        % determine whether blip response is correct and save
        if ismember(kBlipResponse, kButtBlip)
            blipResTask(kRun, kBlock) = 1;
        elseif isempty(kButtBlip)
            blipResTask(kRun, kBlock) = 9;
        else
            blipResTask(kRun, kBlock) = 0;
        end
        ra.Experiment.Info.Set('ra', 'blipresulttask', blipResTask);        
    end
    
    ra.Experiment.Show.Blank('fixation', false);
    
    
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
    if bChangeWait
        WaitSecs(1.0 - (PTB.Now - tBlip)/1000); % Do this without WaitSecs
        bChangeWait = false;
    elseif isnan(kResponse)
        % don't wait
    else
        WaitSecs(0.96);
    end
end 
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = DoNext(tNow)
    % abort if current time greater than allowed
    if bPractice && ~bMorePractice
        bAbort      = true;
        bContinue   = false;
    elseif tNow > maxLoopTime
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
function [] = DoBlip()

    % prepare to redraw whatever is at fixation
    switch kFixFeature
        case 1
            % color
            val     = colors{kFixValue};
            fixArgs = {'Circle', val, 0.25, [0,0]};
        case 2
            % number
            val     = num2str(numbers{kFixValue});
            fixArgs = {'Text', ['<color: black><size: 0.5>' val '</color></size>'], [0,0]};
        case 3
            % orientation
            val     = switch2(orientations{kFixValue}, 'horizontal', [0.5, 0.125], 'vertical', [0.125, 0.5]);
            fixArgs = {'Rectangle', 'black', val, [0, 0]};
        case 4
            % shape
            val     = shapes{kFixValue};
            if strcmpi(val, 'square') 
                fixArgs = {'Rectangle', 'black', 0.25, [0,0]};
            elseif strcmpi(val, 'diamond')
                fixArgs = {'Rectangle', 'black', 0.25, [0,0], 45};
            end
        case 5
            % fixation dot
            fixArgs = {'Fixation', 'color', 'black'};
        otherwise
            error('Invalid index for fixation feature');
    end

    % do fixation blip
    tSeq = cumsum([0.250 0.001])*1000;
    ra.Experiment.Show.Sequence2({{'Rectangle', backColor, 1.0, [0,0]},      ...
                                 fixArgs}, tSeq, 'tunit', 'ms', 'tbase',      ...
                                'sequence', 'fixation', false);                        
                        
end
%------------------------------------------------------------------------------%
function [bAbort] = loopWait(tNow, tNext)
    % THIS ISN'T BEING USED, EVEN THOUGH IT IS SUPPLIED AS THE FWAIT
    % FUNCTION FOR THE LOOP
    % abort if current time greater than allowed
    if tNow > maxLoopTime
        bAbort = true;
    else
        bAbort = false;
    end

	[~,~,~,kResponse]   = ra.Experiment.Input.DownOnce('response'); 	
	tResponse           = conditional(isempty(kResponse),[],tNow);
 	
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end
%------------------------------------------------------------------------------%
end