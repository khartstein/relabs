function [practiceData] = Practice(ra, varargin)
% RelAbs.Practice(<options>)
% 
% Description:	practice the relabs task
% 
% Syntax:	ra.Practice('blockType', 1)
%
% In:   <options>   
%           blockType   -   (1) the blockType to practice
%
% Notes:    
%
% ToDo:     
%           - test with scanner button layout
%               - revert and make it work again.
%
% Updated: 04-01-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt = ParseArgs(varargin, 'blockType', 1);

strSession  = switch2(ra.Experiment.Info.Get('ra', 'session'), 1, 'Train', 2, 'MRI');

kButtYes = cell2mat(ra.Experiment.Input.Get('yes'));
bNextLevel      = true;
practiceData    = {};

while bNextLevel
    strBlock = switch2(opt.blockType                , ...
                        1, 'level one | same'       , ...
                        2, 'level one | different'  , ...
                        3, 'level two | same'       , ...
                        4, 'level two | different'  , ...
                        5, 'level three | same'     , ...
                        6, 'level three | different'  ...
                          );

    ra.Experiment.AddLog([strBlock ' practice start']);

    % display instructions
    if strcmpi(strSession, 'mri')
        ra.Experiment.Show.Text(['Practicing ' strBlock ' \n\n Press any key to start']);
        ra.Experiment.Window.Flip;
        bPressed = 0;
        while ~bPressed
            bPressed = ra.Experiment.Input.DownOnce('any');
        end
        ra.Experiment.Show.Blank('fixation', false);
        ra.Experiment.Window.Flip;
    else
        ra.Experiment.Show.Instructions(['Practicing ' strBlock]);
    end
    
    % pause scheduler
    ra.Experiment.Scheduler.Pause;

    % do the trial loop
    loopData = ra.TrialLoop(opt.blockType, true);

    if isempty(practiceData)
        practiceData = {loopData};
    else
        practiceData{end+1} = loopData;
    end
    
    ra.Experiment.Scheduler.Resume;
    
    % do next level?
    if opt.blockType < 6
        if strcmpi(strSession, 'mri')
            ra.Experiment.Show.Text('Continue to next level?');
            ra.Experiment.Window.Flip;
            bPressed = 0;
            while ~bPressed
                [bPressed,~,~,kPressed] = ra.Experiment.Input.DownOnce('any');
            end
            ra.Experiment.Show.Blank('fixation', false);
            ra.Experiment.Window.Flip;
            bNextLevel = conditional(kPressed==kButtYes, 1, 0);
        else
            sNextLevel = ra.Experiment.Show.Prompt('Continue to next level?','choice',{'y','n'});
            bNextLevel = conditional(strcmpi(sNextLevel, 'y'), true, false);
        end
    else
        bNextLevel = false;
    end
    
    % increment blockType if continuing
    if bNextLevel
       opt.blockType = opt.blockType + 1;
    end
    
end
end