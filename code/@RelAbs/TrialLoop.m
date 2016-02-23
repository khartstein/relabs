function [blockRes, seqTiming] = TrialLoop(ra, blockType, varargin)
% RelAbs.TrialLoop
% 
% Status:
%
% Description:	run a loop of RelAbs trials using PTB.Show.Sequence and
%       ra.ShowTrial
% 
% Syntax:	res = ra.TrialLoop(blockType, 'bPractice', false)
% 
% In:
%	blockType   - the block type. Odd numbers are 1S, evens are 1D
%                   (1=1S, 2=1D, 3=2S, 4=2D, 5=3S, 6=3D)
%   <options>
%   training    - [false] a boolean specifying whether this is a training
%                   session
%
% Out:
% 	blockRes    - a struct of results for the current block
%   loopTiming  - a struct of timing information from 
%                   ra.Experiment.Sequence.Loop
%
% ToDo:          
%               - figure out why blip task is ruining everything
%                   - problems recording responses after end of either task or feedback 
%                   - solve by incorporating into sequence.linear somehow?
%               - get rid of dependence on Flip2 and Sequence2 (probably by
%                   using textures)
%
% Updated: 02-22-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)
[tStart, opt] = ParseArgs(varargin, [], 'training', false);

bPractice   = isempty(tStart) && ~opt.training;
strSession  = conditional(opt.training, 'train', 'mri');

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

% block, run, and trial info
kRun            = ra.Experiment.Info.Get('ra', 'run');
kBlock          = ra.Experiment.Info.Get('ra', 'block');

% get information for mri or training session
tBlipBlock      = ra.Experiment.Info.Get('ra', [strSession '_block_blip']);
blipResTask     = ra.Experiment.Info.Get('ra', [strSession '_blipresulttask']);
trialInfo       = ra.Experiment.Info.Get('ra', [strSession '_trialinfo']);

% blip stuff
blipTimer       = PTB.Now;
blipTime        = tBlipBlock(kRun, kBlock)*1000;
bBlipOver       = false;

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
[blockRes, bSame, numSameCorrect, seqTiming, tFlip, tBlip, bCorrect, stimOrder, kFixFeature, kFixValue, val] = deal([]);
[kTrial, nCorrect, bBlipTrial]  = deal(0);
% bBlipResponse = 0;
bMorePractice   = true;
[trialColors,trialNumbers,trialOrientations,trialShapes] = deal(cell(1,4));
fixArgs         = {};

% use ms for practice and training session
if bPractice || opt.training
    tStart		= PTB.Now;
    maxLoopTime = maxLoopTime*t.tr;
    tUnit       = 'ms';
    ra.Experiment.Scanner.StartScan;
else
    tUnit       = 'tr';
end

cF          =   {@DoTrial; @DoFeedback;};
tSequence   =   {@WaitResponse; @WaitFeedback};

% open texture for on-deck trial creation
ra.Experiment.Window.OpenTexture('nextTrial');

% prepare and draw the first trial 
PrepTrial('main');
ra.ShowStim(stimOrder, trialColors, trialNumbers, trialOrientations, trialShapes, 'window', 'main');
bNextPrepped    = true;

while PTB.Now - tStart < maxLoopTime && bMorePractice
    [tStartTrial,tEndTrial,tTrialSequence, bAbort] = ra.Experiment.Sequence.Linear(...
                        cF              ,   tSequence   , ...
                        'tunit'         ,   tUnit       , ...
                        'tbase'         ,   'sequence'  , ...
                        'tstart'        ,   tStart      , ...
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

if bPractice || opt.training
    ra.Experiment.Scanner.StopScan
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
    
    ra.Experiment.Window.Flip2;
    tFlip = PTB.Now;
    
    % blip during trial
    if PTB.Now - blipTimer > blipTime && ~bBlipOver
        tBlip       = DoBlip;
        bBlipTrial  = true;
        bBlipOver   = true;
    end

end
%------------------------------------------------------------------------------%
function [tOut] = DoFeedback(tNow, NaN)
    tOut = NaN;
    fixArgs = {'Fixation', 'color', 'black'};
    
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
    
    if ~isnan(blockRes(end).kResponse)
        ra.Experiment.Show.Text(strText);
    end
    
    ra.Experiment.Window.Flip2;
    
    % blip during feedback
    if PTB.Now - blipTimer > blipTime && ~bBlipOver
        tBlip       = DoBlip;
        bBlipTrial  = true;
        bBlipOver   = true;
    end
    ra.Experiment.Show.Blank('fixation', false);
    
end 
%------------------------------------------------------------------------------%
function [] = PrepTrial(texWindow)
    
    kTrial      = kTrial + 1;
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
            ra.Experiment.Show.Circle(val, 0.25, [0,0], 'window', texWindow)
            fixArgs = {'Circle', val, 0.25, [0,0]};
        case 2
            % number
            val     = num2str(numbers{kFixValue});
            ra.Experiment.Show.Text(['<color: black><size: 0.5>' val '</color></size>'], [0,0], 'window', texWindow);
            fixArgs = {'Text', ['<color: black><size: 0.5>' val '</color></size>'], [0,0]};
        case 3
            % orientation
            val     = switch2(orientations{kFixValue}, 'horizontal', [0.5, 0.125], 'vertical', [0.125, 0.5]);
            ra.Experiment.Show.Rectangle('black', val, [0, 0], 'window', texWindow);
            fixArgs = {'Rectangle', 'black', val, [0, 0]};
        case 4
            % shape
            val     = shapes{kFixValue};
            if strcmpi(val, 'square') 
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0], 'window', texWindow);
                fixArgs = {'Rectangle', 'black', 0.25, [0,0]};
            elseif strcmpi(val, 'diamond')
                ra.Experiment.Show.Rectangle('black', 0.25, [0,0], 45, 'window', texWindow);
                fixArgs = {'Rectangle', 'black', 0.25, [0,0], 45};
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
function [tBlipEnd] = DoBlip()
    % do fixation blip
    tSeq = cumsum([0.250 0.0001])*1000;
    ra.Experiment.Show.Sequence2({{'Rectangle', backColor, 1.0, [0,0]},      ...
                                 fixArgs}, tSeq, 'tunit', 'ms', 'tbase',    ...
                                'sequence', 'fixation', false);   
    tBlipEnd = PTB.Now;
end
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = WaitResponse(tNow)
    % abort if current time greater than allowed, otherwise get response
    % should work independent of whether response is for blip or task
    kResponse       = [];
    tResponse       = [];
    
    bAbort          = false;
    blipResponse    = NaN;
    tBlipResponse   = NaN;
    kBlipResponse   = NaN;
    
    while isempty(kResponse) && tNow < maxLoopTime
        [~,~,~,kResponse]       = ra.Experiment.Input.DownOnce('response');
        [~,~,~,kBlip]           = ra.Experiment.Input.DownOnce('blip');
        if ~isempty(kBlip)
            kBlipResponse       = kBlip;
        end
        tBlipResponse           = conditional(isempty(kBlip),[],PTB.Now); 
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
    trialRes.kBlipResponse  = kBlipResponse;
    trialRes.bBlipTrial     = bBlipTrial;
    trialRes.bBlipFeedback  = 0;
    trialRes.blipResponse   = blipResponse;
    trialRes.blipRT         = tBlipResponse - tBlip;
    trialRes.numSame        = sum(bSame);                                   % only records number of matches for levels 2 & 3
    trialRes.numSameCorrect = numSameCorrect;
    trialRes.rt             = tResponse - tFlip; 
    trialRes.correct        = (bCorrect && ismember(kButtYes,kResponse))...
                            ||(~bCorrect && ismember(kButtNo,kResponse));
    
    bBlipTrial = false;
                        
    if isempty(blockRes)
        blockRes        = trialRes;
    else
        blockRes(end+1) = trialRes;
    end
    
    if tNow > maxLoopTime
        bAbort      = true;
        bContinue   = false;
    else
        bContinue   = true;
    end
    
    ra.Experiment.Show.Blank('fixation', false);
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = WaitFeedback(tNow)
    % abort if current time greater than allowed, otherwise get response
    
    bAbort          = false;
    bContinue       = true;
    tFeedbackStart  = PTB.Now;

    if bBlipTrial
        kBlipResponse = [];
        while isempty(kBlipResponse) && tNow < maxLoopTime && PTB.Now - tFeedbackStart < 1000
            [~,~,~,kBlipResponse]   = ra.Experiment.Input.DownOnce('blip');
            tBlipResponse           = conditional(isempty(kBlipResponse),[],PTB.Now);             
        end
        blockRes(end).blipResponse  = switch2(kBlipResponse, kButtBlip, 1, [], NaN);
        blockRes(end).bBlipFeedback = 1;
        blockRes(end).blipRT        = tBlipResponse - tBlip; 
        bBlipTrial = false;
    end
    
    if tNow > maxLoopTime - 1000
        bAbort      = true;
        bContinue   = false;
    elseif PTB.Now - tFeedbackStart > 1000
        % time to move on
    elseif bPractice
        WaitSecs(1.0)
        if bPractice
            yn              = ra.Experiment.Show.Prompt('Again?','choice',{'y','n'});
            bMorePractice	= isequal(yn,'y');
            bNextPrepped     = false;
        end
        if ~bMorePractice
            bAbort      = true;
            bContinue   = false;
        end
    else
        % prep next trial texture
        ra.Experiment.Show.Blank('fixation', false);
        PrepTrial('nextTrial');
        ra.ShowStim(stimOrder, trialColors, trialNumbers, trialOrientations, trialShapes, 'window', 'nextTrial')
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