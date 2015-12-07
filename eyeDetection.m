function [leftEye, rightEye, eyeImg] = eyeDetection(subImage, faceMask, mouthCenter)

leftEye=0;rightEye = 0;

[sizeX, sizeY] = size(faceMask);
%eye map

%Minimum size of the eye is 0.0063 percent
nrEyePixels = round(sizeX*sizeY*0.00063);

%Convert to yCbCr color space
subImageYCbCr = rgb2ycbcr(subImage);
im2Y = im2double(subImageYCbCr(:,:,1));
im2Cb = im2double(subImageYCbCr(:,:,2));
im2Cr = im2double(subImageYCbCr(:,:,3));


%Magical equations to get eyeMapC
Cb2 = im2Cb.*im2Cb;
Cr2 = (1-im2Cr).^2;%*(1-im2Cr);
CbCr = im2Cb./im2Cr;
eyeMapC = (1/3) .* (Cb2 +Cr2+CbCr);

%histogram equalization
eyeMapHq = histeq(eyeMapC);


%Luminance eyeMapL
se = strel('disk', 4);
eyeMapL = imdilate(im2Y, se)./(imerode(im2Y,se)+1);
eyeMapL = eyeMapL/max(eyeMapL(:));


%full eyeMap
eyeMap = eyeMapHq.*eyeMapL;
se2 = strel('disk', 10);
dilatedEyeMap = imdilate(eyeMap, se2);

%find eyes as a mask
dilatedEyeMap = (dilatedEyeMap./max(dilatedEyeMap(:))).*faceMask;


%Declare final eye image
eyeImg = 0;

%Loop though eyeImg intensity value and stop when we find two eyes.
for intensityThreshold = 99:-1:40
    
    eyeImg = dilatedEyeMap>(intensityThreshold/100);
    
    %Filter away eye outside of a certain area defined by two circles
    %and one cone.
    innerRadius = (mouthCenter(2)*0.3)^2;
    outerRadius = (mouthCenter(2)*0.7)^2;
    [sizeX, sizeY] = size(faceMask);
    [X, Y] = meshgrid(1:sizeY, 1:sizeX);
    tempMask1 = ( (innerRadius * (Y - mouthCenter(2)) .^ 2 + innerRadius * (X - mouthCenter(1)) .^ 2) <= innerRadius^2 );
    tempMask2 = ( (outerRadius * (Y - mouthCenter(2)) .^ 2 + outerRadius * (X - mouthCenter(1)) .^ 2) <= outerRadius^2 );

    %The cone.
    c = [1 size(faceMask,2)/2 size(faceMask,2)];
    r = [size(faceMask,1)/10 size(faceMask,1) size(faceMask,1)/10];
    tempMask3 = roipoly(faceMask,c,r);

    %Final mask that represent the area where eyes may be.
    tempMask = (tempMask2-tempMask1).*tempMask3;
    
    %remove white pixels below mouth
    tempMask((mouthCenter(2)-20):end, : )=0;
    figure;imshow(eyeImg)
    eyeImg = eyeImg.*tempMask;
    eyeImg = bwareaopen(eyeImg, nrEyePixels);
    [centerCoord, r] = imfindcircles(eyeImg,[10,20]);
    %If we found two eyes or more
    figure;imshow(eyeImg)
    if(size(centerCoord, 1) == 2)
        centerCoord = sortrows(centerCoord);
        leftEye = round(centerCoord(1,:));
        rightEye = round(centerCoord(2,:));
        size(centerCoord, 1)
        break;           
       
    elseif (size(centerCoord, 1) > 2)
        %loop through all pointsand measure thier distance. Merge points if lower
        %than 2*radius
        for i = 1:size(centerCoord, 1)-1
            for j = i+1:size(centerCoord, 1)
                eye2eye=[centerCoord(i,:);
                         centerCoord(j,:)];
                distance = pdist(eye2eye,'minkowski');
                if(distance < 2*r)
                    centerCoord(i,1) = round( (centerCoord(i,1)+centerCoord(j,1))/2);
                    centerCoord(i,2) = round( (centerCoord(i,2)+centerCoord(j,2))/2);

                    %remove unwanted points
                    centerCoord(j,:) = [sizeX, 0];
                end
            end
        end
        %take just 1 eye on each side of the face
        leftCount = 1;
        rightCount = 1;
        for i = 1:size(centerCoord,1)
            %find all distances to centerline
            if  centerCoord(i,1) > mouthCenter(1)
                eye2line = [ centerCoord(i,:) ;
                             mouthCenter(1), centerCoord(i,2) ];

                leftDistance(leftCount, i) = pdist(eye2line,'minkowski');
                leftCount = leftCount+1;
            elseif centerCoord(i,1) < mouthCenter(1)
                eye2line = [ centerCoord(i,:) ;
                             mouthCenter(1), centerCoord(i,2) ];

                rightDistance(rightCount,i) = pdist(eye2line,'minkowski');
                rightCount = rightCount+1;
            end        
        end
        [~, leftIndex] = min(leftDistance);
        [~, rightIndex] = min(rightDistance);
        leftEye = centerCoord(leftIndex,:);
        rightEye = centerCoord(rightIndex,:);

        break;
     end
        
end
            


