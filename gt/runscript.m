clearvars
clc

%List of folders
folders = {'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d1', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d2', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d4', ...
    'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\20230621_140748_081'};

outputFolder = 'D:\Projects\Research\2023-kolya-MLcyano\exported';

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

                exportImages(IBF, mask, outputFolder, 256, ...
                    'EdgeHandler', 'ignore', 'SplitNoCells', true);
            end

        end

    end
end
