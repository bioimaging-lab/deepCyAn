function mask = segmentCellsV2(I, sensitivity)
%SEGMENTCELLS  Generate a mask of fluorescently labeled cyanobacteria
%
%  MASK = SEGMENTCELLS(I) will return a binary matrix MASK which labels the
%  position of fluorescently labeled cells in the input image I. The pixels
%  in MASK will be true if the corresponding pixel in I contains a cell and
%  false otherwise.

%Generate an initial mask using the adaptive thresholding algorithm
% T = adaptthresh(I, 0.8, 'NeighborhoodSize', 41);
% mask = imbinarize(I, T);

%Normalize the image
I = double(I);

I = (I - min(I(:)))/(max(I(:)) - min(I(:)));
I = uint16(I * 65535);

I = imsharpen(I, 'Amount', 0.9);

th = getThreshold(I, sensitivity);
mask = I > th;

mask = imopen(mask, strel('disk', 3));

%Create markers
Ifilt = imgaussfilt(I, 2);
Ifilt = medfilt2(Ifilt, [10 10]);

%Remove masks which intersect with the image border
%mask = imclearborder(mask);
mask = bwareaopen(mask, 200);
mask = imopen(mask, strel('disk', 3));

% %Watershed to separate grouped cells
% dd = -bwdist(~mask);
% dd(~mask) = -Inf;
% 
% dd = imhmin(dd, 1);
% LL = watershed(dd);

markers = imregionalmax(Ifilt, 8);
markers(~mask) = false;

markers = imdilate(markers,strel('disk', 6));
markers = imerode(markers,strel('disk', 3));

% %Remove regions which are too dark
% rptemp = regionprops(markers, I,'MeanIntensity','PixelIdxList');
% markerTh = median([rptemp.MeanIntensity]) - 0.2 * median([rptemp.MeanIntensity]);
% 
% idxToDelete = 1:numel(rptemp);
% idxToDelete([rptemp.MeanIntensity] > markerTh) = [];
% 
% for ii = idxToDelete
%     markers(rptemp(ii).PixelIdxList) = 0;
% end

% 
% figure;
% imshowpair(I, markers);
% keyboard
%imshowpair(I, bwperim(mask))
% keyboard

dd = imcomplement(Ifilt);
dd = imimposemin(dd, ~mask | markers);

LL = watershed(dd);

%Update the original mask
mask(LL == 0) = 0;

%Remove objects which are too small to be a real cell
mask = bwareaopen(mask, 100);

% imshowpair(I, bwperim(mask));

%Grow the remaining masks without allowing objects to touch. This is
%require because the mOrange marker labels the cytoplasm, which is smaller
%than the actual cell.
%mask = bwmorph(mask, 'thicken', 5);

end