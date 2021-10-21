# TextureAnalysis

Calculate GLCM texture features from FreeSurfer-defined regions-of-interest (ROI) from MRI scans (T1-weigthed images) of multiple subjects.
Run the following two codes.

<b> 1.  PreprocessingSteps_v2_2.m </b>


Description:
* Performs preprocessing of T1-weighted image for texture analysis
* Consists of the following steps:
    * Masking of T1-weighted image and ROI mask
    * Collewet normalization (removes voxels that are outside the +- 3SD range)
    * Intensity normalization (divides each ROI voxel by the mean voxel value of the lateral ventricles)
    * Quantization (rescales the signal intensities of the ROI voxels to a scale input by user)

Usage:
* Prepare a main folder 'MAINFolder' where input and output files will be placed
* Prepare a folder '1_nii' that contains isovoxel T1-weighted images of all subjects
* Prepare a folder '2_fsmasks' that contains FreeSurfer-derived ROI masks (e.g. wmparc.mgz). Assumes that wmparc.mgz have been transformed to the same subject-space as the T1-weighted images in the '1_nii' folders, and to .nii type.
* In script, edit 'population', 'ROIname', and 'ROIname_short' according to preference
* In script, edit 'ROI' so that it refers to labels of ROI in the FreeSurfer-derived ROI masks
* In script, control whether to do DO_MASKING, DO_COLLEWETNORMALIZE, DO_INTNORMALIZE, DO_QUANTIZE by switching value to 1 (do) or 0 (don't do)
* In script, Ref_ROILabel refers to the labels in wmparc.mgz that correspond to left and right lateral ventricles
* In script, edit Quantlevel to the number of greylevels wanted for GLCM analysis (default is set to 32 levels).

<b> 2. TextureAnalysis_ROI_v2_2.m </b>

Description:
* Uses quantized ROI T1-weighted images and calculates GLCM texture features for each specified ROI

Usage:
* Run for all ROIs 

