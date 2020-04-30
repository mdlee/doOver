%% Simple crowd aggregate of NBA predictions
% all teams, different expertise for each conference

clear; close all;
preLoad = true;
printFigures = true;

%% Data
dataName= 'NBA2015';
load ../data/basketball2015 d

%% Constants
load pantoneColors pantone;

%% MCMC sampling from graphical model

% which engine to use
engine = 'jags';
%engine = 'stan';

% graphical model script
modelName = 'crowdNBA_2q2';

% parameters to monitor
params = {'mu', 'sigma', 'delta', 'deltaPrime'};

% MCMC properties
nChains    = 8;     % number of MCMC chains
nBurnin    = 1e3;   % number of discarded burn-in samples
nSamples   = 1e4;   % number of collected samples
nThin      = 1;     % number of samples between those collected
doParallel = 1;     % whether MATLAB parallel toolbox parallizes chains

if strmatch(engine, 'stan')
    nSamples = nSamples * nThin;
end

% assign MATLAB variables to the observed nodes
data = struct(...
            'y'       , d.predictions , ...
            'nPeople' , d.nPeople     , ...
            'nTeams'  , d.nTeams      , ...
            'truth'   , d.truth       , ...
            'z'       , d.conference  );

% generator for initialization
generator = @()struct('sigma' , rand(d.nPeople, 2));

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
        'allowunderscores', true                                      , ...
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

if strmatch(engine, 'stan')
    nSamples = nSamples / nThin;
end


%% Analysis


% constants
fontSize = 20;
lo = 0; hi = 0.24; xTick = lo:0.02:hi;
binWidth = 0.001;
CI = 95;

% means and CIs for expertise
sigma = nan(d.nPeople, 2, 3); % 2nd dimensions: east vs west; 3rd dimension: mean, lower CI bound, upper CI bound
sigma(:, :, 1) = get_matrix_from_coda(chains, 'sigma', @mean);
for idx = 1:d.nPeople
CIbounds =  prctile(chains.(sprintf('sigma_%d_1', idx))(:), [(100-CI)/2 100-(100-CI)/2]);
sigma(idx, 1, 2:3) = CIbounds;
CIbounds =  prctile(chains.(sprintf('sigma_%d_2', idx))(:), [(100-CI)/2 100-(100-CI)/2]);
sigma(idx, 2, 2:3) = CIbounds;
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
    'xlim'       , [lo hi]               , ...
    'xtick'      , xTick                 , ...
    'ycolor'     , 'none'                , ...
    'box'        , 'off'                 , ...
    'tickdir'    , 'out'                 , ...
    'layer'      , 'top'                 , ...
    'ticklength' , [0.01 0]              , ...
    'layer'      , 'top'                 , ...
    'fontsize'   , fontSize              );

% labels
xlabel('Accuracy of Crowd Prediction', 'fontsize', fontSize+4);

% draw posterior densities
    density = histcounts(chains.deltaPrime(:), ...
        'binlimits'     , [lo hi]  , ...
        'binwidth'      , binWidth , ...
        'normalization' , 'pdf'    );
    patch([lo lo+binWidth/2:binWidth:hi-binWidth/2 hi], [0 density 0], 'k', ...
        'facecolor' , pantone.ClassicBlue , ...
        'edgecolor' , 'w'                 , ...
        'facealpha' , 0.8                 );
    
    % performance of mean
   plot(ones(1, 2)*mean(abs(mean(d.predictions)-d.truth)), [0 max(density)], '--', ...
       'color'     , pantone.Titanium , ...
       'linewidth' , 1                );

% tidy
set(gca, 'ylim', [0 max(density)]);
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

% expertise figure
F = figure; clf; hold on;
set(F, ...
    'color'             , 'w'               , ...
    'units'             , 'normalized'      , ...
    'position'          , [0.3 0.2 0.4 0.6] , ...
    'papersize'         , [11 6.75]         , ...
    'paperpositionmode' , 'auto'            );

% axis
set(gca, ...
    'units'      , 'normalized'          , ...
    'position'   , [0.125 0.175 0.8 0.8] , ...
    'xlim'       , [0 1]               , ...
    'xtick'      , 0:0.2:1                , ...
    'ylim'       , [0 1]               , ...
    'ytick'      , 0:0.2:1                , ...
    'box'        , 'off'                 , ...
    'tickdir'    , 'out'                 , ...
    'layer'      , 'top'                 , ...
    'ticklength' , [0.01 0]              , ...
    'layer'      , 'top'                 , ...
    'fontsize'   , fontSize              );
axis square;

% labels
xlabel('Eastern Conference', 'fontsize', fontSize+4);
ylabel('Western Conference', 'fontsize', fontSize+4);

% draw CIs
for idx = 1:d.nPeople
    H(1) = plot([sigma(idx, 1, 2) sigma(idx, 1, 3)], [sigma(idx, 2, 1) sigma(idx, 2, 1)], '-');
    H(2) = plot([sigma(idx, 1, 1) sigma(idx, 1, 1)], [sigma(idx, 2, 2) sigma(idx, 2, 3)], '-');
    set(H, 'color', pantone.GlacierGray);
end

% draw means
plot(sigma(:, 1, 1), sigma(:, 2, 1), 'o', ...
    'markerfacecolor' , pantone.ClassicBlue , ...
    'markeredgecolor' , 'w'                 );

% tidy
Raxes(gca, 0.01, 0.01);

% print
if printFigures
    if ~isfolder('figures')
        !mkdir figures
    end
    warning off;
    print(sprintf('figures/%s_%s_expertise.png', modelName, dataName), '-dpng');
    print(sprintf('figures/%s_%s_expertise.pdf', modelName, dataName), '-dpdf');
    warning on;
end
