function Practice(ra, varargin)
% RelAbs.Practice(<options>)
% 
% Description:	practice the rule task
% 
% Syntax:	ra.Practice('level', 1)
%
% In:   <options>   
%           blockType   -   (1) the blockType to practice
%
% Notes:    Partially adapted from NestIf experiment, but not yet in use
%               for actual RelAbs experiment.
%
% Updated: 09-15-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[blockType] = ParseArgs(varargin, 1);

ra.Experiment.AddLog([blockType ' practice start']);

bCorrect        = [];
res             = [];

% display instructions
ra.Experiment.Show.Instructions(['The active rule is ' blockType], 'next', 'continue');
    
% pause scheduler
ra.Experiment.Scheduler.Pause;

bContinue	= true;
while bContinue
    % do the trial loop
    resCur = ra.TrialLoop(blockType);
    % record results
    if isempty(res)
        res	= resCur;
    else
        res(end+1)	= resCur;
    end
    bCorrect    = [bCorrect; resCur.correct];
    
    % show feedback
    strResponse     = conditional(resCur.correct,'<color:green>Yes!</color>','<color:red>No!</color>');
	strPerformance	= ['You were correct on ' num2str(sum(bCorrect)) ' of the last ' num2str(length(bCorrect)) ' trial' plural(length(bCorrect),'','s') '.'];

	yn			= ra.Experiment.Show.Prompt([strResponse '\n\n' strPerformance '\n\n' 'Again?'],'choice',{'y','n'});
	bContinue	= isequal(yn,'y');

end

ra.Experiment.Info.Set('nestif', 'practice_results', res);
ra.Experiment.AddLog([blockType ' practice end']);
ra.Experiment.Scheduler.Resume;
