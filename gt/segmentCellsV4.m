function cellLabels = segmentCellsV4(cellImage, thFactor, maxCellminDepth, cellAreaLim)

%Normalize the cellImage
cellImage = double(cellImage);

cellImage = (cellImage - min(cellImage(:)))/(max(cellImage(:)) - min(cellImage(:)));
cellImage = uint16(cellImage .* 65535);

cellImage = imsharpen(cellImage,'Amount', 2);

%Get a threshold
[nCnts, binEdges] = histcounts(cellImage(:),150);
binCenters = diff(binEdges) + binEdges(1:end-1);

%Determine the background intensity level
[maxVal, maxInd] = max(nCnts);
thInd = find(nCnts((maxInd + 1): end) < (maxVal * thFactor), 1, 'first');
thLvl = binCenters(maxInd + thInd);

mask = cellImage > thLvl;

mask = imopen(mask,strel('disk',3));
mask = imclearborder(mask);

mask = bwareaopen(mask,100);
mask = imopen(mask,strel('disk',2));
mask = ~bwmorph(~mask, 'clean');
%                     mask = imfill(mask,'holes');

dd = -bwdist(~mask);
dd(~mask) = -Inf;

dd = imhmin(dd, maxCellminDepth);

tmpLabels = watershed(dd);

mask(tmpLabels == 0) = 0;

LL = bwareaopen(mask, 100);

%Try to mark the image
markerImg = medfilt2(cellImage,[10 10]);
markerImg = imregionalmax(markerImg,8);
markerImg(~mask) = 0;
markerImg = imdilate(markerImg,strel('disk', 6));
markerImg = imerode(markerImg,strel('disk', 3));

%Remove regions which are too dark
rptemp = regionprops(markerImg, cellImage,'MeanIntensity','PixelIdxList');
markerTh = median([rptemp.MeanIntensity]) - 0.2 * median([rptemp.MeanIntensity]);

idxToDelete = 1:numel(rptemp);
idxToDelete([rptemp.MeanIntensity] > markerTh) = [];

for ii = idxToDelete
    markerImg(rptemp(ii).PixelIdxList) = 0;
end

dd = imcomplement(medfilt2(cellImage,[4 4]));
dd = imimposemin(dd, ~mask | markerImg);

cellLabels = watershed(dd);
cellLabels = imclearborder(cellLabels);
cellLabels = imopen(cellLabels, strel('disk',6));

%Redraw the masks using cylinders
rpCells = regionprops(cellLabels,{'Area','PixelIdxList'});

%Remove cells which are too small or too large
rpCells(([rpCells.Area] < min(cellAreaLim)) | ([rpCells.Area] > max(cellAreaLim))) = [];

cellLabels = zeros(size(cellLabels));
for ii = 1:numel(rpCells)
    cellLabels(rpCells(ii).PixelIdxList) = ii;
end

end