%% Online sellers
% v2: finds probabilities each seller is better than each other


clear; close all;
preLoad = true;
printFigures = true;

%% Data
% online ratings data from https://www.youtube.com/watch?v=8idr1WZ1A7Q

dataName = 'threeSellers';
k = [10 48 186];
n = [10 50 200];

%% Constants
nSellers = length(k);

load PantoneSpring2015 pantone;
sellerColors{1} = pantone.ClassicBlue;
sellerColors{2} = pantone.ToastedAlmond;
sellerColors{3} = pantone.Custard;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
% engine = 'stan'; 

% graphical model script
modelName = 'onlineSellers_2';

% parameters to monitor
params = {'pi'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('k', k, 'n', n, 'nSellers', nSellers);

% generator for initialization
generator = @()struct('theta', rand(nSellers, 1));

%% Sample using Trinity
fileName = sprintf('%s_%s_%s.mat', modelName, dataName, engine);

if preLoad && exist(sprintf('storage/%s_%s', fileName), 'file')
    fprintf('Loading pre-stored samples for model %s on data %s\n', modelName, dataName);
    load(sprintf('storage/%s', fileName), 'chains', 'stats', 'chains', 'diagnostics', 'info');
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
        'logfilename'     , modelName                                 , ...
        'nchains'         , nChains                                   , ...
        'nburnin'         , nBurnin                                   , ...
        'nsamples'        , nSamples                                  , ...
        'monitorparams'   , params                                    , ...
        'thin'            , nThin                                     , ...
        'workingdir'      , sprintf('/tmp/%s', modelName)             , ...
        'verbosity'       , 0                                         , ...
        'saveoutput'      , true                                      , ...
        'parallel'        , doParallel                                );
    fprintf('%s took %f seconds!\n', upper(engine), toc); % show timing
    fprintf('Saving samples for model %s on data %s\n', modelName, dataName);
    save(sprintf('storage/%s', fileName), 'chains', 'stats', 'chains', 'diagnostics', 'info');
end

%% Inspect the results

% convergence of each parameter
disp('Convergence statistics:')
grtable(chains, 1.05)

% basic descriptive statistics
disp('Descriptive statistics for all chains:')
codatable(chains);

%% Analysis

sellerLabel = cell(nSellers, 1);
for idx = 1:nSellers
    sellerLabel{idx} = sprintf('Seller %d', idx);
end

pi = get_matrix_from_coda(chains, 'pi', @mean); 
probabilityTable(pi, sellerLabel, fileName, inf);