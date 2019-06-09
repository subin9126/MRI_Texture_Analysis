function [ output_args ] = b_GMGLCManalysis(QuantFolder)

% 0. Settings
ROIs={'left-MGN','left-LGN','left-Pul'}; %SET (ROI names)
Labels=[8200 8201 8202]; %SET (ROIlabels)
numROIs = length(ROIs);

tStart = tic;
FeatureNum = 22;


for m = 1:numROIs
    % 1. For current ROI, find QuantROI directory and make space for data
    ROI = ROIs{m};
    ROIFolder = strcat(QuantFolder,'/',ROI);
    QuantROIFiles = dir(fullfile(ROIFolder, strcat('Quant_',ROI,'*.nii'))); % or 'QuantHistNorm_',ROI,'*.nii'
    numQuantROIFiles = length(QuantROIFiles, 1);
    
    ROITextureFeatures = zeros(numQuantROIFiles,FeatureNum);    
    Subjects = cell(numQuantROIFiles,1);
    
    for idxFile = 1:numQuantROIFiles
        
        % 2. Load QuantROI image and make mask
        QuantROIGMImage = load_untouch_nii(strcat(ROIFolder,'/',QuantROIFiles(idxFile).name));  % Edited by LSB 171119
        QuantROIGM = QuantROIGMImage.img;
        ROIMask = (QuantROIGMImage.img>0);
        
        % 3. GLCM Texture Analysis and save data:
        FeatureVector = GLCMFeature(QuantROIGM, ROIMask);
        
        ROITextureFeatures(idxFile,:) = transpose(FeatureVector);   
        Subjects{idxFile,1}= QuantROIFiles(idxFile).name(1:end-4);
        
    end %end subject
    
    % 4. Write matrix of subjectnames and texture values of current subnuclei ROI
    ROITextureFeatures = [Subjects ROITextureFeatures];
    Filename = strcat('TextureValues_',ROI,'.mat');
    save(Filename,'ROITextureFeatures');
    
end %end current ROI

tElapsed = toc(tStart);
fprintf('Processing time: %.3f min/n', tElapsed / 60);
end

