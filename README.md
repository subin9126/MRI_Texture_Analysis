# MRI Texture Analysis

Calculate GLCM texture features from FreeSurfer-defined regions-of-interest (ROI) from MRI scans (T1-weigthed images) of multiple subjects.
Run the following two codes.

## (1) PreprocessingSteps_v2_2.m


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


## (2) TextureAnalysis_ROI_v2_2.m

Description:
* Uses quantized ROI T1-weighted images and calculates GLCM texture features for each specified ROI
* Texture features computed include [1-4]: 
   * Energy
   * Entropy
   * Dissimilarity
   * Contrast
   * Inverse Difference
   * Correlation
   * Homogeneity
   * Autocorrelation
   * ClusterShade 
   * ClusterProminence
   * Maximum Probability
   * SumOfSquares
   * SumAverage
   * SumVariance
   * SumEntropy
   * DifferenceVariance
   * DifferenceEntropy
   * InformationMeasuresCorrelationI
   * InformationMeasuresCorrelationII
   * InverseDifferenceNormalized
   * InverseDifferenceMomentNormalized


### <b> Acknowledgements </b>

The GLCMFeature calculation codes were adapted and modified from codes by Avinash Uppuluri [5].

### References:
1. R. M. Haralick, K. Shanmugam, and I. Dinstein, Textural Features of Image Classification, IEEE Transactions on Systems, Man and Cybernetics, vol. SMC-3, no. 6, Nov. 1973
2. L. Soh and C. Tsatsoulis, Texture Analysis of SAR Sea Ice Imagery Using Gray Level Co-Occurrence Matrices, IEEE Transactions on Geoscience and Remote Sensing, vol. 37, no. 2, March 1999.
3. D A. Clausi, An analysis of co-occurrence texture statistics as a function of grey level quantization, Can. J. Remote Sensing, vol. 28, no.1, pp. 45-62, 2002.
4. http://murphylab.web.cmu.edu/publications/boland/boland_node26.html
5. https://www.mathworks.com/matlabcentral/fileexchange/22354-glcm_features4-m-vectorized-version-of-glcm_features1-m-with-code-changes?s_tid=prof_contriblnk
