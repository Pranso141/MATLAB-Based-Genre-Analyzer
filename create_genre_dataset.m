% Creates an enhanced genre dataset using more MATLAB features
clear; clc; close all;

% --- CONFIGURATION ---
rootMusicFolder = 'Music Library';

% --- SCRIPT START ---
disp('Starting enhanced MATLAB-based dataset creation...');

extractor = audioFeatureExtractor( ...
    'SampleRate', 44100, ...
    'spectralCentroid', true, ...
    'spectralSpread', true, ...
    'spectralRolloffPoint', true, ...
    'zeroCrossRate', true, ...
    'spectralFlatness', true, ...
    'spectralFlux', true, ...
    'spectralCrest', true, ...
    'spectralEntropy', true, ...
    'spectralSkewness', true, ...
    'spectralKurtosis', true, ...
    'mfcc', true);

% Get a list of genre subfolders
genreFolders = dir(rootMusicFolder);
genreFolders = genreFolders([genreFolders.isdir] & ~ismember({genreFolders.name},{'.','..'}));

allFeatures = [];
allLabels = {};

% Loop through each genre folder
for i = 1:length(genreFolders)
    genreName = genreFolders(i).name;
    disp(['Processing genre: ', genreName]);
    
    audioFiles = [dir(fullfile(rootMusicFolder, genreName, '*.mp3')); dir(fullfile(rootMusicFolder, genreName, '*.wav'))];
    
    for j = 1:length(audioFiles)
        filePath = fullfile(rootMusicFolder, genreName, audioFiles(j).name);
        disp(['  - Analyzing: ', audioFiles(j).name]);
        
        try
            [y, fs] = audioread(filePath);
            y_resampled = resample(y, extractor.SampleRate, fs);
            if size(y_resampled, 2) > 1, y_resampled = mean(y_resampled, 2); end
            
            features = extract(extractor, y_resampled);
            features(isinf(features) | isnan(features)) = 0;
            meanFeatures = mean(features, 1);
            
            allFeatures = [allFeatures; meanFeatures];
            allLabels{end+1} = genreName;
            
        catch e
            disp(['    * Error processing file: ', e.message]);
        end
    end
end

% --- FIX IS HERE: Manually define variable names to avoid errors ---
varNames = {'spectralCentroid', 'spectralSpread', 'spectralRolloffPoint', ...
            'zeroCrossingRate', 'spectralFlatness', 'spectralFlux', ...
            'spectralCrest', 'spectralEntropy', 'spectralSkewness', ...
            'spectralKurtosis'};
% Add the 13 MFCC names
for i = 1:13 
    varNames{end+1} = ['mfcc_' num2str(i)];
end

featureTable = array2table(allFeatures, 'VariableNames', varNames);
featureTable.genre = allLabels';

% Save the final dataset
outputFilename = 'genre_features.csv';
writetable(featureTable, outputFilename);

disp('---------------------------------');
disp(['Enhanced MATLAB dataset creation complete! File saved as: ', outputFilename]);