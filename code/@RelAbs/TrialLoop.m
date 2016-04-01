function [blockRes, seqTiming] = TrialLoop(ra, blockType, varargin)
% RelAbs.TrialLoop
%
% Description:	run a loop of RelAbs trials using PTB.Show.Sequence and
%       ra.ShowTrial
% 
% Syntax:	res = ra.TrialLoop(blockType)
% 
% In:
%	blockType   - the block type. Odd numbers are 1S, evens are 1D
%                   (1=1S, 2=1D, 3=2S, 4=2D, 5=3S, 6=3D)
%   <options>
%   bPractice   - [false] a boolean specifying whether TrialLoop is being 
%                   called from the practice function
%
% Out:
% 	blockRes    - a struct of results for the current block
%   loopTiming  - a struct of timing information from 
%                   ra.Experiment.Sequence.Loop
%
% ToDo:          
%               - 
%
% Updated: 04-01-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[~, bPractice] = ParseArgs(varargin, [], false);
tStart      = PTB.Now;
strSession  = switch2(ra.Experiment.Info.Get('ra', 'session'), 1, 'train', 2, 'mri');

% get feature values from RA.Param
colors          = struct2cell(RA.Param('stim_color'));
numbers         = struct2cell(RA.Param('stim_number'));
orientations    = fieldnames(RA.Param('stim_orient'));
shapes          = fieldnames(RA.Param('stim_shape'));

% get background color
backColor       = RA.Param('color', 'back');

% timing info
t               = RA.Param('time');
maxLoopTime     = switch2(bPractice, false, t.trialloop, true, inf);
maxLoopTime     = maxLoopTime*t.tr;

% block, run, and trial info
kRun            = ra.Experiment.Info.Get('ra', 'run');
kBlock          = ra.Experiment.Info.Get('ra', 'block');

% get information for mri or training session
trialInfo       = ra.Experiment.Info.Get('ra', [strSession '_trialinfo']);

% blip stuff
tBlipBlock      = ra.Experiment.Info.Get('ra', [strSession '_block_blip']);
blipRT          = ra.Experiment.Info.Get('ra', [strSession '_blipresulttask']);
blipTime        = tBlipBlock(kRun, kBlock);

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

% bSame possibilities for incorrect answers
bNotOneSame     = [bTwoSame; bThreeSame; bAllSame; bNoneSame];
bNotThreeSame   = [bOneSame; bTwoSame; bAllSame; bNoneSame];

% initialize some things
[blockRes, bSame, numSameCorrect, seqTiming, tFlip, bCorrect, stimOrder, kFixFeature, kFixValue, val] = deal([]);
[kTrial, nCorrect]  = deal(0);
% bBlipResponse = 0;
bMorePractice   = true;
[trialColors,trialNumbers,trialOrientations,trialShapes] = deal(cell(1,4));

% use ms for practice and training session
if bPractice || strcmpi(strSession, 'train')
    tUnit       = 'ms';
    ra.Experiment.Scanner.StartScan;
else
    tUnit       = 'tr';
    maxLoopTime = maxLoopTime*(63/64);
end

cF          =   {@DoTrial; @DoFeedback;};
tSequence   =   {@WaitResponse; @WaitFeedback};

% open texture for on-deck trial creation
ra.Experiment.Window.OpenTexture('nextTrial');

if ~bPractice
    % set up blipTimer
    blipTimer               = timer;
    blipTimer.Name          = 'blipTimer';
    blipTimer.StartDelay    = blipTime;
    blipTimer.TimerFcn      = @(blipTimerObj, thisEvent)DoBlip;

    start(blipTimer);
end

% prepare and draw the first trial 
PrepTrial('main');
ra.ShowStim(stimOrder, trialColors, trialNumbers, trialOrientations, trialShapes, 'window', 'main');
bNextPrepped    = true;

while (PTB.Now - tStart) < maxLoopTime && bMorePractice
    [tStartTrial,tEndTrial,tTrialSequence, bAbort] = ra.Experiment.Sequence.Linear(...
                        cF              ,   tSequence   , ...
                        'tunit'         ,   tUnit       , ...
                        'tbase'         ,   'sequence'  , ...
                        'fwait'         ,   fWait         ...
                        );
                    
    % save loop timing for output
    curSeqTiming = struct('tStart'  , tStartTrial,      ...
                          'tEnd'    , tEndTrial,        ...
                          'tSeq'    , tTrialSequence,   ...
                          'bAbort'  , bAbort);

    if isempty(seqTiming)
        seqTiming = curSeqTiming;
    else
        seqTiming(end+1) = curSeqTiming;
    end
   
end

if bPractice || strcmpi(strSession, 'train')
    ra.Experiment.Scanner.StopScan;
end

% close nextTrial texture and blank the screen
ra.Experiment.Window.CloseTexture('nextTrial');
ra.Experiment.Show.Fixation('color', 'black');
ra.Experiment.Window.Flip;

%------------------------------------------------------------------------------%
function [tOut] = DoTrial(tNow, NaN)
    tOut        = NaN;
    
    if bNextPrepped
        ra.Experiment.Show.Texture('nextTrial');
    else
        ra.Experiment.Show.Blank('fixation', false);
        PrepTrial('main');
        ra.ShowStim(stimOrder, trialColors, trialNumbers, trialOrientations, trialShapes, 'window', 'main')
    end
    
    ra.Experiment.Window.OverrideStore(true);
    tFlip = ra.Experiment.Window.Flip;
    
end
%------------------------------------------------------------------------------%
function [tOut] = DoFeedback(tNow, NaN)
    tOut = NaN;
    
    % add a log message
    nCorrect	= nCorrect + blockRes(end).correct;
    strCorrect	= conditional(blockRes(end).correct,'y','n');
    strTally	= [num2str(nCorrect) '/' num2str(kTrial)];
     
    ra.Experiment.AddLog(['feedback (' strCorrect ', ' strTally ')']);
    
    % get the feedback message and color
    if blockRes(end).correct
        strFeedback	= 'Yes!';
        strColor	= 'green';
    else
        strFeedback	= 'No!';
        strColor	= 'red';
    end

	% show feedback
    strText	= ['<color:' strColor '>' strFeedback '</color>\n\n']; 
    ra.Experiment.Show.Fixation('color', 'black');
    ra.Experiment.Show.Text(strText);
    
    ra.Experiment.Window.OverrideStore(true);
    ra.Experiment.Window.Flip;
    
end 
%------------------------------------------------------------------------------%
function [] = PrepTrial(texWindow)
    
    kTrial      = conditional(~bPractice, kTrial + 1, randi(36));
    ra.Experiment.AddLog(['trial ' num2str(kTrial)]);
    ra.Experiment.Show.Blank('window', texWindow, 'fixation', false);
    
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
            ra.Experiment.Show.Circle(val, 0.25, [0,0], 'window', texWindow);
        case 2
            % number
            val     = num2str(numbers{kFixValue});
            ra.Experiment.Show.Text(['<color: black><size: 0.5>' val '</color></size>'], [0,0], 'window', texWindow);
        case 3
            % orientation
            val     = switch2(orientations{kFixValue}, 'horizontal', [0.5, 0.125], 'vertical', [0.125, 0.5]);
            ra.Experiment.Show.Rectangle('black', val, [0, 0], 'window', texWindow);
        case 4
            % shape
            val     = shapes{kFixValue};
            if strcmpi(val, 'square') 
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0], 'window', texWindow);
            elseif strcmpi(val, 'diamond')
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0], 45, 'window', texWindow);
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
end
%------------------------------------------------------------------------------%
function [] = DoBlip()
    % execute the blip
    ra.Experiment.Window.Recall;
    ra.Experiment.Show.Rectangle(backColor, 1.0, [0,0]);
    ra.Experiment.Window.Flip;
    WaitSecs(0.250);
    ra.Experiment.Window.Recall;
    tBlipOffset = ra.Experiment.Window.Flip('fixation blip end');
    
    % get response and record reaction time
    kBlipResponse   = [];
    while isempty(kBlipResponse) && PTB.Now - tBlipOffset < 1500
        [~,~,~,kBlipResponse]   = ra.Experiment.Input.DownOnce('blip');
        tBlipResponse           = conditional(isempty(kBlipResponse),[],PTB.Now);
    end
    
    blockBlipRT                 = conditional(~isempty(tBlipResponse), tBlipResponse - tBlipOffset, NaN);
    ra.Experiment.AddLog(['fixation blip response | RT: ' num2str(blockBlipRT)]);
    blipRT(kRun,kBlock)         = blockBlipRT;
    ra.Experiment.Info.Set('ra', [strSession '_blipresulttask'], blipRT);
    stop(blipTimer);
end
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = WaitResponse(tNow)
    % abort if current time greater than allowed, otherwise get response
    % should work independent of whether response is for blip or task
    kResponse       = [];
    tResponse       = [];
    
    bAbort          = false;
    
    while isempty(kResponse) && PTB.Now - tStart < maxLoopTime
        [~,~,~,kResponse]       = ra.Experiment.Input.DownOnce('response');
        tResponse               = conditional(isempty(kResponse),[],PTB.Now); 
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
    
    if isnan(kResponse)
        ra.Experiment.AddLog(['trial ' num2str(kTrial) ' aborted - time up.']);
        bAbort      = true;
        bContinue   = false;
    else
        % record trial results
        trialRes.level          = blockType;
        trialRes.run            = kRun;
        trialRes.block          = kBlock;
        trialRes.trial          = kTrial;
        trialRes.color          = trialColors;
        trialRes.number         = trialNumbers;
        trialRes.orientation    = trialOrientations;
        trialRes.shape          = trialShapes;
        trialRes.fixValue       = val; 
        trialRes.response       = sResponse;
        trialRes.kResponse      = kResponse;
        trialRes.numSame        = sum(bSame);                                   % only records number of matches for levels 2 & 3
        trialRes.numSameCorrect = numSameCorrect;
        trialRes.rt             = tResponse - tFlip; 
        trialRes.correct        = (bCorrect && ismember(kButtYes,kResponse))...
                                ||(~bCorrect && ismember(kButtNo,kResponse));
        
        
        if isempty(blockRes)
            blockRes        = trialRes;
        else
            blockRes(end+1) = trialRes;
        end
                            
        bContinue   = true;
    end
    
    ra.Experiment.Show.Blank('fixation', false);
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = WaitFeedback(tNow)
    % abort if current time greater than allowed, otherwise prepare texture
    % for next trial
    bAbort          = false;
    bContinue       = true;
    tFeedbackStart  = PTB.Now;
    
    if PTB.Now - tStart > maxLoopTime - (maxLoopTime/64)
        bAbort      = true;
        bContinue   = false;
    elseif bPractice && strcmpi(strSession, 'mri')
        WaitSecs(1.0);
        ra.Experiment.Show.Text('Again?');
        ra.Experiment.Window.Flip;
        bPressed = 0;
        while ~bPressed
            [bPressed,~,~,kPressed] = ra.Experiment.Input.DownOnce('any');
        end
        ra.Experiment.Show.Blank('fixation', false);
        ra.Experiment.Window.Flip;
        bMorePractice   = conditional(kPressed==kButtYes, true, false);
        bNextPrepped    = false;
    elseif bPractice && strcmpi(strSession, 'train')
        WaitSecs(1.0);
        bMorePractice	= strcmpi(ra.Experiment.Show.Prompt('Again?','choice',{'y','n'}), 'y');
        bNextPrepped    = false;
    else
        % prep next trial texture
        ra.Experiment.Show.Blank('fixation', false);
        PrepTrial('nextTrial');
        ra.ShowStim(stimOrder, trialColors, trialNumbers, trialOrientations, trialShapes, 'window', 'nextTrial');
        bNextPrepped = true;
        ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
        WaitSecs(1.0 - (PTB.Now - tFeedbackStart)/1000);
    end    
	
end
%------------------------------------------------------------------------------%
function [bAbort] = fWait(tNow, NaN)
    bAbort = false;
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
end
%------------------------------------------------------------------------------%
end