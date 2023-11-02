%This script

clearvars
clc

%List of folders
folders = {'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d1', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d2', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d4', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\20230621_140748_081'};

outputFolder = 'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\exported';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

for iFolder = 1:numel(folders)

    files = dir(fullfile(folders{iFolder}, '*.nd2'));

    for iFile = 1:numel(files)
        fprintf(['Processing file ', files(iFile).name, '\n'])

        reader = BioformatsImage(fullfile(files(iFile).folder, files(iFile).name));

        for iS = 1:reader.seriesCount

            reader.series = iS;

            for iT = 1:reader.sizeT

                ImOrange = getPlane(reader, 1, '555-mOrange', iT);
                IBF = getPlane(reader, 1, 'Red', iT);

                mask = segmentCells(ImOrange);

                %Export the mask and brightfield file as a TIFF stack
                if iT == 1
                    imwrite(IBF, fullfile(outputFolder, [files(iFile).name, '_T', int2str(iT), '_S', int2str(reader.series), '_BF.tif']))
                    imwrite(mask, fullfile(outputFolder, [files(iFile).name, '_T', int2str(iT), '_S', int2str(reader.series), '_mask.tif']), 'Compression', 'none')
                else
                    imwrite(IBF, fullfile(outputFolder, [files(iFile).name, '_T', int2str(iT), '_S', int2str(reader.series), '_BF.tif']), 'writeMode', 'append')
                    imwrite(mask, fullfile(outputFolder, [files(iFile).name, '_T', int2str(iT), '_S', int2str(reader.series), '_mask.tif']), 'Compression', 'none', 'writeMode', 'append')
                end

                % exportImages(IBF, mask, outputFolder, 256, ...
                %     'EdgeHandler', 'ignore', 'SplitNoCells', true);
            end

        end

    end
end
