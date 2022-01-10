function [collewetnorm_ROI, orig_stats, theoreticalrange_stats, collewetnorm_stats] = CollewetMethod_v2(Image, ROIMask, ROI, idx)
% Removes values that lie beyond 3SD range from mean of input (ROI parts of Image)
% V2.
% - fixed error in original 'CollewetMethod.m' code, in which the output
%   collewetnorm_ROI had more values than the original Image.
% - it was because it searched for values within the theoretical range from
%   the original whole image, rather than the ROI-bounded image.
% - edited points (1) added ROIMask binarizing step. 
%                 (2) added ROIMask*Image masking step 
%                 (3) perform collewetnorm on ROImasked Image rather than whole Image
%
% Inputs
% Image:   a 3D matrix; no struct variable. (ex. GMMasked_BC_T2.img)
% ROIMask: a 3D matrix; no struct variable. (ex. FSMask.img) (ex2. GMMask.img)
% ROI:     a number or vector of ROI labels to be analyzed. (ex. [8 47] for cerebellar GM)
%
% Outputs
% collewetnorm_ROI: a 3D matrix; (image) with voxels outside 3SD range removed.
% orig_stats:              a 1x3 vector; min, mean, max of original intensity of Image
% theoretical_range_stats: a 1x2 vector; min, max of theoretical range based on Image's -3 SD~3 SD range.
% collewetnorm_stats:      a 1x3 vector; min, mean, max of collewet-normed intensity of Image
%
% [Subin Lee: subin9126@hotmail.com]
    
    % 0. Binarized ROImask
    ROIMask(~ismember(ROIMask, ROI)) = 0;
    ROIMask(ismember(ROIMask, ROI)) = 1;

    roimasked_Image = Masking(Image, ROIMask);
    
    % 1. Bring MRI values in ROI
    [ROIX,ROIY,ROIZ]= ind2sub(size(roimasked_Image), find(ismember(ROIMask,ROI)));
    ROI_Values = zeros(1,length(ROIX));
    
    for i = 1:length(ROIX)
        ROI_Values(i) = roimasked_Image(ROIX(i),ROIY(i),ROIZ(i));
    end 
    
    if length(find(ROI_Values==0)) > 0
        %error('Zero-values found in ROI. ROImask and Image may not be overlapping well.')
        warning('Zero-values found in ROI areas. ROImask and Image may not be overlapping well.')
                load('warning_subjidx.mat');
                warning_subjidx_collewet = [warning_subjidx_collewet; idx]; %vertcat(warning_subjidx_collewet, idx);
                save('warning_subjidx.mat');
    end
    
    
    
   %%%%% Save original range of the ROI before Collewet Histnorm %%%%%%%%
    orig_stats = [min(ROI_Values) mean(ROI_Values) max(ROI_Values)];
    
    
    % 2. Extract Theoretical values from ROI MRI
    %   (will reduce range of intensities to analyze):
    orig_signalMean = mean(ROI_Values);  
    orig_signalSD = std(ROI_Values);
    
    TheoreticalMin = orig_signalMean - 3*orig_signalSD; 
    TheoreticalMax = orig_signalMean + 3*orig_signalSD;
    
    if TheoreticalMin < 0        % in case the HistNorm min is less than 0 (3sd range exceeds positive scale), change to 0.1.
        TheoreticalMin = 0.1;
        warning('Subject %d has negative Collewet range min \n', idx)
    else
    end
     
    %%%%% Save theoretical range.  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Actual collewet image may not have same min and max as theoretical
    theoreticalrange_stats = [TheoreticalMin TheoreticalMax];
 
    
    
    
    % 3. Extract MRI values that are within Theoretical Range:
    collewetnorm_values = ROI_Values(ROI_Values>=TheoreticalMin & ROI_Values<=TheoreticalMax);
    %%%%% Save collewetnormed range.  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    collewetnorm_stats = [min(collewetnorm_values) mean(collewetnorm_values) max(collewetnorm_values)];  
    
    
    % Writing of Collewet-normed ROI Image
    collewetnorm_ROI = zeros(size(roimasked_Image));
%    [HX,HY,HZ] = ind2sub(size(Image), find(Image >= TheoreticalMin & Image <= TheoreticalMax ));
    [HX,HY,HZ] = ind2sub(size(roimasked_Image), find(roimasked_Image >= TheoreticalMin & roimasked_Image <= TheoreticalMax ));
    for ii = 1: length(HX)
        collewetnorm_ROI(HX(ii),HY(ii),HZ(ii)) = roimasked_Image(HX(ii),HY(ii),HZ(ii));
    end
   

    

end
