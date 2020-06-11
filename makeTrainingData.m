%MAKETRAININGDATA  Generate training datasets
%
%  Original code from Nick. Modified by Jian.

%Define directories and filename
inputDir = 'D:\Nick\images';
nd2Filename = 'seq0002_xy6_crop.nd2';
maskFilename = 'seq0002_xy6_crop_series1_cellMask.tif';

outputDir = 'D:\Nick\images\trainingOutput';

%Create a reader
reader = BioformatsImage(fullfile(inputDir, nd2Filename));

%Define output image properties
targetImgSize = [256, 256];

%-- Start processing --%
%Create output directory if necessary
if ~exist(outputDir, 'dir')
    mkdir(outputDir)
else
    
    %Check if directory is empty
    listing = dir(fullfile(outputDir, '*.tif'));
    if ~isempty(listing)
        s = input('Output directory contains .tif files. Do you want to delete them (files could be overwritten anyway)? (Y = yes)', 's');
        if strcmpi(s, 'y')
            for iFile = 1:numel(listing)
                delete(fullfile(outputDir, listing(iFile).name));
            end
        end        
    end
end

%Calculate tile indices
tileRowIdxs = 1:targetImgSize(1):reader.height;
if tileRowIdxs(end) ~= reader.height
    tileRowIdxs(end + 1) = reader.height;
end

tileColIdxs = 1:targetImgSize(2):reader.width;
if tileColIdxs(end) ~= reader.width
    tileColIdxs(end + 1) = reader.width;
end

%Process frames
outputFileCtr = 0;
for iFrame = 1:reader.sizeT
    
    %Load the current image and mask
    currImg = getPlane(reader, 1, 1, iFrame);    
    currMask = imread(fullfile(inputDir, maskFilename), iFrame);
    
    for iTileRow = 1:(numel(tileRowIdxs) - 1)
        for iTileCol = 1:(numel(tileColIdxs) - 1)
            
            ROI = [tileRowIdxs(iTileRow), (tileRowIdxs(iTileRow + 1) - 1), ...
                tileColIdxs(iTileCol), (tileColIdxs(iTileCol + 1) - 1)];
            
            subI = cropAndResize(currImg, ROI, targetImgSize);
            subMask = cropAndResize(currMask, ROI, targetImgSize);
            
            if ~any(subMask > 0, 'all')
                %Skip any frames with no cells
                continue;                
            end
            
            outputFileCtr = outputFileCtr + 1;
            imwrite(subI, ...
                fullfile(outputDir, sprintf('image%04.0f.tif', outputFileCtr)), 'Compression', 'none');
            imwrite(subMask, ...
                fullfile(outputDir, sprintf('mask%04.0f.png', outputFileCtr)), ...
                'BitDepth', 8);
            %showoverlay(subI, bwperim(subMask))
            %keyboard
            
        end
    end
    
    % %     %And finally, compute the custom weights, and write to the weight
% %     matrix
% 
% %     [weight]=unetwmap(resizedMask,10,25);
% %     weightMatrix(:, :, iFrame) = weight;


end

function Iout = cropAndResize(Iin, ROI, targetImgSize)

Iout = Iin(ROI(1):ROI(2), ROI(3):ROI(4));


%Check image size
if size(Iout, 1) > targetImgSize(1)
    %Resize image
    Iout = imresize(Iout, [targetImgSize(1), size(Iout, 2)], 'nearest');
    
elseif size(Iout, 1) < targetImgSize(1)
    %Add black pixels
    pxsToAdd = targetImgSize(1) - size(Iout, 1);
    
    Iout = padarray(Iout, [pxsToAdd, 0], 'post');
end

if size(Iout, 2) > targetImgSize(2)
    %Resize image
    Iout = imresize(Iout, [size(Iout, 1), targetImgSize(2)], 'nearest');
    
elseif size(Iout, 2) < targetImgSize(2)
    %Add black pixels
    pxsToAdd = targetImgSize(2) - size(Iout, 2);
    
    Iout = padarray(Iout, [0, pxsToAdd], 'post');
end

%Double check image size
if any(size(Iout) ~= targetImgSize)
    keyboard
end

end

%Save the weightMatrix in a .mat file
% weightMatrixFileName = [currND2FileName(1:end-4), '_WeightMatrix'];
% save(fullfile(inputDir, 'separatedImages', 'pixelWeights', weightMatrixFileName), 'weightMatrix', '-v7.3');

% currWeightMatrix = matfile(fullfile(inputDir, 'separatedImages', 'pixelWeights', [currND2FileName(1:end-4), '_WeightMatrix', '.mat']));
% currWeights = currWeightMatrix.weightMatrix(:,:,120);
