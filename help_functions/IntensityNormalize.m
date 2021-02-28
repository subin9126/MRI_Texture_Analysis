function [IntNorm_Image, Ref_meanintensity, intnorm_stats] = IntensityNormalize(ROIImage_to_normalize, Ref_FSMask, Ref_ROILabel, Ref_Image)
% Calculates mean signal intensity of provided Reference Region (ex. Lateral Ventricle T1 signal intensities), 
% and divides all voxels in the Image-of-interest by this value.
% Essentially, normalizes the provided ROI image by the reference ROI's mean signal intensity.
%
% Inputs
% ROIImage_to_normalize:  a 3D matrix; no struct (ex. collewet-normalized precuneus image)
% Ref_FSMask:  a 3D matrix; no struct; Mask that contains label of reference region (ex. FSMask)
% Ref_ROILabel:  Label number(s) of the reference region (ex. 4 and 43 for lateral ventricles)
% Ref_Image:  a 3D matrix; no struct; Image that contains original signal intensities of the reference region (ex. T1 image)
% 
% Output
% IntNorm_Image: a 3D matrix; no struct; ROIImage_to_normalize that has been divided by average intensity of Ref_ROILabel voxels in Ref_Image.
% Ref_meanintensity: average intensity of Ref_ROILabel voxels in Ref_Image.

%After I deactivated this class-change part, the INTNORM files started
%coming out appropriately....
%
%     if isa(ROIImage_to_normalize, 'double') == 0
%         warning('Changing class %s to double \n', class(ROIImage_to_normalize))
%         ROIImage_to_normalize = double(ROIImage_to_normalize); %just in case
%                 load('warning_subjidx.mat');
%                 warning_subjidx_intnorm = [warning_subjidx_intnorm; idx]; 
%                 save('warning_subjidx.mat');
%     end

    Ref_FSMask(~ismember(Ref_FSMask, Ref_ROILabel)) = 0;
    Ref_FSMask(ismember(Ref_FSMask, Ref_ROILabel)) = 1;

    % Calculate RefROI average intensity:
    [RefX, RefY, RefZ] = ind2sub(size(Ref_FSMask), find(Ref_FSMask==1));
    numRefVoxels = length(RefX);
    refroi_intensities = zeros(numRefVoxels,1);
    for r = 1:numRefVoxels
        refroi_intensities(r,1) = Ref_Image(RefX(r),RefY(r),RefZ(r));
    end
    Ref_meanintensity = mean(refroi_intensities);
    
    
    % Divide all values in ROIImage_to_normalize by Ref_meanintensity
    IntNorm_Image = ROIImage_to_normalize ./ Ref_meanintensity;
        
    
    % Stats of IntNorm_Image:
    [INX, INY, INZ] = ind2sub(size(IntNorm_Image), find(IntNorm_Image>0)); 
    IntNorm_Values = zeros(length(INX),1);
    
    for ii = 1:length(INX)
        IntNorm_Values(ii,1) = IntNorm_Image(INX(ii), INY(ii), INZ(ii));    
    end
    
    intnorm_stats = [min(IntNorm_Values) mean(IntNorm_Values) max(IntNorm_Values)];
    
    
end