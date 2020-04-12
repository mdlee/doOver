%% Bandit Win-Stay Lose-Shift
% v2: apply extended WSLS model to single-subject bandit

clear; close all;
preLoad = true;
printFigures = true;

%% Data
% data from: Lee, M.D., Zhang, S., Munro, M.N., & Steyvers, M. (2011).
% Psychological models of human and optimal performance on bandit problems.
% Cognitive Systems Research, 12, 164-174.
% [see OSF project https://osf.io/26m4z/]

dataName = 'bandit';
load ../data/bandit y r nGames nTrials

%% Constants
load pantoneColors pantone;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan';

% graphical model script
modelName = 'banditWSLS_2';

% parameters to monitor
params = {'alpha', 'beta', 'yPostpred'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('y', y, 'r', r, 'nGames', nGames, 'nTrials', nTrials);

% generator for initialization
generator = @()struct('alpha', rand*0.5 + 0.5);

%% Sample using Trinity
fileName = sprintf('%s_%s_%s.mat', modelName, dataName, engine);

if preLoad && isfile(sprintf('storage/%s', fileName))
    fprintf('Loading pre-stored samples for model %s on data %s\n', modelName, dataName);
    load(sprintf('storage/%s', fileName), 'chains', 'stats', 'diagnostics', 'info');
else
    tic; % start clock
    [stats, chains, diagnostics, info] = callbayes(engine, ...
        'model'           , sprintf('%s_%s.txt', modelName, engine)   , ...
        'data'            , data                                      , ...
        'outputname'      , 'samples'                                 , ...
        'init'            , generator                                 , ...
        'datafilename'    , modelName                                 , ...
        'initfilename'    , modelName                                 , ...
        'scriptfilename'  , modelName                                 , ...
        'logfilename'     , sprintf('tmp/%s', modelName)              , ...
        'nchains'         , nChains                                   , ...
        'nburnin'         , nBurnin                                   , ...
        'nsamples'        , nSamples                                  , ...
        'monitorparams'   , params                                    , ...
        'thin'            , nThin                                     , ...
        'workingdir'      , sprintf('tmp/%s', modelName)              , ...
        'verbosity'       , 0                                         , ...
        'saveoutput'      , true                                      , ...
        'parallel'        , doParallel                                );
    fprintf('%s took %f seconds!\n', upper(engine), toc); % show timing
    fprintf('Saving samples for model %s on data %s\n', modelName, dataName);
    save(sprintf('storage/%s', fileName), 'chains', 'stats', 'diagnostics', 'info');
    
    % convergence of each parameter
    disp('Convergence statistics:')
    grtable(chains, 1.05)
    
    % basic descriptive statistics
    disp('Descriptive statistics for all chains:')
    codatable(chains);
    
end

%% Analysis

% variables
yPostpred = get_matrix_from_coda(chains, 'yPostpred', @mean);

% constants
fontSize = 20;
binWidth = 0.005;
lineWidth = 3;

% posterior agreement descriptive adequacy
fprintf('Posterior accuracy is %1.2f\n', mean(yPostpred(:)));

% posterior figure
F = figure; clf; hold on;
set(F, ...
    'color'             , 'w'               , ...
    'units'             , 'normalized'      , ...
    'position'          , [0.2 0.2 0.6 0.6] , ...
    'papersize'         , [11 6.75]         , ...
    'paperpositionmode' , 'auto'            );

% axis
set(gca, ...
    'units'      , 'normalized'          , ...
    'position'   , [0.125 0.175 0.8 0.8] , ...
    'xlim'       , [0 1]                 , ...
    'xtick'      , 0:0.1:1               , ...
    'ycolor'     , 'none'                , ...
    'box'        , 'off'                 , ...
    'tickdir'    , 'out'                 , ...
    'layer'      , 'top'                 , ...
    'ticklength' , [0.01 0]              , ...
    'layer'      , 'top'                 , ...
    'fontsize'   , fontSize              );

% labels
xlabel('Win-Stay Lose-Shift Probabilities', 'fontsize', fontSize+4);

% draw posterior densities
densityAlpha = histcounts(chains.alpha(:), ...
    'binlimits'     , [0 1]    , ...
    'binwidth'      , binWidth , ...
    'normalization' , 'pdf'    );
patch([0 binWidth/2:binWidth:1-binWidth/2 1], [0 densityAlpha 0], 'k', ...
    'facecolor' , pantone.ClassicBlue , ...
    'edgecolor' , 'w'               , ...
    'facealpha' , 0.8               );
densityBeta = histcounts(chains.beta(:), ...
    'binlimits'     , [0 1]    , ...
    'binwidth'      , binWidth , ...
    'normalization' , 'pdf'    );
patch([0 binWidth/2:binWidth:1-binWidth/2 1], [0 densityBeta 0], 'k', ...
    'facecolor' , pantone.Custard   , ...
    'edgecolor' , 'w'               , ...
    'facealpha' , 0.8               );
% legend
legend('Win-Stay', 'Lose-Shift', ...
    'fontsize' , fontSize      , ...
    'location' , 'northwest'   , ...
    'box'      , 'off'         );


% tidy
set(gca, 'ylim', [0 max(max(densityAlpha), max(densityBeta))]);
Raxes(gca, 0.02, 0);

% print
if printFigures
    if ~isfolder('figures')
        !mkdir figures
    end
    warning off;
    print(sprintf('figures/%s_%s.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s.pdf', modelName, dataName), '-dpdf');
    warning on;
end


