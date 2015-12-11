function Run(ra)
% RelAbs.Run
%
% Description: do the next relabs run
%
% Syntax: ra.Run
%
% ToDo:     - Scanner stuff
%
% Updated: 08-13-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

    nBlock      = RA.Param('exp','blocks');
    nRun        = RA.Param('exp','runs');
    tRun        = RA.Param('trrun');  
    
    trRest      = RA.Param('time', 'rest');
    trTrialLoop = RA.Param('time', 'trialloop');                
    trPrompt    = RA.Param('time', 'prompt');
    trWait      = RA.Param('time', 'wait');
    trTimeUp    = RA.Param('time', 'timeup'); 
    tr          = RA.Param('time', 'tr');  
    
% get the subject's block order
    blockOrder = ra.Experiment.Subject.Get('block_order');
    
% get the current run
    kRun	= ra.Experiment.Info.Get('ra','run');
    kRun	= ask('Next run','dialog',false,'default',kRun);
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
    ra.Experiment.Scanner.StartScan(tRun);
 	
% let idle processes execute
    ra.Experiment.Scheduler.Wait;
    
cF          =    [
                    {@DoRest}
                    repmat({@ShowPrompt; @DoWait; @DoTrialLoop; @DoTimeUp; @DoRest}, [nBlock 1])
                    ];
                
tSequence   = cumsum([
                        trRest
                        repmat([trPrompt; trWait; trTrialLoop; trTimeUp; trRest], [nBlock 1])
                        ]);
                    
% because fake scanner
    tStart		= PTB.Now;
    tSequence   = tSequence*tr;
    strTUnit    = 'ms';

	[tStartActual,tEndActual,tSequenceActual] = ra.Experiment.Sequence.Linear(...
                        cF              ,   tSequence   , ...
                        'tunit'         ,   strTUnit    , ...
                        'tstart'        ,   tStart      , ...
                        'tbase'         ,   'sequence'  , ...
                        'fwait'         ,   false         ...
                    );
    runTiming = struct('StartActual', tStartActual, 'EndActual', tEndActual, 'SequenceActual', tSequenceActual);
% scanner stopped
    ra.Experiment.Scanner.StopScan;
% blank the screen
    ra.Experiment.Show.Text('<color:red><size:3>RELAX!</size></color>');
    ra.Experiment.Window.Flip;

% save timing results
    timing = ra.Experiment.Info.Get('ra', 'timing');
    timing{kRun} = runTiming;
    ra.Experiment.Info.Set('ra', 'timing', timing);
    
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
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip;
	
	ra.Experiment.Scheduler.Wait;
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
                                        6, 'level three | different'  ,   ...
                                        7, 'level four | same'        ,   ...
                                        8, 'level four | different'       ...
                                        );
    ra.Experiment.Show.Text(['<size:1><style:normal><color:black>' sBlockType '</color></style></size>']);
    % flip and log
    ra.Experiment.Window.Flip(['block ' num2str(kBlock) ', type: ' sBlockType]);
end
%------------------------------------------------------------------------------%
function tNow = DoWait(tNow, tNext)
	ra.Experiment.AddLog('waiting (for prompt HRF decay)');
	
	% blank the screen
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip;
	ra.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW);
end
%------------------------------------------------------------------------------%
function tNow = DoTrialLoop(tNow, tNext)
    % execute the block
    kBlock = ra.Experiment.Info.Get('ra', 'block');
    blockType = blockOrder(kRun,kBlock);
    blockRes	= ra.TrialLoop(blockType);        
    
    % save results
    result = ra.Experiment.Info.Get('ra', 'result');
    result{kRun, kBlock} = blockRes;
    ra.Experiment.Info.Set('ra', 'result', result);
    
    % increment block
    if kBlock < nBlock
        ra.Experiment.Info.Set('ra','block',kBlock+1);
    else
        ra.Experiment.Info.Set('ra','block',1);
    end
    ra.Experiment.Show.Blank;
    ra.Experiment.Window.Flip;
end  
%------------------------------------------------------------------------------%
function tNow = DoTimeUp(tNow, tNext)
    % time is up for block.
    strFeedback = 'Time Up!';
    strColor    = 'red';
    
    strText = ['<color:' strColor '>' strFeedback '</color>\n\nCurrent total: ' StringMoney(ra.reward)];
    ra.Experiment.Show.Text(strText);
    ra.Experiment.Window.Flip;
end
%------------------------------------------------------------------------------%
end