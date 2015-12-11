function res = Trial(ra, blockType, kTrial, varargin)
% RelAbs.Trial
% 
% Description:	run a single RelAbs trial. not currently used, but
%   under development for better timing with PTB.Show.Sequence
% 
% Syntax:	res = ra.Trial(blockType, kTrial)
% 
% In:
%	blockType   - The type of block to pull a trial from.
%                   (1=1s,2=1d,3=2s,4=2d,5=3s,6=3d,7=4s,8=4d)
%   kTrial      - The current trial number 
%
% Out:
% 	res         - a struct of results
%
% ToDo:         - Fix tResponse
%               - other timing problems
%
% Updated: 09-02-2014

[tStart] = ParseArgs(varargin, []);

bPractice = isempty(tStart);

topCenter       = RA.Param('screenlocs' , 'topcenter');
bottomCenter    = RA.Param('screenlocs' , 'bottomcenter');
radius          = RA.Param('stim_size'  , 'circradius');
squareSide      = RA.Param('stim_size'  , 'sqside');
smallXOff       = RA.Param('smallXOffset');
largeXOff       = RA.Param('largeXOffset');
smallYOff       = RA.Param('smallYOffset');
largeYOff       = RA.Param('largeYOffset');


% block and run information
kRun    = ra.Experiment.Info.Get('ra', 'run');
kBlock  = ra.Experiment.Info.Get('ra', 'block');

% find correct/incorrect keys
kButtYes = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo = cell2mat(ra.Experiment.Input.Get('no'));
% bResponse = false;

% same/different arrays
bOneSame    = unique(perms([1 0 0 0]), 'rows');
bTwoSame    = unique(perms([0 0 1 1]), 'rows');
bThreeSame  = unique(perms([0 1 1 1]), 'rows');
bAllSame    = [1 1 1 1];
bNoneSame   = [0 0 0 0];

% get trial info
trial = ra.Experiment.Info.Get('ra', 'trial');
numSame = trial.numSame(kRun, kBlock, kTrial);
numSameYes = switch2(blockType, {1, 3, 5, 7}, 1, {2, 4, 6, 8}, 3);

% choose stimuli for the trial
bSame1 = switch2(numSame, 0, bNoneSame                          , ...  
                    1, bOneSame(randi(length(bOneSame)),:)      , ...
                    2, bTwoSame(randi(length(bTwoSame)),:)      , ...
                    3, bThreeSame(randi(length(bThreeSame)),:)  , ...
                    4, bAllSame);

if ismember(blockType, 5:8)
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
    
% choose features and show the stimulus
[color1, number1, orientation1, shape1] = ra.ChooseStimFeatures(bSame1);
[trialColors, trialNumbers, trialOrientations, trialShapes] = deal(color1, number1, orientation1, shape1);

if ismember(blockType, [7 8])
    [color2, number2, orientation2, shape2] = ra.ChooseStimFeatures(bSame2);
    trialColors = [color1, color2];
    trialNumbers = [number1, number2];
    trialOrientations = [orientation1, orientation2];
    trialShapes = [shape1, shape2];
end

% timing
t = RA.Param('time');

cSequence   = {             @ShowStimulus
                            @ShowBlank
              };
         
tSequence   = {             @DoBlank
                            @DoStim
              };

% fWait       = {             @WaitResponse
%                             @WaitBlank
%               };

if bPractice
    tStart      = PTB.Now;
    blockTime   = t.trialloop*t.tr;
    strTUnit	= 'ms';
else
    blockTime = t.trialloop;
    strTUnit	= 'tr';
end

if bPractice
    ra.Experiment.Scanner.StartScan;
end

[tStart,tEnd,tShow,bAbort] = ra.Experiment.Show.Sequence(...
                cSequence   ,   tSequence   ,   ...
                'tunit'     ,   strTUnit    ,   ...
                'tstart'    ,   tStart      ,   ...
                'tbase'     ,   'sequence'      ...
                );
%                 ;'fwait'    ,   fWait           ...

if bPractice
%     ra.Experiment.Show.Blank('fixation',true);
%     ra.Experiment.Window.Flip;
    ra.Experiment.Scanner.StopScan;
end
            
    
% determine whether answer is correct
if ismember(res.kResponse, kButtYes)
    sResponse = 'Yes';
elseif ismember(res.kResponse, kButtNo)
    sResponse = 'No';
elseif isempty(res.kResponse)
    sResponse = 'No response';
else
    sResponse = 'Incorrect Key';
end

% record trial results
res.tStart      = tStart;
res.tEnd        = tEnd;
res.tShow       = tShow;
res.abort       = bAbort;
res.level       = blockType;
res.color       = trialColors;
res.number      = trialNumbers;
res.orientation = trialOrientations;
res.shape       = trialShapes;
res.response    = sResponse;
res.numSame     = numSame;
res.numSameYes  = numSameYes;
res.correct     = (numSameYes == numSame && ismember(res.kResponse,kButtYes))...
                    ||(numSameYes ~= numSame && ismember(res.kResponse,kButtNo));
    
%     % feedback - do here or in Run2?
%     DoFeedback;    

%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum, varargin)
    opt	= ParseArgs(varargin,...
		'window'	, 'main'	  ...
		);
    if ismember(blockType, 1:4)
        center = switch2(stimNum, 1, topCenter, 2, bottomCenter, [0 0]);
    elseif ismember(blockType, 5:8)
        center = switch2(stimNum, 1, topCenter - [6 0], 2, bottomCenter - [6 0], ...
            3, topCenter + [6 0], 4, bottomCenter + [6 0]);
    end
    smallOffset = switch2(trialOrientations{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(trialOrientations{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    bitLoc = {center-largeOffset, center-smallOffset,center+smallOffset, center+largeOffset};
    if strcmpi(trialShapes{stimNum},'rectangle')
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{2}, [], 'window', opt.window);
        ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{3}, [], 'window', opt.window);
            if trialNumbers{stimNum} == 4
                ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{1}, [], 'window', opt.window);
                ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, bitLoc{4}, [], 'window', opt.window);    
            end
    elseif strcmpi(trialShapes{stimNum}, 'circle')
        ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{2}, [], 'window', opt.window);
        ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{3}, [], 'window', opt.window);
            if trialNumbers{stimNum} == 4
                ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{1}, [], 'window', opt.window);
                ra.Experiment.Show.Circle(trialColors{stimNum}, radius, bitLoc{4}, [], 'window', opt.window);
            end
    else
            error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL1Box(stimNum, varargin)
    opt	= ParseArgs(varargin,...
		'window'	, 'main'	  ...
		);
    oriDims = switch2(trialOrientations{stimNum}, 'vertical', [.125*squareSide squareSide], ...
                'horizontal', [squareSide, .125*squareSide]);
    iLoc = randperm(4);
    boxLocs = {bottomCenter-largeXOff, bottomCenter-smallXOff, ...
        bottomCenter+smallXOff, bottomCenter+largeXOff};
    % color
    ra.Experiment.Show.Rectangle(trialColors{stimNum}, squareSide, boxLocs{iLoc(1)}, [], 'window', opt.window);
    % number
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>'...
        num2str(trialNumbers{stimNum}) '</color></style></size>'], ...
        (boxLocs{iLoc(4)} + [0 .5]), 'window', opt.window);
    % orientation
    ra.Experiment.Show.Rectangle('black', oriDims, boxLocs{iLoc(2)}, [], 'window', opt.window);
    % shape 
    if strcmpi(trialShapes{stimNum}, 'rectangle')
        ra.Experiment.Show.Rectangle('black', squareSide, boxLocs{iLoc(3)}, [], 'window', opt.window); 
    elseif strcmpi(trialShapes{stimNum}, 'circle')
        ra.Experiment.Show.Circle('black', radius, boxLocs{iLoc(3)}, [], 'window', opt.window);
    else
        error('stimulus shape cannot be identified');
    end
end
%------------------------------------------------------------------------------%
function [] = DrawL3Box(varargin)
    opt	= ParseArgs(varargin,...
		'window'	, 'main'	  ...
		);
    % replace text with icons
    boxLocs = {[6 0]-largeXOff, [6 0]-smallXOff, ...
        [6 0]+smallXOff, [6 0]+largeXOff};
    SD = Replace(bSame2, [0 1], ['D' 'S']);
    cLabelIms = {ra.colorIcon, ra.numberIcon, ra.orientationIcon, ra.shapeIcon};
    for loc = 1:4
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>' char(SD(loc)) '</color></style></size>'], ...
        (boxLocs{loc} + [0 1.5]), [], [], 'window', opt.window);
    ra.Experiment.Show.Image(cLabelIms{loc}, (boxLocs{loc} - [0 1.5]), 1.5, [], 'window', opt.window);
    end
end
%------------------------------------------------------------------------------%
function [] = ShowStimulus(varargin)
    switch blockType
        case {1 2}
            DrawSet(1, varargin{:});
            DrawL1Box(2, varargin{:});
        case {3 4}
            DrawSet(1, varargin{:});
            DrawSet(2, varargin{:});
        case {5 6}
            DrawSet(1, varargin{:});
            DrawSet(2, varargin{:});
            DrawL3Box(varargin{:});
        case {7 8}
            for k = 1:4
                DrawSet(k, varargin{:});
            end
        otherwise
            error('blockType must be an integer between 1 and 8!');
    end
    ra.Experiment.Window.Flip
end
%------------------------------------------------------------------------------%
function [] = ShowBlank(varargin)
    opt = ParseArgs(varargin,...
        'window'    , 'main'    ...
        );
    ra.Experiment.Show.Blank(varargin{:});
end
%------------------------------------------------------------------------------%
% function [bAbort] = WaitBlank(tNow,tNext)
% 	bAbort		= false;
% 
%     ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
% end
%------------------------------------------------------------------------------%
% function [bAbort] = WaitResponse(tNow,tNext)
% 	bAbort              = false;
% 	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
%     
%  end
%------------------------------------------------------------------------------%
function [bAbort, bContinue, kResponse, tResponse] = DoBlank(tNow)
    bAbort      = false;
    kResponse   = [];
    tResponse   = [];
    
    while isempty(kResponse)
        [~,~,tResponse,kResponse]	= ra.Experiment.Input.DownOnce('response');
    end
    
    res.kResponse   = kResponse;
    res.rt          = tResponse - tStart;
    
    % if response has been made and time is less than block time, do next thing
    if ~isempty(kResponse) && tNow < blockTime
        bContinue = true;
    else
        bContinue = false;
    end
end
%------------------------------------------------------------------------------%
function [bAbort, bContinue] = DoStim(tNow)
    bAbort = false;
    
    % if time is less than block time, do next thing
    if tNow < blockTime
        bContinue = true;
    else
        bContinue = false;
        bAbort = true;
    end
    
    % take care of log messages, etc.
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
end      
%------------------------------------------------------------------------------%
end
