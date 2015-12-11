function Practice(nif, varargin)
% NestIf.Practice(<options>)
% 
% Description:	practice the rule task
% 
% Syntax:	nif.Practice('blockType', 'A1')
%
% In:   <options>   
%           blockType   -   ('A1') the blockType to practice
%
% Updated: 06-26-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

[blockType] = ParseArgs(varargin, 'A1');

nif.Experiment.AddLog([blockType ' practice start']);

bCorrect        = [];
res             = [];

% display instructions
nif.Experiment.Show.Instructions('You will see a series of shapes \nappear on the screen', 'next', 'continue');
nif.Experiment.Show.Instructions('Determine whether the shapes are the same \n or different', 'next', 'continue');
nif.Experiment.Show.Instructions(['The active rule is ' blockType], 'next', 'continue');    
nif.Mapping;
    
% pause scheduler
nif.Experiment.Scheduler.Pause;

bContinue	= true;
while bContinue
    % do the trial
    resCur = nif.Trial(blockType);
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

	yn			= nif.Experiment.Show.Prompt([strResponse '\n\n' strPerformance '\n\n' 'Again?'],'choice',{'y','n'});
	bContinue	= isequal(yn,'y');
    if bContinue
        showMapping = nif.Experiment.Show.Prompt('show mapping?', 'choice', {'y', 'n'}, 'default', 'n');
        if showMapping == 'y'
            nif.Mapping;
        end
    end
end

nif.Experiment.Info.Set('nestif', 'practice_results', res);
nif.Experiment.AddLog([blockType ' practice end']);
nif.Experiment.Scheduler.Resume;
