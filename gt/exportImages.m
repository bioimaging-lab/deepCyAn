function exportImages(I, mask, outputDir, imgSize, varargin)
%EXPORTIMAGES  Divide and export images as TIFFs
%
%  EXPORTIMAGES(I, MASK, DIR, SZ) will divide the image I and corresponding
%  MASK into subimages of specified by SZ. SZ can either be a single number
%  for square subimages or a two-element vector specifying the height x
%  width of the subimages.
%
%  The resulting images and masks will be saved to the main directory DIR.
%  The code will create two sub-directories: 'images' and 'labels', storing
%  the image and masks in the corresponding folder. Image names are numeric
%  and increase monotonically. Note that if images already exist in the
%  'images' subfolder, the code will export new images with next available
%  filename. Note that the code only checks for existing files in the
%  'images' subfolder. It is strongly recommended that any deletions you
%  make is reflected in both images and masks.
%
%  EXPORTIMAGES(..., 'EdgeHandler', value) can be used to change the way
%  the subimages are exported along the edge of the image:
%   * 'maximize' (default) - If a subimage would extend beyond the size of
%     the image, the starting index of the subimage is changed to allow fit
%     into the current image. This allows the greatest number of subimages
%     to be generated.
%   * 'ignore' - In this case, if a subimage would extend beyond the image
%     size, it is ignored and not exported.
%
%  EXPORTIMAGES(..., 'SplitNoCells', value) can be used to change the way
%  the subimages without detected cells are handled
%   * false (default) - Subimages and masks are exported in the default
%     folders.
%   * true - If subimages have no cells (i.e., masks have no true pixels),
%     they will be placed into 'imagesNoCells' and 'labelsNoCells' directories
%     instead.

%Validate inputs

%Check image size input
if numel(imgSize) == 1
    imgSize = [imgSize imgSize];
elseif numel(imgSize) > 2
    error('Expected output image size to be a two-element vector.')
end

%Parse the variable input
ip = inputParser;

validationEdgeHandle = @(x) assert(isequal(lower(x), 'maximize') || isequal(lower(x), 'ignore'), ...
    'EdgeHandler value must be ''maximize'' or ''ignore''');
addParameter(ip, 'EdgeHandler', 'maximize', validationEdgeHandle);
addParameter(ip, 'SplitNoCells', false, @(x) assert(islogical(x), 'SplitNoCells must be true or false.'));
parse(ip, varargin{:});

%--- Initialize ---%

%Create subdirectories if needed
if ~exist(fullfile(outputDir, 'images'), 'dir')
    mkdir(fullfile(outputDir, 'images'));
end

if ~exist(fullfile(outputDir, 'labels'), 'dir')
    mkdir(fullfile(outputDir, 'labels'));
end

if ip.Results.SplitNoCells

    if ~exist(fullfile(outputDir, 'imagesNoCells'), 'dir')
        mkdir(fullfile(outputDir, 'imagesNoCells'));
    end

    if ~exist(fullfile(outputDir, 'labelsNoCells'), 'dir')
        mkdir(fullfile(outputDir, 'labelsNoCells'));
    end

end

%Check if images already exist. If so, set the image counter to a higher
%number.
imgFiles = dir(fullfile(outputDir, 'images', '*.tif'));

if numel(imgFiles) > 0

    %Handle SplitNoCell
    if ip.Results.SplitNoCells
        imgFilesNoCell  = dir(fullfile(outputDir, 'imagesNoCells', '*.tif'));
        imgFiles = [imgFiles; imgFilesNoCell];
    end

    %Get the file names
    fn = {imgFiles.name};
    [~, fn] = fileparts(fn);

    fndbl = str2double(fn);

    %Set counter to highest filename + 1
    ctrImage = max(fndbl) + 1;

else
    ctrImage = 0;

end

%--- Start export code ---%

%Compute the indices to split the image at
indRowStart = 1:imgSize(1):size(I, 1);
indColStart = 1:imgSize(2):size(I, 2);

for iRow = 1:numel(indRowStart)

    indRowEnd = indRowStart(iRow) + imgSize(1) - 1;

    %Check if we've reached the bottom
    if indRowEnd > size(I, 1)

        switch (lower(ip.Results.EdgeHandler))

            case 'maximize'
                %Move the start index
                indRowStart(iRow) = size(I, 1) - imgSize(1);
                indRowEnd = size(I, 1);

            case 'ignore'
                continue;

        end

    end

    for iCol = 1:numel(indColStart)

        indColEnd = indColStart(iCol) + imgSize(2) - 1;

        %Check if we've reached the right side
        if indColEnd > size(I, 2)

            switch (lower(ip.Results.EdgeHandler))

                case 'maximize'

                    %Move the start index
                    indColStart(iCol) = size(I, 2) - imgSize(2);
                    indColEnd = size(I, 2);

                case 'ignore'
                    continue;
            end

        end

        imagesSubDir = 'images';
        labelsSubDir = 'labels';

        if ip.Results.SplitNoCells

            if nnz(mask(indRowStart(iRow):indRowEnd, indColStart(iCol):indColEnd)) == 0
                imagesSubDir = 'imagesNoCells';
                labelsSubDir = 'labelsNoCells';
            end

        end

        imwrite(I(indRowStart(iRow):indRowEnd, ...
            indColStart(iCol):indColEnd), ...
            fullfile(outputDir, imagesSubDir, [int2str(ctrImage), '.tif']), ...
            'Compression', 'none')

        imwrite(mask(indRowStart(iRow):indRowEnd, ...
            indColStart(iCol):indColEnd), ...
            fullfile(outputDir, labelsSubDir, [int2str(ctrImage), '.tif']), ...
            'Compression', 'none')        

        ctrImage = ctrImage + 1;
   
    end
end

end