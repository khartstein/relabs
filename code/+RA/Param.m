function p = Param(varargin)
% RA.Param
% 
% Description:	get an RA parameter
% 
% Syntax:	p = RA.Param(f1,...,fN)
% 
% In:
% 	fK	- the the Kth parameter field
% 
% Out:
% 	p	- the parameter value
%
% ToDo:      
%
% Example:
%	p = RA.Param('color','back');
% 
% Updated: 09-01-2015

global SIZE_MULTIPLIER;
persistent P;

if isempty(SIZE_MULTIPLIER)
	SIZE_MULTIPLIER	= 1;
end


if isempty(P)
	% stimulus parameters
		P.color	= struct(...
					'back'      , [128 128 128]	, ...
					'fore'      , [0 0 0]		, ...
					'text'      , [0 0 0]		  ...
					);
        P.stim_size = struct(...
                    'area'          ,   2.5         ,   ...
                    'circradius'    ,   sqrt(2.5/pi),   ...
                    'sqside'        ,   sqrt(2.5)   ,   ...
                    'interstim'     ,   2               ...
                    );
        P.stim_color = struct(...
                    'deepskyblue'   ,   [0 128 255] , ...
                    'red'           ,   [255 0 0]   ...
                     );
        P.stim_orient = struct(...
                    'vertical'  , [],   ...
                    'horizontal', []    ...
                    );
        P.stim_shape = struct(...
                    'rectangle' , [],   ...
                    'circle'    , []    ...
                    );
        P.stim_number = struct(...
                    'two'         , 2,    ...
                    'four'        , 4     ...
                    );
    
    % screen locations
        P.screenlocs = struct(...
                    'topcenter'     ,   [0, -5]     ,       ...
                    'bottomcenter'  ,   [0,  5]             ...
                    );
    
    % timing  - CHANGE trialloop BACK TO 16 AFTER TESTING
		P.time	= struct(...
					'tr'        , 2000	, ...
					'feedback'	, 1		, ...
                    'trial'     , 3     , ...
                    'trialloop' , 4    , ...
                    'blank'     , 1     , ...
					'rest'		, 2		, ...
                    'prompt'    , 2     , ...
                    'wait'      , 4     , ...
					'timeup'    , 1       ...
                    );
    % experiment info
		P.exp	= struct(...
					'runs'      , 12	, ...
					'blocks'    , 8     , ...
                    'reps'      , 1		  ...
					);

        P.conditions = struct(...
                    'same'      ,   []  ,   ...
                    'different' ,   []      ...
                    );
    % text
		P.text	= struct(...
					'font'	, 'Helvetica'			, ...
					'size'	, 0.75*SIZE_MULTIPLIER	  ...
					);
	% reward
		P.reward	= struct(...
                    'base'		, 20	, ...
                    'max'		, 40	, ...
                    'penalty'	, 2		  ... %penalty is <- times the reward
                    );
                    
	% response buttons
        P.response = struct(...
                    'yes'   , 'left'    ,   ...
                    'no'    , 'right'       ...
                    );  

	% stuff for transfer entropy calculations - ?
% 		P.te		= struct(...
% 						'block'	, 5	  ...	% number of samples to use per trial
% 						);
end

p	= P;

for k=1:nargin
	v	= varargin{k};
	
	switch class(v)
		case 'char'
			switch v
                case 'sizemultiplier'
					p	= SIZE_MULTIPLIER;
                case 'smallXOffset'
                    p = [0.5*P.stim_size.interstim 0];
                case 'largeXOffset'
                    p = [1.5*P.stim_size.interstim 0];
                case 'smallYOffset'
                    p = [0 0.5*P.stim_size.interstim];
                case 'largeYOffset'
                    p = [0 1.5*P.stim_size.interstim];
                case 'blockperrun'
					p	= P.exp.blocks*P.exp.reps;
				case 'trblock'
					p	= P.time.prompt + P.time.wait + P.time.trialloop + RA.Param('time', 'rest');
				case 'trrun'
					nBlock	= RA.Param('blockperrun');
					
					p	= RA.Param('time', 'rest') + nBlock*(RA.Param('trblock') + RA.Param('time', 'rest'));
				case 'trtotal'
					p	= P.exp.runs*RA.Param('trrun');
				case 'trun'
					p	= RA.Param('trrun')*RA.Param('time','tr')/1000/60;
				case 'ttotal'
					p	= RA.Param('trtotal')*RA.Param('time','tr')/1000/60;
				case 'tblock'
					p	= RA.Param('trblock')*RA.Param('time', 'tr')*RA.Param('blockperrun')/1000/60;
				case 'rewardpertrial'
					p	= 0.06;
				case 'penaltypertrial'
					p	= RA.Param('rewardpertrial')*P.reward.penalty;
				otherwise
					if isfield(p,v)
						p	= p.(v);
					else
						p	= [];
						return
					end
			end
		otherwise
			if iscell(p)
				p	= p{v};
			else
				p	= [];
				return;
			end
	end
end
