function Crit(nif)
% NestIf.Crit
% 
% Description:	Criterion run for all conditions of NestIf in order of
% easiest to hardest ('A1', 'B1', ... 'B3')
% 
% Syntax:	nif.Crit()
%
% Updated: 06-26-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

nCriterion	= 10;
chrLog		= {'<color:red>N</color>','<color:green>Y</color>'};

% block order easy to hard
cBlocks = fieldnames(NIF.Param('response'));

for k = 1:numel(cBlocks)
    bCorrect	= [];
    res         = [];
    nCritTrial  = 0;

    % add log
    nif.Experiment.AddLog(['Criterion Run, block ' num2str(k) ' start']);
    nif.Experiment.Info.Set('nif', 'crit_block', k);

    % get blockType
    blockType = cBlocks{k};

    % show mapping and indicate block type to subject
    nif.Mapping;
    nif.Experiment.Show.Instructions(['Active rule: ' blockType], 'next', 'continue');

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
        nCount		= min(nCriterion,numel(bCorrect));
        bCorrectC	= bCorrect(end-nCount+1:end);
        nCorrectC	= sum(bCorrectC);

        strResponse     = conditional(resCur.correct,'<color:green>Yes!</color>','<color:red>No!</color>');
        strPerformance	= ['You were correct on ' num2str(nCorrectC) ' of the last ' num2str(nCount) ' trial' plural(nCount,'','s') '.'];
        strLog			= ['History: ' join(arrayfun(@(k) chrLog{k},double(bCorrectC)+1,'uni',false),' ') ' (' num2str(nCount) ' total)'];

        nif.Experiment.Show.Instructions([strResponse '\n\n' strPerformance '\n' strLog], 'next', 'continue');

        if nCorrectC >= nCriterion
            bContinue = false;
        end

        nCritTrial = nCritTrial + 1;
    end

        nif.Experiment.Info.Set('nestif', ['criterion_' cBlocks{k} 'results'], res);
        nif.Experiment.AddLog(['Criterion Run, block ' num2str(k) ' end']);
        nif.Experiment.Scheduler.Resume;
end
end
