% Analyzes a song using an enhanced feature set

clear; clc; close all;

% --- CONFIGURATION ---
testAudioFile = 'D:\SNS Proj\Dont Stop Me Now.mp3'; % <-- SET YOUR TEST FILE
%testAudioFile = 'D:\SNS Proj\Dancing Queen.mp3'; % <-- SET YOUR TEST FILE
%testAudioFile = 'D:\SNS Proj\Blinding Lights.mp3'; % <-- SET YOUR TEST FILE
esp32_IP = '192.168.2.70'; % <-- SET YOUR ESP32 IP
tcpPort = 8080;

% --- SCRIPT START ---

% 1. Load the Enhanced MATLAB-generated Dataset
disp('Loading enhanced MATLAB-generated genre dataset...');
datasetTable = readtable('genre_features.csv');
featureData = table2array(datasetTable(:, 1:end-1));
genreLabels = datasetTable.genre;

% 2. Train the k-NN Model
disp('Training k-NN model...');
k = 5;
knnModel = fitcknn(featureData, genreLabels, 'NumNeighbors', k, 'Distance', 'euclidean');
disp('Model training complete.');

% 3. Analyze the New Song
disp(['Analyzing test file: ', testAudioFile]);
try
    [y, fs] = audioread(testAudioFile);
    
    % --- UPDATED EXTRACTOR: Must match the creator script perfectly ---
    extractor = audioFeatureExtractor( ...
        'SampleRate', 44100, ...
        'spectralCentroid', true, ...
        'spectralSpread', true, ...
        'spectralRolloffPoint', true, ...
        'zeroCrossRate', true, ...
        'spectralFlatness', true, ...
        'spectralFlux', true, ...
        'spectralCrest', true, ...     % <-- NEW
        'spectralEntropy', true, ...   % <-- NEW
        'spectralSkewness', true, ...  % <-- NEW
        'spectralKurtosis', true, ...  % <-- NEW
        'mfcc', true);
    
    % Resample the test audio to match the model's training data
    y_resampled = resample(y, extractor.SampleRate, fs);
    if size(y_resampled, 2) > 1, y_resampled = mean(y_resampled, 2); end
    
    features = extract(extractor, y_resampled);
    features(isinf(features) | isnan(features)) = 0;
    testFeatures = mean(features, 1);
    
    % 4. Predict the Genre
    predictedGenre = predict(knnModel, testFeatures);
    disp(['>>> Predicted Genre: ', predictedGenre{1}]);
    
    % 5. Send Result to ESP32
    disp(['Connecting to ESP32 TCP server at ', esp32_IP, '...']);
    tcpClient = tcpclient(esp32_IP, tcpPort);
    write(tcpClient, predictedGenre{1});
    disp('Data sent successfully via TCP!');
    
catch e
    disp('An error occurred during analysis or communication:');
    disp(e.message);
end