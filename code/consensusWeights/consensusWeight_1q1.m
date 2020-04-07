%% Consensus Weight
% v1: apply Social Judgment Scheme model to consensus data, as in:
%
% Ohtsubo, Y., Masuchi, A., & Nakanishi, D. (2002).
% Majority influence process in group judgment: Test of the
% social judgment scheme model in a group polarization context.
% Group processes & intergroup relations, 5(3), 249-261.

clear; close all;
preLoad = false;
printFigures = false;

%% Data
% data from: Lee, M.D., & Shi, J. (2010).  The accuracy of small-group
% estimation and the wisdom of crowds. In R. Catrambone, & S. Ohlsson
% (Eds.), Proceedings of the 32nd Annual Conference of the Cognitive
% Science Society, pp. 1124-1129. Austin, TX: Cognitive Science Society.
% [see OSF project https://osf.io/p29vn/]

dataName = 'consensusEstimation';
load ../data/consensusEstimation g x y totalTrials nGroups
nMembers = 3;

%% Constants
load pantoneColors pantone;
groupColors{1} = pantone.ClassicBlue;
groupColors{2} = pantone.IslandParadise;
groupColors{3} = pantone.Custard;
groupColors{4} = pantone.CelosiaOrange;
groupColors{5} = pantone.LushMeadow;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan';

% graphical model script
modelName = 'consensusWeight_1q1';

% parameters to monitor
params = {'theta', 'yPostpred'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 1e3;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

% assign MATLAB variables to the observed nodes
data = struct('y', y, 'x', x, 'g', g, 'totalTrials', totalTrials, 'nGroups', nGroups, 'nMembers', nMembers);

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


%% Analysis

% constants
fontSize = 20;
binWidth = 0.005;
lineWidth = 3;
groupLabel = cell(nGroups, 1);
for idx = 1:nGroups
    groupLabel{idx} = sprintf('Group %d', idx);
end

% colors, if not defined earlier
if ~exist('groupColors', 'var')
    colors = fieldnames(pantone);
    groupColors = cell(numel(colors), 1);
    for idx = 1:numel(colors)
        groupColors{idx} = pantone.(sprintf('%s', colors{idx}));
    end
end

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
xlabel('Decay', 'fontsize', fontSize+4);

% draw posterior densities
maxY = 0; % keep track of largest density
for idx = 1:nGroups
    density = histcounts(chains.(sprintf('theta_%d', idx))(:), ...
        'binlimits'     , [0 1]    , ...
        'binwidth'      , binWidth , ...
        'normalization' , 'pdf'    );
    patch([0 binWidth/2:binWidth:1-binWidth/2 1], [0 density 0], 'k', ...
        'facecolor' , groupColors{idx} , ...
        'edgecolor' , 'w'               , ...
        'facealpha' , 0.8               );
    maxY = max(maxY, max(density));
end

% tidy
set(gca, 'ylim', [0 maxY]);
Raxes(gca, 0.02, 0);

% legend
legend(groupLabel, ...
    'fontsize' , fontSize      , ...
    'location' , 'northeast'   , ...
    'box'      , 'off'         );

% print
if printFigures
    warning off;
    print(sprintf('figures/%s_%s.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s.pdf', modelName, dataName), '-dpdf');
    warning on;
end

