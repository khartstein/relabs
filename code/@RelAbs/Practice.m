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
%           - add scanner practice buttons
%
% Updated: 03-29-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt = ParseArgs(varargin, 'blockType', 1);

strSession  = switch2(ra.Experiment.Info.Get('ra', 'session'), 1, 'train', 2, 'mri');

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
    % NEED BUTTONBOX-COMPATIBLE PROMPT HERE
    ra.Experiment.Show.Prompt(['Practicing ' strBlock ' \n\n Press any key to start']);

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

    if opt.blockType < 6
        % NEED BUTTONBOX-COMPATIBLE PROMPT HERE
        sNextLevel = ra.Experiment.Show.Prompt('Continue to next level?','choice',{'y','n'});
        bNextLevel = conditional(strcmpi(sNextLevel, 'y'), true, false);
    else
        bNextLevel = false;
    end
    
    % increment blockType if continuing
    if bNextLevel
       opt.blockType = opt.blockType + 1;
    end
    
end
end