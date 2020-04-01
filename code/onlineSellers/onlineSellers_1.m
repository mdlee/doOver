%% Online sellers
% v1: underlying rate inference

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
sellerColors{2} = pantone.Marsala;
sellerColors{3} = pantone.Custard;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan'; 

% graphical model script
modelName = 'onlineSellers_1';

% parameters to monitor
params = {'theta'};

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
        'logfilename'     , sprintf('/tmp/%s', modelName)             , ...
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

% constants
fontSize = 20;
binWidth = 0.01;
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
    'position'          , [0.2 0.2 0.6 0.6] , ...
    'papersize'         , [11 6.75]            , ...
    'paperpositionmode' , 'auto'            );

% axis
set(gca, ...
    'units'      , 'normalized'        , ...
    'position'   , [0.125 0.175 0.8 0.8] , ...
    'xlim'       , [0 1]               , ...
    'xtick'      , 0:0.1:1             , ...
    'box'        , 'off'               , ...
    'tickdir'    , 'out'               , ...
    'layer'      , 'top'               , ...
    'ticklength' , [0.01 0]            , ...
    'layer'      , 'top'               , ...
    'fontsize'   , fontSize            );

% labels
xlabel('Rate', 'fontsize', fontSize+4);
ylabel('Density', 'fontsize', fontSize+4);

% draw posterior densities
maxY = 0; % keep track of largest density
for idx = 1:nSellers
    density = histcounts(chains.(sprintf('theta_%d', idx))(:), ...
        'binlimits'     , [0 1]    , ...
        'binwidth'      , binWidth , ...
        'normalization' , 'pdf'    );
    patch([0 binWidth/2:binWidth:1-binWidth/2 1], [0 density 0], 'k', ...
        'facecolor' , sellerColors{idx} , ...
        'edgecolor' , 'w'               , ...
        'facealpha' , 0.6               );
    maxY = max(maxY, max(density));
end

% tidy
set(gca, 'ylim', [0 maxY], 'ytick', [0 floor(maxY)]);
Raxes(gca, 0.02, 0);

% legend
legend(sellerLabel, ...
    'fontsize' , fontSize      , ...
    'location' , 'northwest'   , ...
    'box'      , 'off'         );

% print
if printFigures
    warning off;
    print(sprintf('figures/%s_%s.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s.pdf', modelName, dataName), '-dpdf');
    warning on;
end

