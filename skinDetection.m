function [img, faceMask] = skinDetection(image)

[~, skinRegion] = generate_skinmap(image);

%fill holes
groupedSkinArea = imfill(skinRegion, 'holes');

%remove noise
se = strel('disk', 9);
faceMask = (imdilate(groupedSkinArea, se));
faceMask = imfill(faceMask, 'holes');

%decide how many pixels a region must have to not be erased 
[r, c] = size(faceMask);
numbOfpixels = round(r*c*0.033);

%erase white regions if it contains less than numbOfpixels pixels, we only
%want one face region
faceMask = bwareaopen(faceMask, numbOfpixels);

%noise reduction
se = strel('disk', 20);
faceMask = imfill(faceMask, 'holes');
faceMask = imdilate(imerode(faceMask, se), se);
%masking, gives the complete mask


%find all areas of white 
centroidsOffaceMask  = regionprops(faceMask,'BoundingBox','Area');


% Select largest area you want to keep.
MaxArea = numbOfpixels; 
% Detect cells larger than some value.
centroidsOffaceMask = centroidsOffaceMask([centroidsOffaceMask.Area] > MaxArea); 


L = length(centroidsOffaceMask);

%[row, col] = find(faceMask);
   % cropSubImage  = image(min(row):max(row), min(col):max(col), :);


for n = 1:L
    
    %croppar ut alla omr�den i bilden till sub-bilder
    cropSubImage = imcrop(image,[centroidsOffaceMask(n).BoundingBox]);

    %generera om skinmasken p� omr�det
    [~, skinRegion] = generate_skinmap(cropSubImage);
    
    %fill holes
    groupedSkinArea = imfill(skinRegion, 'holes');

    se = strel('disk', 3);
    se2 = strel('disk', 9);
    se3 = strel('disk', 6);

    %remove noise
    faceMask = imerode(imdilate(imerode(groupedSkinArea, se), se2), se3);
    faceMask = imfill(faceMask, 'holes');
    %decide how many pixels a region must have to not be erased 
    [r, c] = size(faceMask);
    numbOfpixels = round(r*c*0.043);
    %erase white regions if it contains less than numbOfpixels pixels, we only
    %want one face region
    faceMask = bwareaopen(faceMask, numbOfpixels);
   
    %find all "ones" in faceMask
    [x, y] = find(faceMask);

    X = [x';
        y'];

    %ellipse mask
 
    [zt, at, bt, ~] = fitellipse(X, 'linear', 'constraint', 'trace');
    ellipseC = zt;
    r_sq = [bt, at].^2;

    [sizeX, sizeY] = size(faceMask);
    [X, Y] = meshgrid(1:sizeY, 1:sizeX);
    ellipse_mask = ((r_sq(1) * (Y - ellipseC(1)) .^ 2 + r_sq(2) * (X - ellipseC(2)) .^ 2) <= prod(r_sq));

    %makes the ellipse bigger, important because somtimes it cuts eyes and mouths
    se = strel('disk', 20);
    ellipse_mask = imdilate(ellipse_mask,se);

    faceMaskPlusElips = ellipse_mask;
    faceMaskPlusElips = (faceMaskPlusElips > 0.1);
    faceMask = faceMaskPlusElips > 0.1;

    assignin('base', 'faceMask', faceMask);
    assignin('base', 'cropSubImage', cropSubImage);
    cropSubImage = im2double(cropSubImage);
    img = zeros(size(cropSubImage));
    img(:,:,1) = cropSubImage(:,:,1).*faceMask;
    img(:,:,2) = cropSubImage(:,:,2).*faceMask;
    img(:,:,3) = cropSubImage(:,:,3).*faceMask;
    img2 = cropSubImage;
    %Mouth detection
    [~, ~, mouthCenter] = mouthDetection(cropSubImage, faceMask);
    
    %Detect eyes and rotate image to align them to the horizontal plane
    [xPos, yPos, ~] = eyeDetection(img, faceMask, mouthCenter);
    [angle, ~] = triangulateFace(xPos,yPos,img,mouthCenter);
    
    %rotate all
    img = imrotate(img, angle, 'bilinear');
    img2 = imrotate(img2, angle, 'bilinear');
    faceMask = imrotate(faceMask, angle, 'bilinear');
    
    %redo all calculations for the rotated image
    %Mouth detection
    [~, ~, mouthCenter] = mouthDetection(img, faceMask);
    
    %Detect eyes and rotate image to align them to the horizontal plane
    [xPos, yPos, ~] = eyeDetection(img, faceMask, mouthCenter);    
    
    [xSize, ySize] = size(faceMask);
    xSize = round(0.1*xSize);
    ySize = round(0.1*ySize);

    %calculate new mask
    c = [xPos(1,1)-xSize yPos(1,1)+xSize yPos(1,1)+xSize xPos(1,1)-xSize];
    r = [xPos(1,2)-ySize yPos(1,2)-ySize mouthCenter(1,2)+ySize mouthCenter(1,2)+ySize];
    faceMask2 = roipoly(faceMask,c,r);
    
    %recalculate and crop image with new mask
    img2(:,:,1) = img2(:,:,1).*faceMask2;
    img2(:,:,2) = img2(:,:,2).*faceMask2;
    img2(:,:,3) = img2(:,:,3).*faceMask2;
    [row, col] = find(faceMask2);
    faceMask2  = faceMask2(min(row):max(row), min(col):max(col));
    img2 = img2(min(row):max(row), min(col):max(col),:);
    
    %set values to resendvariables
    img = img2;
    faceMask = faceMask2;
    
end
