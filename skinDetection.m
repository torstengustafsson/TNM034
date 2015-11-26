function [cropImage, faceMask] = skinDetection(image)

cbcrIm = rgb2ycbcr(image);

[~, skinRegion] = generate_skinmap(image);


Y = double(cbcrIm(:,:,1));
Cb = double(cbcrIm(:,:,2));
Cr = double(cbcrIm(:,:,3));


%find white parts = red dots
[rowSkinColor, colSkinColor] = find(skinRegion == 1);

%find black parts = blue dots
[rowRepColor, colRepColor] = find(skinRegion == 0);


[skinColLenth, ~] = size(rowSkinColor);
[repColLenth, ~] = size(rowRepColor);

skinColorY = zeros(skinColLenth,1);
skinColorCb = zeros(skinColLenth,1);
skinColorCr = zeros(skinColLenth,1);

repColorY = zeros(repColLenth,1);
repColorCb = zeros(repColLenth,1);
repColorCr = zeros(repColLenth,1);


%find skin color value in lightComp image with skin color positions
for i = 1:skinColLenth
        skinColorY(i,1) = Y(rowSkinColor(i),colSkinColor(i));
        skinColorCr(i,1) = Cr(rowSkinColor(i),colSkinColor(i));
        skinColorCb(i,1) = Cb(rowSkinColor(i),colSkinColor(i));
end

for i = 1:repColLenth
        repColorCb(i,1) = Cb(rowRepColor(i),colRepColor(i));
        repColorCr(i,1) = Cr(rowRepColor(i),colRepColor(i));
        repColorY(i,1) = Y(rowRepColor(i),colRepColor(i));
end


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
numbOfpixels = round(r*c*0.033);
%erase white regions if it contains less than numbOfpixels pixels, we only
%want one face region
faceMask = bwareaopen(faceMask, numbOfpixels);

%crop mask, Find indices and values of nonzero elements
[row, col] = find(faceMask);
faceMask  = faceMask(min(row):max(row), min(col):max(col));
cropImage = image(min(row):max(row), min(col):max(col),:);


%find all "ones" in faceMask
[x, y] = find(faceMask);

X = [x';
    y'];

%ellipse mask
[zt, at, bt, alphat] = fitellipse(X, 'linear', 'constraint', 'trace');
ellipseC = zt;
r_sq = [bt, at].^2;

[sizeX, sizeY] = size(faceMask);
[X, Y] = meshgrid(1:sizeY, 1:sizeX);
ellipse_mask = ((r_sq(1) * (Y - ellipseC(1)) .^ 2 + r_sq(2) * (X - ellipseC(2)) .^ 2) <= prod(r_sq));

%makes the elips bigger, important because somtimes it cuts eyes and mouths
se = strel('disk', 10);
ellipse_mask = imdilate(ellipse_mask,se);


%expand the face to an elipse mask
%faceMask = ellipse_mask+faceMask;

%invert color
ellipse_mask = imcomplement(ellipse_mask);

%masking, gives the complete mask
faceMaskPlusElips =  faceMask - ellipse_mask;

%the subtraction above sets some pixel values to -1, we must change these to
%0
faceMaskPlusElips(faceMaskPlusElips == -1) = 0;


%figure
%imshow(faceMaskPlusElips)

%using the elipsMasks size to crop the final faceMask (rezise it to same size)
[row, col] = find(faceMaskPlusElips);
%faceMask  = faceMask(min(row):max(row), min(col):max(col));

%applies faceMaskPlusElips on a black image that have same size as cropImage
[r c ~] = size(cropImage);
sizeCropImg = zeros(r,c);

bigFaceMaskPlusElips=sizeCropImg+faceMaskPlusElips;

%[row, col] = find(bigFaceMaskPlusElips);
%cropImage = cropImage(min(row):max(row), min(col):max(col),:);



%remove unwanted shapes in the mask
%se = strel('disk', 20);
%faceMask = imdilate(imerode(faceMask, se), se);

