function [corrVal, mouthImg, mouthCenter] = mouthDetection(cropImage, faceMask)
corrVal = 0;

% mouth map
subImageYCbCr = rgb2ycbcr(cropImage);

im2Y = im2double(subImageYCbCr(:,:,1));
im2Cb = im2double(subImageYCbCr(:,:,2));
im2Cr = im2double(subImageYCbCr(:,:,3));

%fallowing the equation from "face detection in color image"
%calculate n, "eta"
chromaLength = size(im2Cr(:), 1);
top = ((1/chromaLength) * sum(im2Cr(:).*im2Cr(:)));
bot = ((1/chromaLength) * sum(im2Cr(:)./im2Cb(:)));
n = 0.97 *( top./bot );

%calculate mouthmask 
mouthMap = (im2Cr.^2) .* ((im2Cr.^2) - n.*(im2Cr./im2Cb)).^2;
mouthMap = mouthMap./max(mouthMap(:));

%masking, gives the compleate mouthMap
finalMouthMap = faceMask.* mouthMap;

%dilation
se2 = strel('disk', 8);
mouthImg = imdilate(finalMouthMap, se2);

%set the over half of the img to black
[sizeX, sizeY] = size(mouthImg);
[r, c] = size(mouthMap);

%decide how many pixels a region must have to not be erased 
%we decided that regions that are has less than 0.23% pixels of the image will be erased (empriskt) 
numbOfpixels = round(r*c*0.0028);

assignin('base', 'mouthMap', mouthImg);
mouthImg(1:round(sizeX.*0.6),:) = 0;

for mouthIntensity = 0.4:-0.01:0.1
    

    %if the pixel value is greater than mouthIntensity set pixel value to 1 the rest is 0
    mouthImgMask = mouthImg > mouthIntensity;



    %Remove small regions
    se = strel('disk',1);        
    mouthImgMask = imerode(mouthImgMask,se);

    se2 = strel('disk', 2);
    
    mouthImgMask = imdilate(mouthImgMask, se2);
    
    if(nnz(mouthImgMask) > numbOfpixels)
        break;
    end

end

%Dilate first to fill lips
mouthImgMask = bwareaopen(mouthImgMask, numbOfpixels);

numbOfpixels = round(numbOfpixels/70);

se = strel('disk', numbOfpixels);
mouthImgMask = imerode(imdilate(mouthImgMask, se), se);
L = imfill(mouthImgMask, 'holes');


%find mouth center
xcentre = 1;
ycentre = 1;
[x, y] = meshgrid(1:size(L, 2), 1:size(L, 1));
weightedx = x .* L;
weightedy = y .* L;
xcentre = sum(weightedx(:)) / sum(L(:));
ycentre = sum(weightedy(:)) / sum(L(:));
xcentre = round(xcentre);
ycentre = round(ycentre);
mouthCenter = [xcentre, ycentre];

