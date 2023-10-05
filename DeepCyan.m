clearvars
clc

imageFolder = 'D:\Projects\Research\deepCyan\data\images';
labelsFolder = 'D:\Projects\Research\deepCyan\data\labels';

outputFolder = 'D:\Projects\Research\deepCyan\trained';

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
    'RandXTranslation',[-10 10], 'RandYTranslation',[-10 10]);

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
    'MiniBatchSize',1, ...
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

save(fullfile(outputFolder, outputFN), 'net', 'info', 'options', 'lgraph')

%% Final sanity check

imgInd = [5, 36, 151];

figure;
for ii = 1:numel(imgInd)

    fn = imdsVal.Files{imgInd(ii)};
    [~, fn] = fileparts(fn);

    I = readimage(imdsTrain, imgInd(ii));
    C = semanticseg(I, net);

    E = readimage(pxdsTrain, imgInd(ii));
    
    subplot(3, 2, ((ii - 1) * 2) + 1)
    B = labeloverlay(I, C);
    imshow(B)
    title(['Predicted (', fn, '.tif)'])

    subplot(3, 2, ii * 2)
    B = labeloverlay(I, E);
    imshow(B)
    title('Expected')

end
sgtitle('Training set')
set(gcf, 'Position', [102 2 836 948])

saveas(gcf, fullfile(outputFolder, [char(datetime('now', 'Format', 'yyyyMMdd-HHmmss')), '-DeepCyan-Unet-Training.png']))

%% Check validation set

imgInd = [64, 115, 89];

figure;
for ii = 1:numel(imgInd)

    fn = imdsVal.Files{imgInd(ii)};
    [~, fn] = fileparts(fn);

    I = readimage(imdsVal, imgInd(ii));
    C = semanticseg(I, net);

    E = readimage(pxdsVal, imgInd(ii));
    
    subplot(3, 2, ((ii - 1) * 2) + 1)
    B = labeloverlay(I, C);
    imshow(B)
    title(['Predicted (', fn, '.tif)'])

    subplot(3, 2, ii * 2)
    B = labeloverlay(I, E);
    imshow(B)
    title('Expected')

end
sgtitle('Validation set')
set(gcf, 'Position', [102 2 836 948])

saveas(gcf, fullfile(outputFolder, [char(datetime('now', 'Format', 'yyyyMMdd-HHmmss')), '-DeepCyan-Unet-Validation.png']))