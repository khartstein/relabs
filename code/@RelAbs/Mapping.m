function Mapping(nif,varargin)
% NIF.Mapping
% 
% Description:	show the rule mapping
% 
% Syntax:	nif.Mapping(<options>)
%
% In:
%	<options>:
%		wait:	(true) true to wait for user input before returning
% 
% Updated: 06-26-2015
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

opt	= ParseArgs(varargin,   ...
		'wait'	, true     ...
		);

% get the rule mapping for the current subject
 	cStim	= nif.Experiment.Subject.Get('map_stim');
% open a texture
% 	sTexture	= switch2(nif.Experiment.Info.Get('nif','session'),1,800,2,1000);
%   sTexture    = 1000;
    nif.Experiment.Window.OpenTexture('mapping');  %[sTexture sTexture]

% Get labels for levels	
	strLevels	= NIF.Param('labels','level');
    strRules    = NIF.Param('labels', 'rulesets');
	
	for k=1:numel(cStim)
        % set up rule texture (6 rule images in 2 rows with level labels)
		if k<=3
            nif.Experiment.Show.Image(cStim{k},[16*(k-1)-16, -3],[16,12],'window','mapping');    
            nif.Experiment.Show.Text(['<size:1><style:normal><color:black>' strLevels(k) '</color></style></size>'],[16*(k-1)-16, -12],'window','mapping');
        elseif k>3 && k<=6
            nif.Experiment.Show.Image(cStim{k},[16*(k-4)-16,10],[16,12],'window','mapping')
        else
            error('too many rule images! should only have 6')
        end
    end
    % add ruleset labels
    nif.Experiment.Show.Text(['<size:1><style:normal><color:black>' strRules(1) '</color></style></size>'], [-21, -3],'window','mapping');
    nif.Experiment.Show.Text(['<size:1><style:normal><color:black>' strRules(2) '</color></style></size>'], [-21, 10],'window','mapping');
    
% 	if opt.wait
% 		fResponse	= [];
% 		strPrompt	= [];
% 	else
% 		fResponse	= false;
% 		strPrompt	= ' ';
%     end
    
    fResponse = conditional(opt.wait, [], false);
    strPrompt = conditional(opt.wait, [], ' ');
    
	nif.Experiment.Show.Instructions('',...
					'figure'	, 'mapping'	, ...
					'fresponse'	, fResponse	, ...
					'prompt'	, strPrompt	  ...
					);

% remove the texture
	nif.Experiment.Window.CloseTexture('mapping');
end	