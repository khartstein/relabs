function Prepare(ra,varargin)
% RelAbs.Prepare
%
% Description: prepare to run an ra session
%
% Syntax: ra.Prepare()
%
% ToDo:         
%           - 
%
% Updated: 04-08-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

% get experiment info from params
    session             = ra.Experiment.Info.Get('ra', 'session');
    nMRIRuns            = RA.Param('nmriruns');
    nTrainRuns          = RA.Param('ntrainruns');
    nTrainRunsOrdered   = RA.Param('exp', 'ntrainrunsordered');
    nTrainRunsMixed     = RA.Param('exp', 'ntrainrunsmixed');
    nBlocksPerRun       = RA.Param('exp', 'blocksperrun'); 

    cBlocks = 1:nBlocksPerRun;
    
    bBlockOrderExists = ~isempty(ra.Experiment.Subject.Get('mri_block_order'));
    if bBlockOrderExists
        strOrderExist   = 'existing';
    elseif ra.Experiment.Info.Get('experiment', 'debug') < 2
        % running for real, initial training session run ordered, rest 
        % counterbalanced. MRI runs counterbalanced
        trainBlockOrder                                     = zeros(nTrainRuns, nBlocksPerRun);
        trainBlockOrder(1:nTrainRunsOrdered, :)             = repmat(cBlocks, nTrainRunsOrdered, []);
        trainBlockOrder(nTrainRunsOrdered+1:nTrainRuns, :)  = blockdesign(cBlocks, 1, nTrainRunsMixed);
        mriBlockOrder                                       = blockdesign(cBlocks, 1, nMRIRuns);
        ra.Experiment.Subject.Set('train_block_order', trainBlockOrder);
        ra.Experiment.Subject.Set('mri_block_order', mriBlockOrder);
        strOrderExist   = 'new';
    else
        % debug mode, 1:6 in order for all runs in training and "MRI"
        trainBlockOrder                                     = zeros(nTrainRuns, nBlocksPerRun);
        trainBlockOrder(1:nTrainRuns, :)                    = repmat(cBlocks, nTrainRuns, []);
        mriBlockOrder                                       = repmat(cBlocks, nMRIRuns);
        ra.Experiment.Subject.Set('train_block_order', trainBlockOrder);
        ra.Experiment.Subject.Set('mri_block_order', mriBlockOrder);
        strOrderExist = 'default';
    end
    
    ra.Experiment.AddLog(['using ' strOrderExist ' block order']);
    
    % set run, block
    ra.Experiment.Info.Set('ra', 'run', 1);
    ra.Experiment.Info.Set('ra', 'block', 1);
    % set timing and blip results for training session
    ra.Experiment.Info.Set('ra', 'train_blocktiming', cell(nTrainRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'train_result', cell(nTrainRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'train_blipresulttask', zeros(nTrainRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'train_blipresultrest', zeros(nTrainRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'train_runtiming', cell(nTrainRuns, 1));
    ra.Experiment.Info.Set('ra', 'train_practiceresult', []);
    % set timing and blip results for mri session
    ra.Experiment.Info.Set('ra', 'mri_blocktiming', cell(nMRIRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'mri_result', cell(nMRIRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'mri_blipresulttask', zeros(nMRIRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'mri_blipresultrest', zeros(nMRIRuns, nBlocksPerRun));
    ra.Experiment.Info.Set('ra', 'mri_runtiming', cell(nMRIRuns, 1));
    ra.Experiment.Info.Set('ra', 'mri_practiceresult', []);
    
    % set trial information
    bCorrectMRI     = zeros(nMRIRuns, nBlocksPerRun, 36);
    fixFeatureMRI   = zeros(nMRIRuns, nBlocksPerRun, 36);
    tBlipRestMRI    = zeros(nMRIRuns, nBlocksPerRun);
    tBlipBlockMRI   = zeros(nMRIRuns, nBlocksPerRun);
    
    bCorrectTrain   = zeros(nTrainRuns, nBlocksPerRun, 36);
    fixFeatureTrain = zeros(nTrainRuns, nBlocksPerRun, 36);
    tBlipRestTrain  = zeros(nTrainRuns, nBlocksPerRun);
    tBlipBlockTrain = zeros(nTrainRuns, nBlocksPerRun);
    
    % set up correct, fix features, blips for training session
    for iTrainRun = 1:nTrainRuns
        for iBlock = 1:nBlocksPerRun
            bCorrectTrain(iTrainRun, iBlock, :) = [Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) ...
                                    Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3))];
            fixFeatureTrain(iTrainRun, iBlock, :)    = [Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) ...
                                    Shuffle(1:4) Shuffle(1:4) Shuffle(1:4)];
            tBlipBlockTrain(iTrainRun, iBlock)       = ((30-2)*rand+2);
        end
        tBlipRestTrain(iTrainRun, :)          = ((8-2).*rand(1, nBlocksPerRun)+2);
    end
    
    % set up correct, fix features, blips for mri session
    for iRun = 1:nMRIRuns
        for iBlock = 1:nBlocksPerRun
            bCorrectMRI(iRun, iBlock, :)   = [Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) ...
                                    Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3)) Shuffle(repmat(0:1, 1, 3))];
            fixFeatureMRI(iRun, iBlock, :) = [Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) Shuffle(1:4) ...
                                    Shuffle(1:4) Shuffle(1:4) Shuffle(1:4)];                                
            tBlipBlockMRI(iRun, iBlock)    = ((30-2)*rand+2);
        end
        tBlipRestMRI(iRun, :)          = ((8-2).*rand(1, nBlocksPerRun)+2);
    end
    
    % set info for training session
    ra.Experiment.Info.Set('ra', {'train_trialinfo', 'bcorrect'}, bCorrectTrain);
    ra.Experiment.Info.Set('ra', {'train_trialinfo', 'fixfeature'}, fixFeatureTrain);
    ra.Experiment.Info.Set('ra', 'train_rest_blip', tBlipRestTrain);
    ra.Experiment.Info.Set('ra', 'train_block_blip', tBlipBlockTrain);
    
    % set info for MRI session
    ra.Experiment.Info.Set('ra', {'mri_trialinfo', 'bcorrect'}, bCorrectMRI);
    ra.Experiment.Info.Set('ra', {'mri_trialinfo', 'fixfeature'}, fixFeatureMRI);
    ra.Experiment.Info.Set('ra', 'mri_rest_blip', tBlipRestMRI);
    ra.Experiment.Info.Set('ra', 'mri_block_blip', tBlipBlockMRI);
    
    % set responses
    strSession  = switch2(session, 1, 'Train', 2, 'MRI', []);
    ra.Experiment.Input.Set('response', {RA.Param(['response' strSession], 'yes'), RA.Param(['response' strSession], 'no')});
    ra.Experiment.Input.Set('yes', RA.Param(['response' strSession], 'yes'));
    ra.Experiment.Input.Set('no', RA.Param(['response' strSession], 'no'));
    ra.Experiment.Input.Set('blip', RA.Param(['response' strSession], 'blip'));

    ra.Experiment.Info.Set('ra','prepared',true);
    ra.Experiment.Info.Save;
    ra.Experiment.Subject.Save;
end