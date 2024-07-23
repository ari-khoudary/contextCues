%% set up psychtoolbox variables

% create outfiles (.csvs for each phase)
setup_output;

% keyboard responses (top row only)
setup_keyboard;

% screen initialization & aesthetics
setup_screen;

% mapping of buttons to scene images
setup_stimuli; 
%%% this is fine here for now, but if/when we expand to have different expectations in different blocks it will have to be re-modularized; need to ensure that images are not repeated across blocks
