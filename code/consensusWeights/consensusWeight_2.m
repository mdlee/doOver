%% Consensus weight
% v2: product-space Bayes factors

clear; close all;
preLoad = true;
printFigures = false;

%% Data
% data from: Lee, M.D., & Shi, J. (2010).  The accuracy of small-group
% estimation and the wisdom of crowds. In R. Catrambone, & S. Ohlsson
% (Eds.), Proceedings of the 32nd Annual Conference of the Cognitive
% Science Society, pp. 1124-1129. Austin, TX: Cognitive Science Society.
% [see OSF project https://osf.io/p29vn/]

dataName = 'consensusEstimation';
load ../data/consensusEstimation g x y totalTrials nGroups
pi = [(1-1e-6) 1e-6 1e-6 1e-6 (1-1e-6)];

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan';

% graphical model script
modelName = 'consensusWeight_2';

% parameters to monitor
params = {'z'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 100;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('y', y, 'x', x, 'g', g, 'totalTrials', totalTrials, 'nGroups', nGroups, 'pi', pi);

% generator for initialization
generator = @()struct('theta', rand(nGroups, 1)*0.5 + 1);

%% Sample using Trinity
fileName = sprintf('%s_%s_%s.mat', modelName, dataName, engine);

if preLoad && exist(sprintf('storage/%s', fileName), 'file')
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

%% Bayes factor inferences

% posterior probabilities
pHat = codatable(chains, 'z', @mean);

% bayes factors
BF = pHat./(1-pHat) .* ((1-pi)./pi)';

for idx = 1:nGroups
    if BF(idx) > 1
        fprintf('Estimated Bayes factor for Group %d in favor of the averaging model is %1.0f\n', idx, BF(idx));
    else
        fprintf('Estimated Bayes factor for Group %d in favor of the weighted model is %1.0f\n', idx, 1/BF(idx));
        
    end
end



