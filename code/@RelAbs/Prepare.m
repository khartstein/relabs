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
% Updated: 08-31-2015
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
        blockOrder = blockdesign(cBlocks, nRep, nRun);
        ra.Experiment.Subject.Set('block_order', blockOrder);
        strOrderExist = 'new';
    else
        % debug mode, 1:8 in order for all runs
        blockOrder = repmat(cBlocks, nRun, nRep);
        ra.Experiment.Subject.Set('block_order', blockOrder);
        strOrderExist = 'default';
    end
    
    ra.Experiment.AddLog(['using ' strOrderExist ' block order']);
    
    % set run, block, results
    ra.Experiment.Info.Set('ra', 'run', 1);
    ra.Experiment.Info.Set('ra', 'block', 1);
    ra.Experiment.Info.Set('ra', 'result', cell(RA.Param('exp', 'runs'), RA.Param('blocksperrun')));
    ra.Experiment.Info.Set('ra', 'timing', cell(RA.Param('exp', 'runs'), 1));
    ra.reward	= RA.Param('reward','base');
    
    % set trial information
    numSame = zeros(nRun, nBlock, 32);
    for iRun = 1:nRun
        for iBlock = 1:nBlock
            numSame(iRun, iBlock, :) = [Shuffle(repmat(1:4, 1, 2)) Shuffle(repmat(1:4, 1, 2)) ...
            Shuffle(repmat(1:4, 1, 2)) Shuffle(repmat(1:4, 1, 2))];
        end
    end
    ra.Experiment.Info.Set('ra', {'trial', 'numSame'}, numSame);
    
    % set nCorrect if not already available (Get it if it is available?)
    % check if this is really necessary
    bnCorrectExists = ~isempty(ra.Experiment.Info.Get('ra', 'nCorrect'));
    if ~bnCorrectExists
        ra.Experiment.Subject.Set('ra', 'nCorrect', 0);
        ra.Experiment.AddLog('Setting nCorrect to 0');
    end
    
    %load some images
	strDirImage             = DirAppend(ra.Experiment.File.GetDirectory('code'),'@RelAbs','Images');

	strPathColor            = PathUnsplit(strDirImage,'RA_color','png');
    [imColor, ~, alpha]     = imread(strPathColor);
    imColor(:,:,4)          = alpha;
    ra.colorIcon            = imColor;
    
    strPathNumber           = PathUnsplit(strDirImage, 'RA_number', 'png');
    [imNumber, ~, alpha]    = imread(strPathNumber);
    imNumber(:,:,4)         = alpha;
    ra.numberIcon           = imNumber;
    
    strPathOrientation      = PathUnsplit(strDirImage, 'RA_orientation', 'png');
    [imOrientation,~, alpha]= imread(strPathOrientation);
    imOrientation(:,:,4)    = alpha;
    ra.orientationIcon      = imOrientation;
    
    strPathShape           = PathUnsplit(strDirImage, 'RA_shape', 'png');
    [imShape, ~, alpha]    = imread(strPathShape);
    imShape(:,:,4)         = alpha;
    ra.shapeIcon           = imShape;
    
    % set responses
    ra.Experiment.Input.Set('response', struct2cell(RA.Param('response'))');
    ra.Experiment.Input.Set('yes', RA.Param('response', 'yes'));
    ra.Experiment.Input.Set('no', RA.Param('response', 'no'));

    ra.Experiment.Info.Set('ra','prepared',true);
    ra.Experiment.Info.Save;
    ra.Experiment.Subject.Save;

end