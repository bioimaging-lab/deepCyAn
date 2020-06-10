%% To output properly sized images and masks of PCC 7002


%First, load the .nd2 file and the mask.
inputDir = 'F:\deep learning';

currND2FileName = 'seq0002_xy6_crop.nd2';
currMaskFileName = 'seq0002_xy6_crop_series1_cellMask.tif';

currND2FileDir = fullfile(inputDir, 'inputFiles', 'seq0002_xy6_crop.nd2');
currMaskFileDir = fullfile(inputDir,'inputFiles', 'seq0002_xy6_crop_series1_cellMask.tif');
currND2 = BioformatsImage(currND2FileDir);

targetImgSize = 2048;
weightMatrix = nan(targetImgSize, targetImgSize, currND2.sizeT);
for iFrame = 1:currND2.sizeT
    
    %Load the current image
    currImg = currND2.getPlane(1, 1, iFrame);
    
    %Resize the image to a square of size 2048 by 2048
    resizedImg = zeros(targetImgSize, targetImgSize, 'uint16');
    imgSize = size(currImg);
    resizedImg(1:imgSize(1), 1:imgSize(2)) = currImg;
    
    %Find the size of matrices required to fill the rest of resized image
    rightSideMatrixSize = [targetImgSize, targetImgSize-imgSize(2)];
    bottomMatrixSize = [targetImgSize-imgSize(1), imgSize(2)];
    
    %Then, fill in the remaining zeros with grey values of background
    
    %Find the background peak
    [nCnts, binEdges] = histcounts(currImg(:),linspace(0, double(max(currImg(:))), 150));
    binCenters = diff(binEdges) + binEdges(1:end-1);
    [~, bgPkLoc] = max(nCnts);
    %Say the background contains 6 bins on each size of this peak
    greyValues = [binCenters(bgPkLoc-6) binCenters(bgPkLoc+6)];
    
    %Pick random grey values and add them to the resized image
    
    %For the right side matrix
    pos = randi([round(greyValues(1)) round(greyValues(end))], rightSideMatrixSize);
    resizedImg(1:targetImgSize, imgSize(2)+1:targetImgSize) = pos;
    
    %For the bottom matrix
    pos = randi([round(greyValues(1)) round(greyValues(end))], bottomMatrixSize);
    resizedImg(imgSize(1)+1:targetImgSize, 1:imgSize(2)) = pos;
    
    %Then, load in the mask
    currMask = imread(currMaskFileDir, iFrame);
    
    %Again, make an empty matrix and put the mask in it.
    resizedMask = zeros(targetImgSize, targetImgSize, 'uint8');
    resizedMask(1:imgSize(1), 1:imgSize(2)) = currMask;    
    resizedMask(resizedMask > 0) = 2;
    resizedMask(resizedMask == 0) = 1;

    %Then, write the image and mask to output folders
    imageOutputFileName = [currND2FileName(1:end-4), '_Frame', num2str(iFrame), '.tif'];
    maskOutputFileName = [currMaskFileName(1:end-4), '_Frame', num2str(iFrame), '.tif'];
%     imwrite(resizedImg, fullfile(inputDir, 'separatedImages', 'rawImages', imageOutputFileName), 'Compression', 'None');
    imwrite(resizedMask, fullfile(inputDir, 'separatedImages', 'pixelLabels', maskOutputFileName), 'Compression', 'None');
    
%     %And finally, compute the custom weights, and write to the weight
%     matrix

%     [weight]=unetwmap(resizedMask,10,25);
%     weightMatrix(:, :, iFrame) = weight;


end

%Save the weightMatrix in a .mat file
% weightMatrixFileName = [currND2FileName(1:end-4), '_WeightMatrix'];
% save(fullfile(inputDir, 'separatedImages', 'pixelWeights', weightMatrixFileName), 'weightMatrix', '-v7.3');

% currWeightMatrix = matfile(fullfile(inputDir, 'separatedImages', 'pixelWeights', [currND2FileName(1:end-4), '_WeightMatrix', '.mat']));
% currWeights = currWeightMatrix.weightMatrix(:,:,120);


%% Compute the weight map from the mask

% [weight]=unetwmap(resizedMask,10,25);

%% Load the images into datastores

%Load images into a dataStore
imgDir = fullfile(inputDir, 'separatedImages', 'rawImages');

%Delete the extra file that starts with a period
files = dir(fullfile(imgDir, '*.tif'));
acceptedFiles = {};
for iFile = 1:numel(files)
    
    if ~strcmpi(files(iFile).name(1), '.')
        acceptedFiles{end + 1} = fullfile(files(iFile).folder, files(iFile).name);
    end
    
end
imds = imageDatastore(acceptedFiles);


%Create the labels and labelIDs
classes = [
    "Background"
    "Cell"
    ];

labelIDs = [1, 2];

%Create a datastore for the pixelLabels
labelDir = fullfile(inputDir, 'separatedImages', 'pixelLabels');
pxds = pixelLabelDatastore(labelDir,classes,labelIDs);

% I = readimage(imds,1);
% I = histeq(I);
% imshow(I)
% 
% %Show an overlayed picture
% C = readimage(pxds,1);
% B = labeloverlay(I,C);
% imshow(B)

tbl = countEachLabel(pxds);

%Find frequencies of each pixel
frequency = tbl.PixelCount/sum(tbl.PixelCount);

% bar(1:numel(classes),frequency)
% xticks(1:numel(classes)) 
% xticklabels(tbl.Name)
% xtickangle(45)
% ylabel('Frequency')

%Partition data into training, validation, and test sets
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionData(imds,pxds);


%For testing with class weights
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

%Create a U-net
lgraphU = createUnet();

%Modify the final segmentation layer. This custom layer includes a custom
%loss function that takes into account custom pixel weights.
customSegLayer = customClassificationLayer('customSegLayer', classWeights);
lgraphU = replaceLayer(lgraphU,"Segmentation-Layer",customSegLayer);

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





