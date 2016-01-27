function Run(ra, varargin)
% RelAbs.Run
%
% Description: do the next relabs run
%
% Syntax: ra.Run
%
% ToDo:     - scanner testing
%
% Updated: 01-27-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

bTesting = ParseArgs(varargin, false);

    nBlock      = RA.Param('exp','blocks');
    nRun        = RA.Param('exp','runs');
    trRun       = RA.Param('trrun');  
    
    trRest      = RA.Param('time', 'rest');
    trTrialLoop = RA.Param('time', 'trialloop');                
    trPrompt    = RA.Param('time', 'prompt');
    trWait      = RA.Param('time', 'wait');
    trTimeUp    = RA.Param('time', 'timeup'); 
    tr          = RA.Param('time', 'tr');  
    
    kButtBlip   = cell2mat(ra.Experiment.Input.Get('blip'));
    
    kBlock      = [];
    kBlipResponse   = [];
    
% get the subject's block order and blip timing
    blockOrder  = ra.Experiment.Subject.Get('block_order');
    tBlipRest   = ra.Experiment.Info.Get('ra', 'rest_blip');
% get the current run
    kRun        = ra.Experiment.Info.Get('ra','run');
    kRun        = ask('Next run','dialog',false,'default',kRun);
    if ischar(kRun)
        kRun = str2double(kRun);
    end

% add to the log
    ra.Experiment.AddLog(['run ' num2str(kRun) ' start']); 
% add to info
    ra.Experiment.Info.Set('ra','run',kRun);

% perform the run
% disable the keyboard
%     ListenChar(2);
% start the scanner
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip('waiting for scanner');
    ra.Experiment.Scanner.StartScan(trRun);
 	
% let idle processes execute
    ra.Experiment.Scheduler.Wait;
    
    cF          =   [
                    {@DoRest}
                    repmat({@ShowPrompt; @DoWait; @DoTrialLoop; @DoTimeUp; @DoRest}, [nBlock 1])
                    ];
                
    tSequence   = cumsum([
                        trRest
                        repmat([trPrompt; trWait; trTrialLoop; trTimeUp; trRest], [nBlock 1])
                        ]);
                    
    cWait       =   [
                    {@Wait_Default}
                    repmat({@Wait_Default; @Wait_Blip; @Wait_Default; @Wait_Default; @Wait_Default}, [nBlock 1])
                    ];
                   
if bTesting
    % fake scanner, use ms
    tSequence   = tSequence*tr;
    tUnit       = 'ms';
else
    tUnit       = 'tr'; 
end
    
	[tStartActual,tEndActual,tSequenceActual] = ra.Experiment.Sequence.Linear(...
                        cF              ,   tSequence   , ...
                        'tunit'         ,   tUnit       , ...
                        'tbase'         ,   'sequence'  , ...
                        'fwait'         ,   cWait         ...
                    );

    runTimes = struct('StartActual', tStartActual, 'EndActual', tEndActual, 'SequenceActual', tSequenceActual);
% scanner stopped
    ra.Experiment.Scanner.StopScan;
% blank the screen
    ra.Experiment.Show.Text('<color:red><size:3>RELAX!</size></color>');
    ra.Experiment.Window.Flip;

% save timing results
    runTiming = ra.Experiment.Info.Get('ra', 'runtiming');
    runTiming{kRun} = runTimes;
    ra.Experiment.Info.Set('ra', 'runtiming', runTiming);
    
% % enable the keyboard
% 	ListenChar(1);
    
% add to the log
	ra.Experiment.AddLog(['run ' num2str(kRun) ' end']);
    ra.Experiment.Info.Save;

% increment run or end
	if kRun < nRun
		ra.Experiment.Info.Set('ra','run',kRun+1);
    else
        if isequal(ask('End experiment?','dialog',false,'choice',{'y','n'}),'y')
            ra.End;
        else
                disp('*** Remember to ra.End ***');
        end
    end

%------------------------------------------------------------------------------%
function tNow = DoRest(tNow, tNext)
	% log
    ra.Experiment.AddLog('rest');
    
	% blank the screen
    ra.Experiment.Show.Fixation('color', 'black');
    ra.Experiment.Window.Flip;
end
%------------------------------------------------------------------------------%
function tNow = ShowPrompt(tNow, tNext)
    % get current block
    kBlock = ra.Experiment.Info.Get('ra', 'block');
    blockType = blockOrder(kRun,kBlock);
    sBlockType = switch2(blockType,     1, 'level one | same'         ,   ...
                                        2, 'level one | different'    ,   ...
                                        3, 'level two | same'         ,   ...
                                        4, 'level two | different'    ,   ...
                                        5, 'level three | same'       ,   ...
                                        6, 'level three | different'      ...
                                        );
    ra.Experiment.Show.Text(['<size:1><style:normal><color:black>' sBlockType '</color></style></size>']);
    % flip and log
    ra.Experiment.Window.Flip(['block ' num2str(kBlock) ', type: ' sBlockType]);
end
%------------------------------------------------------------------------------%
function tNow = DoWait(tNow, tNext)
	ra.Experiment.AddLog('waiting (for prompt HRF decay)');

    % do fixation blip
	blipTime    = tBlipRest(kRun, kBlock); 
    tSeq        = cumsum([blipTime; 0.250; 0.001])*1000;
    
    % fixation blink
    ra.Experiment.Show.Sequence({{'Fixation', 'color', 'black'},    ...
                                 {'Blank', 'fixation', false},      ...
                                 {'Fixation', 'color', 'black'}},   ...
                                tSeq, 'tunit', 'ms', 'tbase',      ...
                                'sequence', 'fixation', false);
                            
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
    
end
%------------------------------------------------------------------------------%
function [bAbort] = Wait_Blip(tNow,tNext)
    % fwait function for fixation task
	bAbort  = false;
    
    [~,~,~,kBlipResponse]	= ra.Experiment.Input.DownOnce('response');
    
    % determine whether answer is correct
    if ismember(kBlipResponse, kButtBlip)
        blipCode = 1;                       % correct response (blip detected)
    elseif isempty(kBlipResponse)
        blipCode = 0;                       % no response (blip not detected)
    else
        blipCode = 9;                       % incorrect response
    end
    
    if ~isempty(kBlipResponse)
%         tResponse       = PTB.Now;            % is this useful? 
        blipResRest     = ra.Experiment.Info.Get('ra', 'blipresultrest');
        blipResRest(kRun, kBlock) = blipCode;
        ra.Experiment.Info.Set('ra', 'blipresultrest', blipResRest);
        kBlipResponse   = [];
    end
    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end
%------------------------------------------------------------------------------%
function [bAbort] = Wait_Default(tNow,tNext)
	bAbort		= false;

    ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
end
%------------------------------------------------------------------------------%
function tNow = DoTrialLoop(tNow, tNext)
    % execute the loop of trials
    kBlock                      = ra.Experiment.Info.Get('ra', 'block');
    blockType                   = blockOrder(kRun,kBlock);

    [blockRes, loopTiming]      = ra.TrialLoop(blockType, tNow, 'testing', bTesting);
    
    % save results and timing
    result                      = ra.Experiment.Info.Get('ra', 'result');
    result{kRun, kBlock}        = blockRes;
    blockTiming                 = ra.Experiment.Info.Get('ra', 'blocktiming');
    blockTiming{kRun, kBlock}   = loopTiming;
    
    ra.Experiment.Info.Set('ra', 'result', result);
    ra.Experiment.Info.Set('ra', 'blocktiming', blockTiming);
    
    % increment block
    if kBlock < nBlock
        ra.Experiment.Info.Set('ra','block', kBlock+1);
    else
        ra.Experiment.Info.Set('ra','block', 1);
    end
    
end  
%------------------------------------------------------------------------------%
function tNow = DoTimeUp(tNow, tNext)
    % time is up for block.
    strFeedback = 'Time Up!';
    strColor    = 'red';
    
    strText = ['<color:' strColor '>' strFeedback '</color>\n\nCurrent total: ' StringMoney(ra.reward)];
    ra.Experiment.Show.Text(strText);
    ra.Experiment.Show.Fixation('color', 'black');
    ra.Experiment.Window.Flip;
end
%------------------------------------------------------------------------------%
end
