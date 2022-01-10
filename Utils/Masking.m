function [MaskedImage] = Masking(Image, Mask)
% Assumes Mask is binary****
%
% Input
% Image: a 3D matrix; no struct variable. (ex. SubjectT2.img)
% Mask:  a 3D matrix; no struct variable. (ex. Subject_GMMask.img)
%        must be a binary mask (0: no ROI, 1: ROI)
%
% Output
% MaskedImage: a 3D matrix; no struct variable. (ex. GMMasked_SubjectT2.img)
%
% [Subin Lee: subin9126@hotmail.com]

    % Check if Mask is binary:
    mask_values = unique(Mask);
    if min(mask_values)~=0 || max(mask_values)~=1 || length(mask_values)~=2
        error('Mask input is not a binary mask of 0 and 1')
    end

    % Check if size are same:
    if size(Image) ~= size(Mask)
        error('Size of Image and Mask for Masking do not match')
    end
    
    % Change any NaN values in Image and convert to 0
    % (NaNs can usually occur in background after using mri_convert)
    Image(isnan(Image)) = 0;

    % Masking:
    MaskedImage = Image .* Mask;

end
