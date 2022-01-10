function [QuantizedImg, max_value] = Quantization(ROIImage, QuantLevel)
% Asssumes that input image is already ROI-masked
% Thus all voxels in ROIImage excluding background voxels (o value) will be
% quantized.
%
% Input
% ROIImage:   a 3D matrix; no struct variable. (ex. ROI-masked, preprocessed MRI)
% QuantLevel: a single number. (ex. 64)
%
% Output
% QuantizedImg: a 3D matrix; no struct variable. Quantized image.
% max_value:    max value of QuantizedImg, just to keep records.
%
% [Subin Lee: subin9126@hotmail.com]

    % Find ROI voxels to quantize:
    ROIImgValues = ROIImage(ROIImage>0);
    VoxelNum = length(ROIImgValues);

    % Prep for quantization:
    ImgMin = min(ROIImgValues);
    ImgMax = max(ROIImgValues);
    Range = ImgMax - ImgMin;
    Q = QuantLevel - 1;
    
    % Find coordinates of voxels where ROI are:
    % To exclude 0 values from background during quantization:
    [X,Y,Z] = ind2sub(size(ROIImage), find(ROIImage>0));
    
    QuantizedImg = zeros(size(ROIImage));
    QuantizedValues = zeros(length(ROIImgValues),1);
    for i = 1:VoxelNum
        QuantizedValues(i,1) = (((ROIImgValues(i) - ImgMin)*(Q))/ Range) + 1;
        QuantizedImg(X(i),Y(i),Z(i)) = floor(QuantizedValues(i,1));
    end
% forget this. just testin.    
%     levels = [1+(63/64):(63/64):64-(63/64)];
%     QuantizedValues = imquantize(ROIImgValues,levels);

    max_value = max(max(max(QuantizedImg)));

end
