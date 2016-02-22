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
%           - save practice data?
%
% Updated: 02-22-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt = ParseArgs(varargin, 'blockType', 1);

bNextLevel      = true;
practiceData    = {};

while bNextLevel
    strBlock = switch2(opt.blockType, 1, 'level one | same',    ...
                                  2, 'level one | different',   ...
                                  3, 'level two | same',        ...
                                  4, 'level two | different',   ...
                                  5, 'level three | same',      ...
                                  6, 'level three | different'  ...
                                  );

    ra.Experiment.AddLog([strBlock ' practice start']);

    % display instructions
    ra.Experiment.Show.Instructions(['Practicing ' strBlock], 'next', 'continue');

    % pause scheduler
    ra.Experiment.Scheduler.Pause;

    % do the trial loop
    loopData = ra.TrialLoop(opt.blockType);

    if isempty(practiceData)
        practiceData = {loopData};
    else
        practiceData{end+1} = loopData;
    end
    
    ra.Experiment.Scheduler.Resume;

    if opt.blockType < 6
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