clearvars
clc

fn = 'C:\Users\jianw\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\20230621_140748_081\ChannelRed,Cy5,555-mOrange_Seq0000.nd2';

reader = BioformatsImage(fn);

%%

reader.series = 5;
iT = 1;

I = getPlane(reader, 1, '555-mOrange', iT);

%mask = segmentCellsV4(I, 0.001, 1, [0 1000]);
mask = segmentCellsV2(I, 0.004);

Ibf = getPlane(reader, 1, 'Red', iT);
offset = [-4, 0];
Ibf = circshift(Ibf, offset);

imshowpair(I, bwperim(mask))