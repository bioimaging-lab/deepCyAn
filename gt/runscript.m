clearvars
clc

file = 'C:\Users\jianw\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\OD0d1\OD0d1_image001.nd2';

reader = BioformatsImage(file);

%%
for iS = 1:2%reader.seriesCount

    reader.series = iS;


    ImOrange = getPlane(reader, 1, '555-mOrange', 1);
    IBF = getPlane(reader, 1, 'Red', 1);

    imshow(ImOrange, [])

    mask = segmentCells(ImOrange);

    exportImages(IBF, mask, 'C:\Users\jianw\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\exported', 256, ...
        'EdgeHandler', 'ignore', 'SplitNoCells', true);

end


