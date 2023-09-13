clearvars
clc

imageFolder = 'D:\Projects\Research\2023-kolya-MLcyano\exported\images';
labelsFolder = 'D:\Projects\Research\2023-kolya-MLcyano\exported\labels';

%% Load the images into datastores
imds = imageDatastore(imageFolder);

%Load masks into a label datastore
classNames = ["Background" "Cell"];
pixelLabelID = [0, 1];

pxds = pixelLabelDatastore(labelsFolder, classNames, pixelLabelID);

%Sanity check
I = readimage(imds, 1);
M = readimage(pxds, 1);
figure;
imshow(labeloverlay(I, M));

%Count number of labels
tbl = countEachLabel(pxds);

%Find frequencies of each pixel. The inverse of this will be used to set
%class weights
classFrequency = tbl.PixelCount/sum(tbl.PixelCount);

% bar(1:numel(classes),frequency)
% xticks(1:numel(classes)) 
% xticklabels(tbl.Name)
% xtickangle(45)
% ylabel('Frequency')


%Partition data into training, validation, and test sets
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionData(imds, pxds);

pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);

%For training set, perform simple augmentation to increase training data
augmenter = imageDataAugmenter('RandXReflection',true, ...
    'RandYReflection',true, ...
    'RandXTranslation',[-10 10], 'RandYTranslation',[-10 10],...
    'RandRotation', [-90 90]);

%Apply the data augmentation
pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain, ...
    'DataAugmentation',augmenter);

% %For testing with class weights
% imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
% classWeights = median(imageFreq) ./ imageFreq;

%% Create the network
%Create a U-net
lgraph = unetLayers([256 256], 2);

%Replace the final segmentation layer to include class weights. This is
%done to increase significance of the cells and decrease significance of
%background.
%lgraph = removeLayers(lgraph, 'Segmentation-Layer');

newSegLayer = pixelClassificationLayer('Name', 'Weighted-Segmentation-Layer', ...
    'Classes', ["Background", "Cell"], ...
    'ClassWeights', 1 ./ classFrequency);

lgraph = replaceLayer(lgraph, 'Segmentation-Layer', newSegLayer);

% Define training options. 
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.90, ...
    'InitialLearnRate',1e-5, ...
    'L2Regularization',0.005, ...
    'ValidationData',pximdsVal,...
    'MaxEpochs',30, ...  
    'MiniBatchSize',10, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', '', ...
    'VerboseFrequency',10,...
    'Plots','training-progress',...
    'ExecutionEnvironment', 'gpu', ...
    'ValidationPatience', 4);

%Do the actual training
[net, info] = trainNetwork(pximds,lgraph,options);

%% Save the network

outputFN = [char(datetime('now', 'Format', 'yyyyMMdd-HHmmss')), '-DeepCyan-Unet.mat'];

save(outputFN, 'net', 'info', 'options', 'lgraph')

%% Final sanity checvk

imgInd = 64;

I = readimage(imdsVal, imgInd);
C = semanticseg(I, net);

E = readimage(pxdsVal, imgInd);

figure;
subplot(1, 2, 1)
B = labeloverlay(I, C);
imshow(B)
title('Predicted')

subplot(1, 2, 2)
B = labeloverlay(I, E);
imshow(B)
title('Expected')

