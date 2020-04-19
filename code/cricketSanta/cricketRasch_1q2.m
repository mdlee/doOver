%% Cricket Rasch
% v1: apply Rasch model to cricket Santa quiz
% answer to question 2

clear; close all;
preLoad = true;
printFigures = true;

%% Data
% data from: https://twitter.com/ZAbbasOfficial/status/1245593444468154369

dataName = 'cricketSanta';
load ../data/cricketSanta d

%% Constants
load pantoneColors pantone;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan';

% graphical model script
modelName = 'Rasch_1q2';

% parameters to monitor
params = {'delta'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('y', d.yMatrixCorrect, 'nQuestions', d.nQuestions, 'nPeople', d.nPeople);

% generator for initialization
generator = @()struct('theta', rand(1, d.nPeople));

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
    if ~isfolder('storage')
        !mkdir storage
    end
    save(sprintf('storage/%s', fileName), 'chains', 'stats', 'diagnostics', 'info');
    
    % convergence of each parameter
    disp('Convergence statistics:')
    grtable(chains, 1.05)
    
    % basic descriptive statistics
    disp('Descriptive statistics for all chains:')
    codatable(chains);
    
end

%% Analysis
fprintf('Probability person 1 has ability greater than person 127 is %1.2f\n', codatable(chains, 'delta', @mean));

