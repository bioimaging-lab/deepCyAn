function mask = segmentCells(I)
%SEGMENTCELLS  Generate a mask of fluorescently labeled cyanobacteria
%
%  MASK = SEGMENTCELLS(I) will return a binary matrix MASK which labels the
%  position of fluorescently labeled cells in the input image I. The pixels
%  in MASK will be true if the corresponding pixel in I contains a cell and
%  false otherwise.

%Generate an initial mask using the adaptive thresholding algorithm
T = adaptthresh(I, 0.8, 'NeighborhoodSize', 41);
mask = imbinarize(I, T);

%Remove masks which intersect with the image border
mask = imclearborder(mask);
mask = bwareaopen(mask, 200);
mask = imopen(mask, strel('disk', 3));

%Watershed to separate grouped cells
dd = -bwdist(~mask);
dd(~mask) = -Inf;
dd = imhmin(dd, 1);
LL = watershed(dd);

%Update the original mask
mask(LL == 0) = 0;

%Remove objects which are too small to be a real cell
mask = bwareaopen(mask, 100);

%Grow the remaining masks without allowing objects to touch. This is
%require because the mOrange marker labels the cytoplasm, which is smaller
%than the actual cell.
mask = bwmorph(mask, 'thicken', 5);

end