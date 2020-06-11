%% Compute the weight map from the mask

% [weight]=unetwmap(resizedMask,10,25);

%% Load the images into datastores

trainingDir = 'D:\Nick\images\trainingOutput';

%Load training images into a dataStore
tImgList = dir(fullfile(trainingDir, 'image*.tif'));
tImgListCell = cell(1, numel(tImgList));
for iFile = 1:numel(tImgList)
    tImgListCell{iFile} = fullfile(trainingDir, tImgList(iFile).name);
end

imds = imageDatastore(tImgListCell);

%Load masks into a label datastore
classNames = ["Background" "Cell"];
pixelLabelID = [0, 255];

tMaskList = dir(fullfile(trainingDir, 'mask*.png'));
tMaskListCell = cell(1, numel(tMaskList));
for iFile = 1:numel(tMaskList)
    tMaskListCell{iFile} = fullfile(trainingDir, tMaskList(iFile).name);
end

pxds = pixelLabelDatastore(tMaskListCell, classNames, pixelLabelID);


%Sanity check
I = readimage(imds, 1);
M = readimage(pxds, 1);
figure;
imshow(labeloverlay(I, M));
% imshowpair(I, M == 'Cell', 'montage')

%%

tbl = countEachLabel(pxds);

%Find frequencies of each pixel
frequency = tbl.PixelCount/sum(tbl.PixelCount);

% bar(1:numel(classes),frequency)
% xticks(1:numel(classes)) 
% xticklabels(tbl.Name)
% xtickangle(45)
% ylabel('Frequency')

%Partition data into training, validation, and test sets
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionData(imds, pxds);


%For testing with class weights
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

%Create a U-net
lgraphU = createUnet([256, 256, 1]);

% %Modify the final segmentation layer. This custom layer includes a custom
% %loss function that takes into account custom pixel weights.
% customSegLayer = customClassificationLayer('customSegLayer', classWeights);
% lgraphU = replaceLayer(lgraphU,"Segmentation-Layer",customSegLayer);

%For the standardUnet - alternative to above two lines
% pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
% lgraphU = replaceLayer(lgraphU,"Segmentation-Layer",pxLayer);


%Then, create training options and define validation data
pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);
% Define training options. 
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.90, ...
    'InitialLearnRate',0.00001, ...
    'L2Regularization',0.005, ...
    'ValidationData',pximdsVal,...
    'MaxEpochs',30, ...  
    'MiniBatchSize',1, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', '', ...
    'VerboseFrequency',2,...
    'Plots','training-progress',...
    'ExecutionEnvironment', 'cpu', ...
    'ValidationPatience', 4);


%Perform simple augmentation to increase training data
augmenter = imageDataAugmenter('RandXReflection',true,...
    'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);

%Apply the data augmentation
pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain, ...
    'DataAugmentation',augmenter);

%Do the actual training
[net, info] = trainNetwork(pximds,lgraphU,options);

%% Testing

I = readimage(imdsVal, 53);
C = semanticseg(I, net);

figure;
B = labeloverlay(I, C);
imshow(B)

