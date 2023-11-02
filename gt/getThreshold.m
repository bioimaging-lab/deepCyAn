function thLvl = getThreshold(imageIn, sensitivity)
%GETTHRESHOLD  Get a threshold for the image
%
%  T = FRETtracker.GETTHRESHOLD(I) gets a greyscale threshold
%  level T for the image I.
%
%  Threshold is determined by looking at image histogram, then
%  looking for the greyscale value where the maximum count
%  drops to at least 20%.

%Get the image intensity histogram
binEdges = linspace(0,double(max(imageIn(:))),200);
[nCnts, binEdges] = histcounts(imageIn(:),binEdges);
binCenters = diff(binEdges) + binEdges(1:end-1);

nCnts = smooth(nCnts,5);

%Find the background peak count
[bgCnt,bgLoc] = findpeaks(nCnts,'Npeaks',1,'SortStr','descend');

%Find where the histogram counts drops to at least 20% of this value
thLoc = find(nCnts(bgLoc:end) <= (bgCnt * sensitivity), 1, 'first');

if isempty(thLoc)
    error('FRETtracker:getThreshold:CouldNotGetThreshold',...
        'Auto thresholding failed to find a suitable threshold level. Try specifying one manually.');
end

thLvl = binCenters(thLoc + bgLoc);

plot(binCenters,nCnts,binCenters(bgLoc),bgCnt,'x',[thLvl, thLvl],ylim,'r--');

keyboard

% keyboard
%
%

end
