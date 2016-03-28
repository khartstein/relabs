function Run(ra, varargin)
% RelAbs.Run
%
% Description: do the next relabs run
%
% Syntax: ra.Run
%
% ToDo:     
%           - check new size in scanner, combining training and scan data
%           - what's the deal with the button box?
%
% Updated: 03-28-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

strSession      = switch2(ra.Experiment.Info.Get('ra', 'session'), 1, 'train', 2, 'mri');
nRun            = RA.Param(['n' strSession 'runs']);
nBlocksPerRun   = RA.Param('exp','blocksperrun');
trRun           = RA.Param('trrun');  

trRest          = RA.Param('time', 'rest');
trTrialLoop     = RA.Param('time', 'trialloop');                
trPrompt        = RA.Param('time', 'prompt');
trWait          = RA.Param('time', 'wait');
trTimeUp        = RA.Param('time', 'timeup'); 
tr              = RA.Param('time', 'tr');  

% get the current run
kRun        = ra.Experiment.Info.Get('ra','run');
kRun        = ask('Next run','dialog',false,'default',kRun);
if ischar(kRun)
    kRun = str2double(kRun);
end
kBlock      = 1;

% add to the log
    ra.Experiment.AddLog([strSession ' run ' num2str(kRun) ' start']); 
% add to info
    ra.Experiment.Info.Set('ra','run',kRun);
    
% get the subject's block order and blip timing
    blockOrder  = ra.Experiment.Subject.Get([strSession '_block_order']);
    tBlipRest   = ra.Experiment.Info.Get('ra', [strSession '_rest_blip']);
    blipTime    = tBlipRest(kRun, kBlock);
    restBlipRT  = ra.Experiment.Info.Get('ra', [strSession '_blipresultrest']);
    
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
                    repmat({@ShowPrompt; @DoWait; @DoTrialLoop; @DoTimeUp; @DoRest}, [nBlocksPerRun 1])
                    ];
                
    tSequence   = cumsum([
                        trRest
                        repmat([trPrompt; trWait; trTrialLoop; trTimeUp; trRest], [nBlocksPerRun 1])
                        ]);
                    
    cWait       =   [
                    {@Wait_Default}
                    repmat({@Wait_Default; @Wait_Default; @Wait_Default; @Wait_Default; @Wait_Default}, [nBlocksPerRun 1])
                    ];
                   
    if strcmpi(strSession, 'train')
        % fake scanner, use ms
        tSequence   = tSequence*tr;
        tUnit       = 'ms';
    else
        tUnit       = 'tr'; 
    end
    
    % set up blipTimer
    restBlipTimer               = timer;
    restBlipTimer.Name          = 'restBlipTimer';
    restBlipTimer.StartDelay    = round(blipTime*100)/100;
    restBlipTimer.TimerFcn      = @(restBlipTimerObj, thisEvent)DoBlip;

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
	ra.Experiment.AddLog([strSession ' run ' num2str(kRun) ' end']);
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
	ra.Experiment.Show.Fixation('color', 'black');
    ra.Experiment.Window.Flip;
    ra.Experiment.AddLog('waiting (for prompt HRF decay)');
    start(restBlipTimer);
                            
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
    
end
%------------------------------------------------------------------------------%
function [] = DoBlip()
    % execute the blip
    kBlipResponse   = [];
    
    
    ra.Experiment.Show.Blank('fixation', false);
    ra.Experiment.Window.Flip;
    WaitSecs(0.250);
    ra.Experiment.Show.Fixation('color', 'black');
    tBlipOffset = ra.Experiment.Window.Flip('fixation blip end');
    
    % get response and record reaction time
    while isempty(kBlipResponse) && PTB.Now - tBlipOffset < 1000
        [~,~,~,kBlipResponse]   = ra.Experiment.Input.DownOnce('blip');
        tBlipResponse           = conditional(isempty(kBlipResponse),[],PTB.Now);
    end
    
    blockRestBlipRT             = conditional(~isempty(tBlipResponse), tBlipResponse - tBlipOffset, NaN);
    restBlipRT(kRun,kBlock)     = blockRestBlipRT;
    ra.Experiment.AddLog(['fixation blip response | RT: ' num2str(blockRestBlipRT)]);
    ra.Experiment.Info.Set('ra', [strSession '_blipresultrest'], restBlipRT);
    stop(restBlipTimer);
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

    [blockRes, loopTiming]      = ra.TrialLoop(blockType, tNow);
    
    % save results and timing
    result                      = ra.Experiment.Info.Get('ra', [strSession '_result']);
    result{kRun, kBlock}        = blockRes;
    blockTiming                 = ra.Experiment.Info.Get('ra', [strSession '_blocktiming']);
    blockTiming{kRun, kBlock}   = loopTiming;
    
    ra.Experiment.Info.Set('ra', [strSession '_result'], result);
    ra.Experiment.Info.Set('ra', [strSession '_blocktiming'], blockTiming);
    
    % increment block
    if kBlock < nBlocksPerRun
        ra.Experiment.Info.Set('ra','block', kBlock+1);
    else
        ra.Experiment.Info.Set('ra','block', 1);
    end
    
end  
%------------------------------------------------------------------------------%
function tNow = DoTimeUp(tNow, tNext)
    % time is up for block.
    ra.Experiment.Show.Text('<color:red>Time Up!</color>\n\n');
    ra.Experiment.Show.Fixation('color', 'black');
    ra.Experiment.Window.Flip;
end
%------------------------------------------------------------------------------%
end
