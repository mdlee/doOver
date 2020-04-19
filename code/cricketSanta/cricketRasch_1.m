%% Cricket Rasch
% v1: apply Rasch model to cricket Santa quiz

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
modelName = 'Rasch_1';

% parameters to monitor
params = {'theta', 'beta', 'pi'};

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

% constants
fontSize = 20;
binWidth = 0.02;
lineWidth = 2;
scale = 0.1;
yLim = 4;
CI = 95;
highlight = [34 84];

% question posterior figure
F = figure; clf; hold on;
set(F, ...
    'color'             , 'w'               , ...
    'units'             , 'normalized'      , ...
    'position'          , [0.2 0.2 0.6 0.6] , ...
    'papersize'         , [11 6.75]         , ...
    'paperpositionmode' , 'auto'            );

% axis
set(gca, ...
    'units'      , 'normalized'           , ...
    'position'   , [0.125 0.175 0.8 0.8]  , ...
    'xlim'       , [0.5 d.nQuestions+0.5] , ...
    'xtick'      , 1:d.nQuestions         , ...
    'ylim'       , [-yLim yLim]           , ...
    'ytick'      , -yLim:yLim             , ...
    'box'        , 'off'                  , ...
    'tickdir'    , 'out'                  , ...
    'layer'      , 'top'                  , ...
    'ticklength' , [0.005 0]              , ...
    'layer'      , 'top'                  , ...
    'fontsize'   , fontSize               );

% labels
xlabel('Question', 'fontsize', fontSize+4);
ylabel('Difficulty', 'fontsize', fontSize+4);

% draw posterior densities
yBins = -yLim:binWidth:yLim;
for questionIdx = 1:d.nQuestions
    density = histcounts(chains.(sprintf('beta_%d', questionIdx))(:), ...
        'binlimits'     , [-yLim yLim] , ...
        'binwidth'      , binWidth     , ...
        'normalization' , 'pdf'        );
    for idx = 1:length(density)
        if density(idx) > 0
            plot(questionIdx+scale*[-density(idx) density(idx)], ones(1, 2)*yBins(idx), '-', ...
                'color'     , pantone.ClassicBlue , ...
                'linewidth' , lineWidth           );
        end
    end
end

% tidy
Raxes(gca, 0.02, 0.01);

% print
if printFigures
    if ~isfolder('figures')
        !mkdir figures
    end
    warning off;
    print(sprintf('figures/%s_%s_DifficultyPosterior.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s_DifficultyPosterior.pdf', modelName, dataName), '-dpdf');
    warning on;
end

% person posterior figure
F = figure; clf; hold on;
set(F, ...
    'color'             , 'w'               , ...
    'units'             , 'normalized'      , ...
    'position'          , [0.2 0.2 0.6 0.6] , ...
    'papersize'         , [11 6.75]         , ...
    'paperpositionmode' , 'auto'            );

% axis
xTickLabel = generateTickLabel(d.nPeople, [1 highlight d.nPeople]);
set(gca, ...
    'units'      , 'normalized'          , ...
    'position'   , [0.125 0.175 0.8 0.8] , ...
    'xlim'       , [0.5 d.nPeople+0.5]   , ...
    'xtick'      , 1:d.nPeople           , ...
    'xticklabel' , xTickLabel            , ...
    'ylim'       , [-yLim yLim]          , ...
    'ytick'      , -yLim:yLim            , ...
    'box'        , 'off'                 , ...
    'tickdir'    , 'out'                 , ...
    'layer'      , 'top'                 , ...
    'ticklength' , [0.005 0]             , ...
    'layer'      , 'top'                 , ...
    'fontsize'   , fontSize              );

% labels
xlabel('Person', 'fontsize', fontSize+4);
ylabel('Ability', 'fontsize', fontSize+4);

% draw posterior densities
mn = codatable(chains, 'theta', @mean);
for personIdx = 1:d.nPeople
    CIbounds =  prctile(chains.(sprintf('theta_%d', personIdx))(:), [(100-CI)/2 100-(100-CI)/2]);
    H = errorbar(personIdx, mn(personIdx), mn(personIdx)-CIbounds(1), CIbounds(2)-mn(personIdx), 'o-', ...
        'color'           , pantone.SeaFog   , ...
        'markerfacecolor' , pantone.DuskBlue , ...
        'markeredgecolor' , 'w'              );
    if ismember(personIdx, highlight)
        set(H, 'color', 'k');
    end
    
end

% tidy
Raxes(gca, 0.02, 0.01);

% print
if printFigures
    if ~isfolder('figures')
        !mkdir figures
    end
    warning off;
    print(sprintf('figures/%s_%s_AbilityPosterior.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s_AbilityPosterior.pdf', modelName, dataName), '-dpdf');
    warning on;
end

