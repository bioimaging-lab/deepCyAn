clearvars
clc

fn = 'C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2023 Unet Cyano Segmentation\data\20230621 scJC0201\20230621_140748_081\ChannelRed,Cy5,555-mOrange_Seq0000.nd2';

reader = BioformatsImage(fn);



%%
reader.series = 1;
iT = 1;

I = getPlane(reader, 1, '555-mOrange', iT);
Ibf = getPlane(reader, 1, 'Red', iT);

mask = segmentCellsV2(I);

imshowpair(Ibf, bwperim(mask))