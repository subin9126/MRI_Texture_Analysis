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
* Prepare a folder '1_nii' that contains isovoxel T1-weighted images of all subjects
* Prepare a folder '2_fsmasks' that contains FreeSurfer-derived ROI masks (e.g. wmparc.mgz). Assumes that wmparc.mgz have been transformed to the same subject-space as the T1-weighted images in the '1_nii' folders, and to .nii type (for this, use code -----).


<b> 2. TextureAnalysis_ROI_v2_2.m </b>

Description:
* Uses quantized ROI T1-weighted images and calculates GLCM texture features for each specified ROI
* Texture features computed include: Energy, Entropy, Dissimilarity, Contrast, ..., Autocorrelation, ClusterShade, ClusterProminence, ...,


