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
modelName = 'banditWSLS_4';

% parameters to monitor
params = {'z'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('y', y, 'r', r, 'nGames', nGames, 'nTrials', nTrials);

% generator for initialization
generator = @()struct('z', ceil(rand*3));

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

postProbs = histcounts(chains.z(:), 0.5:1:3.5, 'normalization', 'probability');
fprintf('\nPosterior probability of basic WSLS model = %1.2f\n', postProbs(1));
fprintf('Posterior probability of extended WS vs LS model = %1.2f\n', postProbs(2));
fprintf('Posterior probability of extended WS vs LS with trial-dependent LS model = %1.2f\n', postProbs(3));