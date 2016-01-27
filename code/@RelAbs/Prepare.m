function Prepare(ra,varargin)
% RelAbs.Prepare
%
% Description: prepare to run an ra session
%
% Syntax: ra.Prepare()
%
% ToDo:         
%           - Make sure blip image is correct
%
% Updated: 01-26-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

% global strDirBase;
    
% block order
    nRep        = RA.Param('exp','reps');
    nRun        = RA.Param('exp','runs');
    nBlock      = RA.Param('exp', 'blocks'); 

    cBlocks = 1:nBlock;
    
    bBlockOrderExists = ~isempty(ra.Experiment.Subject.Get('block_order'));
    if bBlockOrderExists
        strOrderExist = 'existing';
    elseif ra.Experiment.Info.Get('experiment', 'debug') < 2
        % counterbalanced if running for real
        blockOrder  = blockdesign(cBlocks, nRep, nRun);
        ra.Experiment.Subject.Set('block_order', blockOrder);
        strOrderExist = 'new';
    else
        % debug mode, 1:6 in order for all runs
        blockOrder  = repmat(cBlocks, nRun, nRep);        
        ra.Experiment.Subject.Set('block_order', blockOrder);
        strOrderExist = 'default';
    end
    
    ra.Experiment.AddLog(['using ' strOrderExist ' block order']);
    
    % set run, block, timing, results
    ra.Experiment.Info.Set('ra', 'run', 1);
    ra.Experiment.Info.Set('ra', 'block', 1);
    ra.Experiment.Info.Set('ra', 'blocktiming', cell(RA.Param('exp', 'runs'), RA.Param('blocksperrun')));
    ra.Experiment.Info.Set('ra', 'result', cell(RA.Param('exp', 'runs'), RA.Param('blocksperrun')));
    ra.Experiment.Info.Set('ra', 'blipresulttask', zeros(RA.Param('exp', 'runs'), RA.Param('blocksperrun')));
    ra.Experiment.Info.Set('ra', 'blipresultrest', zeros(RA.Param('exp', 'runs'), RA.Param('blocksperrun')));
    ra.Experiment.Info.Set('ra', 'runtiming', cell(RA.Param('exp', 'runs'), 1));
    ra.reward	= RA.Param('reward','base');
    
    % set trial information
    bCorrect    = zeros(nRun, nBlock, 36);
%     frameType   = zeros(nRun, nBlock, 36);
    fixFeature  = zeros(nRun, nBlock, 36);
    tBlipRest   = zeros(nRun, 6);
    tBlipBlock  = zeros(nRun, nBlock);
    
    for iRun = 1:nRun
        for iBlock = 1:nBlock
            bCorrect(iRun, iBlock, :)   = [Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) ...
                                    Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3))];
%             frameType(iRun, iBlock, :)  = [Shuffle(1:6) Shuffle(1:6) Shuffle(1:6) Shuffle(1:6) Shuffle(1:6) Shuffle(1:6)];
            fixFeature(iRun, iBlock, :) = [Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) ...
                                    Shuffle(1:4) Shuffle(1:4) Shuffle(1:4)];                                
            tBlipBlock(iRun, iBlock)    = ((30-2)*rand+2);
        end
        tBlipRest(iRun, :)          = ((8-2).*rand(1, 6)+2);
    end
    
%     ra.Experiment.Info.Set('ra', {'trialinfo', 'frametype'}, frameType);
    ra.Experiment.Info.Set('ra', {'trialinfo', 'bcorrect'}, bCorrect);
    ra.Experiment.Info.Set('ra', {'trialinfo', 'fixfeature'}, fixFeature);
    ra.Experiment.Info.Set('ra', 'rest_blip', tBlipRest);
    ra.Experiment.Info.Set('ra', 'block_blip', tBlipBlock);
    
    % set responses
    ra.Experiment.Input.Set('response', struct2cell(RA.Param('response'))');
    ra.Experiment.Input.Set('yes', RA.Param('response', 'yes'));
    ra.Experiment.Input.Set('no', RA.Param('response', 'no'));
    ra.Experiment.Input.Set('blip', RA.Param('response', 'blip'));

    ra.Experiment.Info.Set('ra','prepared',true);
    ra.Experiment.Info.Save;
    ra.Experiment.Subject.Save;

end