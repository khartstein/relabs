function res = TrialLoop(ra, blockType, varargin)
% RelAbs.TrialLoop
% 
% Description:	run a loop of RelAbs trials
% 
% Syntax:	res = ra.TrialLoop(blockType)
% 
% In:
%   blockType   - the type of block to run as an integer 1:8
%                   (1=1s,2=1d,3=2s,4=2d,5=3s,6=3d,7=4s,8=4d)
%   tStart      - <immediate> the time to start
%
% Out:
% 	res         - a struct of results
%
% ToDo:         - PTB.Show.Sequence for showing trials?
%               - Fix timing issues
%
% Updated: 08-31-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[tStart] = ParseArgs(varargin, []);

% find correct/incorrect keys
kButtYes = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo = cell2mat(ra.Experiment.Input.Get('no'));

topCenter       = RA.Param('screenlocs' , 'topcenter');
bottomCenter    = RA.Param('screenlocs' , 'bottomcenter');
radius          = RA.Param('stim_size'  , 'circradius');
squareSide      = RA.Param('stim_size'  , 'sqside');
smallXOff       = RA.Param('smallXOffset');
largeXOff       = RA.Param('largeXOffset');
smallYOff       = RA.Param('smallYOffset');
largeYOff       = RA.Param('largeYOffset');
    
trTrialLoop = RA.Param('time', 'trialloop');
tr          = RA.Param('time', 'tr');

nCorrect    = 0;
kTrial      = 0;
res         = [];

% same/different arrays
bOneSame    = unique(perms([1 0 0 0]), 'rows');
bTwoSame    = unique(perms([0 0 1 1]), 'rows');
bThreeSame  = unique(perms([0 1 1 1]), 'rows');
bAllSame    = [1 1 1 1];
bNoneSame   = [0 0 0 0];

% Pseudo-random numSame (same freq within every 8 trials)
numSame = [Shuffle(repmat(1:4, 1, 2)) Shuffle(repmat(1:4, 1, 2)) ...
        Shuffle(repmat(1:4, 1, 2)) Shuffle(repmat(1:4, 1, 2))];
numSameYes = switch2(blockType,{1, 3, 5, 7}, 1, {2, 4, 6, 8}, 3);

if isempty(tStart);
%     bPractice = true;
    tStart = PTB.Now;
end
 
tEnd = tStart + trTrialLoop*tr;

while PTB.Now < tEnd
    resCur = struct;
    kTrial = kTrial + 1;
    bResponse   = false;

    % choose stimuli for the trial
    bSame1 = switch2(numSame(kTrial), 0, bNoneSame                  , ...  
                        1, bOneSame(randi(length(bOneSame)),:)      , ...
                        2, bTwoSame(randi(length(bTwoSame)),:)      , ...
                        3, bThreeSame(randi(length(bThreeSame)),:)  , ...
                        4, bAllSame);
                    
    if ismember(blockType, [5 6 7 8])
        bSame2 = zeros(1, length(bSame1));
        iChange = randFrom(1:4, numSame(kTrial)); 
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

    % draw stimulus
    DrawStimulus;
    tTrialStart = ra.Experiment.Window.Flip;
    
    % wait for response, then flip the blank screen
    while ~bResponse && PTB.Now < tEnd        
        [bResponse, ~, tResponse, kResponse] = ra.Experiment.Input.DownOnce('response');
    end
    
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip;
    
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
    
    % determine whether answer is correct
    if ismember(kResponse, kButtYes)
        sResponse = 'Yes';
    elseif ismember(kResponse, kButtNo)
        sResponse = 'No';
    elseif isempty(kResponse) 
        sResponse = 'Timeout, end of block';
        kResponse = 0;
    else
        sResponse = 'Incorrect Key';
    end
    
    % record trial results
    resCur.level        = blockType;
    resCur.color        = trialColors;
    resCur.number       = trialNumbers;
    resCur.orientation  = trialOrientations;
    resCur.shape        = trialShapes;
    resCur.response     = sResponse;
    resCur.rt           = tResponse-tTrialStart;
    resCur.numSame      = numSame(kTrial);
    resCur.numSameYes   = numSameYes;
    resCur.correct      = (numSameYes == numSame(kTrial) && ismember(kResponse,kButtYes))...
                        ||(numSameYes ~= numSame(kTrial) && ismember(kResponse,kButtNo));
    
    % feedback
    if PTB.Now < tEnd
        DoFeedback;
    end
    
    if isempty(res)
        res         = resCur;
    else
        res(end+1)  = resCur;
    end
end
    
%------------------------------------------------------------------------------%
function [] = DrawSet(stimNum)
    if ismember(blockType, [1 2 3 4])
        center = switch2(stimNum, 1, topCenter, 2, bottomCenter, [0 0]);
    elseif ismember(blockType, [5 6 7 8])
        center = switch2(stimNum, 1, topCenter - [6 0], 2, bottomCenter - [6 0], ...
            3, topCenter + [6 0], 4, bottomCenter + [6 0]);
    end
    smallOffset = switch2(trialOrientations{stimNum}, 'horizontal', smallXOff, 'vertical', smallYOff, 0);
    largeOffset = switch2(trialOrientations{stimNum}, 'horizontal', largeXOff, 'vertical', largeYOff, 0);
    bitLoc = {center-largeOffset, center-smallOffset,center+smallOffset, center+largeOffset};
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
    boxLocs = {bottomCenter-largeXOff, bottomCenter-smallXOff, ...
        bottomCenter+smallXOff, bottomCenter+largeXOff};
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
    boxLocs = {[6 0]-largeXOff, [6 0]-smallXOff, ...
        [6 0]+smallXOff, [6 0]+largeXOff};
    SD = Replace(bSame2, [0 1], ['D' 'S']);
    cLabelIms = {ra.colorIcon, ra.numberIcon, ra.orientationIcon, ra.shapeIcon};
    for loc = 1:4
    ra.Experiment.Show.Text(['<size:1.5><style:normal><color:black>' char(SD(loc)) '</color></style></size>'], ...
        (boxLocs{loc} + [0 1.5]));
    ra.Experiment.Show.Image(cLabelIms{loc}, (boxLocs{loc} - [0 1.5]), 1.5);
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
            for k = 1:4
                DrawSet(k);
            end
        otherwise
            error('blockType must be an integer between 1 and 8!');
    end
end
%------------------------------------------------------------------------------%
% function [] = Wait_Response()
% % 	bAbort = false;
% 	
%     while ~bResponse && PTB.Now < tEnd
%         [bResponse, ~, tResponse, kResponse]	= ra.Experiment.Input.DownOnce('response');
%     end
% 	
% 	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
% end
%------------------------------------------------------------------------------%
function [] = DoFeedback()
    % add a log message
    nCorrect	= nCorrect + resCur.correct;
    strCorrect	= conditional(resCur.correct,'y','n');
    strTally	= [num2str(nCorrect) '/' num2str(kTrial)];
    
    ra.Experiment.AddLog(['feedback (' strCorrect ', ' strTally ')']);
	
	% get the message and change in winnings
		if resCur.correct
			strFeedback	= 'Yes!';
			strColor	= 'green';
			dWinning	= RA.Param('rewardpertrial');
        else
			strFeedback	= 'No!';
			strColor	= 'red';
			if kResponse == 0
                dWinning = 0;
            else
                dWinning	= -RA.Param('penaltypertrial');
            end
        end
        
	% update the winnings and show feedback
    ra.reward	= max(ra.reward + dWinning, RA.Param('reward','base'));
    strText	= ['<color:' strColor '>' strFeedback ' (' StringMoney(dWinning,'sign',true) ')</color>\n\nCurrent total: ' StringMoney(ra.reward)]; 
        
	ra.Experiment.Show.Text(strText);
    ra.Experiment.Window.Flip;
    
    WaitSecs(1.0); % FIX this can extend block time past deadline
end        
%------------------------------------------------------------------------------%
end