function makeGroundtruthDataset(inputDirs, outputDir)
%MAKEGROUNDTRUTHDATASET  Make ground truth datasets
%
%  MAKEGROUNDTRUTHDATASET(IN) will generate ground truth datasets for
%  this project. The input IN should be either a path to a folder
%  containing ND2 files or a cell array of paths.
%
%  This function reads in all ND2 files in the folder provided and
%  generates: (1) exported TIFF files, (2) corresponding U-net masks, (3)
%  corresponding Mask-RCNN masks (of individual cells), (4) Bounding boxes
%  for Mask-RCNN.
%
% The ND2 files must have two channels - a brightfield channel and a
% fluorescent marker that can be used to segment the cells.

%Parse inputs
if ~iscell(inputDirs) && ischar(inputDirs)
    inputDirs = {inputDirs};
end

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

for iFolder = 1:numel(inputDirs)

    files = dir(fullfile(inputDirs{iFolder}, '*.nd2'));

    for iFile = 1:numel(files)
        fprintf(['Processing file ', files(iFile).name, '\n'])

        reader = BioformatsImage(fullfile(files(iFile).folder, files(iFile).name));

        for iS = 1:reader.seriesCount

            reader.series = iS;

            for iT = 1:reader.sizeT

                %Read in the images
                ImOrange = getPlane(reader, 1, '555-mOrange', iT);
                IBF = getPlane(reader, 1, 'Red', iT);

                %Make mask
                mask = segmentCells(ImOrange);

                %Crop subimages and export as TIFs
                exportImages(IBF, mask, outputDir, 256, ...
                    'EdgeHandler', 'ignore', 'SplitNoCells', true);

            end

        end

    end
end
