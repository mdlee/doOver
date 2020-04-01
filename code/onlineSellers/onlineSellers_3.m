%% Online sellers
% v3: posterior predictive


clear; close all;
preLoad = true;
printFigures = true;

%% Data
% online ratings data from https://www.youtube.com/watch?v=8idr1WZ1A7Q

dataName = 'threeSellers';
k = [10 48 186];
n = [10 50 200];
nPostpred = 200;

%% Constants
nSellers = length(k);

load PantoneSpring2015 pantone;
sellerColors{1} = pantone.ClassicBlue;
sellerColors{2} = pantone.Marsala;
sellerColors{3} = pantone.Custard;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
% engine = 'stan';

% graphical model script
modelName = 'onlineSellers_3';

% parameters to monitor
params = {'kPostpred', 'piPostpred'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 5e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('k', k, 'n', n, 'nSellers', nSellers, 'nPostpred', nPostpred);

% generator for initialization
generator = @()struct('theta', rand(nSellers, 1));

%% Sample using Trinity
fileName = sprintf('%s_%s_%s.mat', modelName, dataName, engine);

if preLoad && exist(sprintf('storage/%s', fileName), 'file')
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

% posterior predictive mass greater or equal to third seller
piPostpred = codatable(chains, 'piPostpred', @mean);

% constants
fontSize = 22;
lineWidth = 3;
sellerLabel = cell(nSellers, 1);
for idx = 1:nSellers
    sellerLabel{idx} = sprintf('Seller %d: %d from %d', idx, k(idx), n(idx));
end

% colors, if not defined earlier
if ~exist('sellerColors', 'var')
    colors = fieldnames(pantone);
    sellerColors = cell(numel(colors), 1);
    for idx = 1:numel(colors)
        sellerColors{idx} = pantone.(sprintf('%s', colors{idx}));
    end
end

% figure
F = figure; clf; hold on;
set(F, ...
    'color'             , 'w'               , ...
    'units'             , 'normalized'      , ...
    'position'          , [0.2 0.1 0.6 0.85] , ...
    'papersize'         , [12 9.5]            , ...
    'paperpositionmode' , 'auto'            );

for sellerIdx = 1:2
    
    subplot(2, 1, sellerIdx); cla; hold on;
    % axis
    set(gca, ...
        'xlim'       , [-0.5 nPostpred+0.5]  , ...
        'xtick'      , 0:50:nPostpred             , ...
        'box'        , 'off'               , ...
        'tickdir'    , 'out'               , ...
        'layer'      , 'top'               , ...
        'ticklength' , [0.01 0]            , ...
        'layer'      , 'top'               , ...
        'fontsize'   , fontSize            );
    
    % labels
    if sellerIdx == 2
        xlabel('Positive Ratings', 'fontsize', fontSize+4);
    end
    ylabel('Probability', 'fontsize', fontSize+4);
    
    % draw posterior densities
    maxY = 0; % keep track of largest density
    mass = histcounts(chains.(sprintf('kPostpred_%d', sellerIdx))(:), ...
        'binlimits'     , [0 nPostpred+1]    , ...
        'binwidth'      , 1 , ...
        'normalization' , 'pdf'    );
    bar(0:nPostpred, mass, 1, ...
        'facecolor' , sellerColors{sellerIdx}, ...
        'edgecolor' , 'w');
    maxY = max(maxY, max(mass));
    
    % highlight actual data for third seller
    bar(k(3), mass(k(3)+1), 1, ...
        'facecolor' , sellerColors{3}, ...
        'edgecolor' , 'w');
    % tidy
    set(gca, 'ylim', [0 maxY], 'ytick', [0:0.01:round(maxY, 2)]);
    Raxes(gca, 0.01, 0);
    
    % legend
    legend(sellerLabel([sellerIdx 3]), ...
        'fontsize' , fontSize      , ...
        'location' , 'northwest'   , ...
        'box'      , 'off'         );
    
    % how much posterior predictive mass for comparison seller is above third seller?
    fprintf('Proprtion of posterior predictive mass\nfor Seller %d greater than or equal to Seller 3 is %1.2f\n', sellerIdx, piPostpred(sellerIdx));
    
end

% print
if printFigures
    warning off;
    print(sprintf('figures/%s_%s.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s.pdf', modelName, dataName), '-dpdf');
    warning on;
end

