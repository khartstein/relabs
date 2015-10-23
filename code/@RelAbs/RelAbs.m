classdef RelAbs < PTB.Object
% RelAbs
%
% Description: the relabs experiment object
%
% Syntax RA = RelAbs(<options>)
%
%       subfunctions:
%				Start(<options>):	start the object
%				End:				end the object
%               Prepare:            prepare necessary info
%               Run:                execute a nestif run
%
% In:
% 	<options>:
%       debug:		(0) the debug level
%
% Out: 
%
% Updated 09-03-2015
% Writted by Kevin Hartstein (kevinhartstein@gmail.com)

	% PUBLIC PROPERTIES---------------------------------------------------------%
	properties
		Experiment;
		% images
        colorIcon       = [];
        numberIcon      = [];
        orientationIcon = [];
        shapeIcon       = [];
        
		% running reward total
		reward; 
	end
	% PUBLIC PROPERTIES---------------------------------------------------------%
	
	
	% PRIVATE PROPERTIES--------------------------------------------------------%
	properties (SetAccess=private, GetAccess=private)
		argin;
	end
	% PRIVATE PROPERTIES--------------------------------------------------------%
	
	
	% PROPERTY GET/SET----------------------------------------------------------%
	methods
		
    end
    % PROPERTY GET/SET----------------------------------------------------------%
	
    
    % PUBLIC METHODS------------------------------------------------------------%
	methods
		function ra = RelAbs(varargin)
			ra	= ra@PTB.Object([],'relabs');
			
			ra.argin	= varargin;
			
			% parse the inputs
			opt = ParseArgs(varargin,...
				'debug'			,   0   , 	  ...
				'session'       ,   []        ...
                );
			
            if isempty(opt.session)
				opt.session	= conditional(opt.debug==2,1,2);
			end
            
			opt.name	= 'relabs';
            opt.context	= switch2(opt.session,1,'psychophysics',2,'fmri');
            opt.input_scheme = 'lrud';
            opt.text_size = RA.Param('text', 'instructSize');
            opt.text_color = RA.Param('text', 'color');
			
			% window
            opt.background	= RA.Param('color','back');
            opt.text_color	= RA.Param('color','text');
            opt.text_size	= RA.Param('text','size');
            opt.text_family	= RA.Param('text','font');
			
			% options for PTB.Experiment object
			cOpt = opt2cell(opt);
			
			% initialize the experiment
			ra.Experiment	= PTB.Experiment(cOpt{:});
			
            % set the session
            ra.Experiment.Info.Set('ra','session',opt.session);
            
			% start
			ra.Start;
		end
		%----------------------------------------------------------------------%
		function Start(ra,varargin)
		%start the nestif object
			ra.argin	= append(ra.argin,varargin);
			
			if isempty(ra.Experiment.Info.Get('ra','prepared'))
				%prepare info
				ra.Prepare(varargin{:});
			end
		end
		%----------------------------------------------------------------------%
		function End(ra,varargin)
		%end the nestif object
			v	= varargin;
            
			ra.Experiment.End(v{:});
		end
		%----------------------------------------------------------------------%
	end
	%PUBLIC METHODS------------------------------------------------------------%    
end