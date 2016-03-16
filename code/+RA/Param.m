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
%       - double-check derived values (mostly timing stuff)
%       
% Example:
%	p = RA.Param('color','back');
%
% Updated: 02-22-2016
% Written by Kevin Hartstein (kevinhartstein@gmail.com)

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
					'text'      , [0 0 0]		, ...
                    'frame'     , [0 0 0 0]       ...
					);
        P.stim_size = struct(...
                    'sqside'        ,   1.5         ,   ...
                    'interstim'     ,   2.25        ,   ...
                    'offset'        ,   6               ...
                );
        P.stim_color = struct(...
                    'light'         ,   [156 156 156] , ...
                    'dark'          ,   [100 100 100]   ...
                     );
        P.stim_orient = struct(...
                    'vertical'  , [],   ...
                    'horizontal', []    ...
                    );
        P.stim_shape = struct(...
                    'square'    , [],   ...
                    'diamond'   , []    ...
                    );
        P.stim_number = struct(...
                    'two'         , 2,    ...
                    'four'        , 4     ...
                    );
    
    % feedback tr number is not currently used (9/8/15)
		P.time	= struct(...
					'tr'        , 2000	, ...
					'feedback'	, 1		, ...
                    'trialloop' , 16    , ...
					'rest'		, 2		, ...
                    'prompt'    , 2     , ...
                    'wait'      , 5     , ...
					'timeup'    , 1       ...
                    );
    % experiment info
		P.exp	= struct(...
					'nmrirunsperrep'        , 6     , ...
                    'ntrainrunsordered'     , 6     , ... 
                    'ntrainrunsmixed'       , 6     , ...
					'blocksperrun'          , 6     , ...
                    'reps'                  , 2		  ...
					);

    % text
		P.text	= struct(...
					'font'	, 'Helvetica'			, ...
					'size'	, 0.75*SIZE_MULTIPLIER	  ...
					);
                    
	% response buttons for training
        P.responseTrain     = struct(...
                    'yes'   , 'left'    ,   ...
                    'no'    , 'right'   ,   ...
                    'blip'  , 'down'        ...
                    );  
	% response buttons for MRI
        P.responseMRI       = struct(...
                    'yes'   , 'lright'   ,   ...                            % Green button
                    'no'    , 'rright'   ,   ...                            % Red button
                    'blip'  , 'lleft'        ...                            % Blue button
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
                case 'framesize'
                    p = 4.5*(P.stim_size.interstim); 
                case 'ntrainruns'
                    p   = RA.Param('exp', 'ntrainrunsordered') + RA.Param('exp', 'ntrainrunsmixed');
                case 'nmriruns'
                    p   = RA.Param('exp', 'nmrirunsperrep') * RA.Param('exp', 'reps');
                case 'trblock'
					p	= P.time.prompt + P.time.wait + P.time.trialloop + P.time.timeup + RA.Param('time', 'rest');
				case 'trrun'
					p	= RA.Param('time', 'rest') + RA.Param('exp', 'blocksperrun')*(RA.Param('trblock'));
				case 'trtotal'
					p	= P.exp.nmrirunsperrep*P.reps*RA.Param('trrun');
				case 'trun'
					p	= RA.Param('trrun')*RA.Param('time','tr')/1000/60;
				case 'ttotal'
					p	= RA.Param('trtotal')*RA.Param('time','tr')/1000/60;
				case 'tblock'
					p	= RA.Param('trblock')*RA.Param('time', 'tr')*RA.Param('blocksperrun')/1000/60;
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
