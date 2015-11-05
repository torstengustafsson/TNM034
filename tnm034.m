function [ result ] = tnm034( im )
%
% im: Image of unknown face, RGB-image in uint8 format in the
% range [0,255]
%
% id: The identity number (integer) of the identified person,
% i.e. �1�, �2�,�,�16� for the persons

% I'm done. Fix it all, boys!

    processedImage = detectFace(im);

    result = false;
    if processedImage ~= 0
        result = compareToDB(processedImage);
    end

end