function Practice(ra, varargin)
% RelAbs.Practice(<options>)
% 
% Description:	practice the relabs task
% 
% Syntax:	ra.Practice
%
% Notes:    
%
% ToDo:     
%
% Updated: 04-08-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

strSession  = switch2(ra.Experiment.Info.Get('ra', 'session'), 1, 'train', 2, 'mri');
pracData    = ra.Experiment.Info.Get('ra', [strSession '_practiceresult']);

kButtYes    = cell2mat(ra.Experiment.Input.Get('yes'));
kButtNo     = cell2mat(ra.Experiment.Input.Get('no'));
kButtBlip   = cell2mat(ra.Experiment.Input.Get('blip'));
bContinue   = true;
pData       = {};
levels      = {'1S', '1D', '2S', '2D', '3S', '3D', 'End Practice'};
kLevel      = 1;

if strcmpi(strSession, 'mri')
    ra.Experiment.Scanner.StartScan;
end

while bContinue
    blockType   = whichLevel;
    strBlock    = switch2(blockType                 , ...
                        1, 'level one | same'       , ...
                        2, 'level one | different'  , ...
                        3, 'level two | same'       , ...
                        4, 'level two | different'  , ...
                        5, 'level three | same'     , ...
                        6, 'level three | different', ...
                        7, []);
    
    if kLevel < 7
        ra.Experiment.AddLog([levels{kLevel} ' practice start']);
    else
        ra.Experiment.AddLog('practice ended');
        bContinue = false;
    end

    % display instructions
    if bContinue
        ra.Experiment.Show.Text(['Practicing ' strBlock ' \n\n Press any key to start']);
        ra.Experiment.Window.Flip;
        bPressedInstruct = 0;
        while ~bPressedInstruct
            [bPressedInstruct,~,~,~] = ra.Experiment.Input.DownOnce('any');
        end
        ra.Experiment.Show.Blank('fixation', false);
        ra.Experiment.Window.Flip;

        % pause scheduler
        ra.Experiment.Scheduler.Pause;

        % do the trial loop
        loopData = ra.TrialLoop(blockType, [], true);

        if isempty(pData)
            pData = {loopData};
        else
            pData{end+1} = loopData;
        end

        ra.Experiment.Scheduler.Resume;
    end
end

ra.Experiment.Show.Fixation('color', 'black');
ra.Experiment.Window.Flip;

if strcmpi(strSession, 'mri')
    ra.Experiment.Scanner.StopScan;
end

pracData = [pracData, pData];
ra.Experiment.Info.Set('ra', [strSession '_practiceresult'], pracData);


%------------------------------------------------------------------------------%
function blockType = whichLevel()
    bPressed = 0;
    kPressed = 0;
    while ~(kPressed == kButtYes)
        ra.Experiment.Show.Text(['<align:center><color:black>Which level?: \n\n ' levels{kLevel} '  </color></align>']);
        ra.Experiment.Window.Flip;
        while ~bPressed
            [bPressed,~,~,kPressed] = ra.Experiment.Input.DownOnce('any');
        end
        if kPressed == kButtBlip
            kLevel = conditional(kLevel==7, 1, kLevel + 1);
            kPressed = 0;
            bPressed = 0;
        end
    end
    blockType = kLevel;
    ra.Experiment.Show.Blank('fixation', false);
    ra.Experiment.Window.Flip;
end
%------------------------------------------------------------------------------%
end