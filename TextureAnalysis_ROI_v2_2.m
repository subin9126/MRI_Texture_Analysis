% About:
% Code for calculating GLCM texture features from quantized MRI files (output from PreprocessingSteps_v2_2.m).
% Processes multiple subjects AND multiple ROIs in one run.
%
% Input:
% Specify the name of ROIs to process (can enter multiple ROIs), must match ROI names used from preprocessing code.
%
% Output:
% 'AllsubjTextureData_combined' - n-by-m table which contains GLCM texture values from each ROI (m) for all subjects (n).
% 'AllsubjTextureData'          - structure array containing subjectname and texture data of all subjects for each ROI
% 'log_TA_run<date>_<ROIs>.mat' - workspace that saves outputs from current run.
%  GLCM files:  .mat files of each region created in GLCMS folder per subject (average of all 13 GLCMs)
                                             

%++++++++++++++++++++Specify Accordingly+++++++++++++++++++++++++++++++++++
clear
% Define which ROIs will be processed
% (ROI names should correspond to those used from preprocessing step).
ROIs = {'hippocampus','inferiortemporal','middletemporal', 'superiorparietal'};  
ROIs_short = {'hpc', 'inftmp', 'midtmp', 'suppar'}; 

% Define path to quantized ROI images
QHNDir = '/media/ws1/DATA/TEXTURE_PRD/6_quant';

% Other settings (leave as default unless otherwise)
numFeatures = 22;
QuantLevel = 32;
startidx = 1; %in case of rerunning code starting from a diff subject

%++++++++++++++++++++Do Not Change Below+++++++++++++++++++++++++++++++++++++++++++++++++++++
numROIs = length(ROIs);

GLCMatrixFolder = [QHNDir '/0_GLCMS'];
if exist(GLCMatrixFolder, 'dir')==0
    mkdir(GLCMatrixFolder)
end

if length(ROIs) ~= length(ROIs_short)
    error('Number of ROIs and ROIs_short do not match')
end


    % For saving all subjects' texture data from all regions
    AllsubjTextureData = struct;                                           
    fields = [ROIs'; 'Subjects'];   
    
    AllsubjTextureData_combined = table;
    
    
    for m = startidx:numROIs
        tStart = tic; 
        fprintf('=====Calculating texture features for %s===== \n', ROIs{m})
        ROIQHNFolder = [QHNDir '/' ROIs{m}];   
        ROIQHNFiles = dir(fullfile(ROIQHNFolder, '*Quant*.nii'));   
        numROIQHNFiles = size(ROIQHNFiles, 1);                              
      
        % To save subjecname and texture features of all subj for current ROI
        AllsubjTextureData.(fields{numROIs+1}) = cell(numROIQHNFiles,1);    
        AllsubjTextureData.(fields{m}) = zeros(numROIQHNFiles,numFeatures); 

        for idxFile = 1:numROIQHNFiles 
            fprintf('-----Doing subject %i of %i\n',idxFile,numROIQHNFiles)
            % 0. Load Quantized, HistogramNormalized ROI image(values:0~64)
            ROIQHNImage = load_untouch_nii(strcat(ROIQHNFolder,'/',ROIQHNFiles(idxFile).name)); 
            QuantROIGM = ROIQHNImage.img;      
            
            % 1. Make binary ROI mask by thresholding ROIQHNImage
            ROIMask = (ROIQHNImage.img>0);                                  
            
            % 2. Texture Analysis 
            [FeatureVector, GLCMatrix] = GLCMFeature_181103(QuantROIGM, ROIMask, QuantLevel);  
            % 2.1 Save subjectname and texture data
            AllsubjTextureData.(fields{m})(idxFile,:) = transpose(FeatureVector);  
            AllsubjTextureData.(fields{numROIs+1}){idxFile} = extractfrom(ROIQHNFiles(idxFile).name,'_T1',15,-3); 
            clear FeatureVector ;             
            
            % 3. Save averaged GLCM for each subject (for future possible reference)
            GLCMname = [QHNDir '/0_GLCMS/GLCM_' ROIQHNFiles(idxFile).name(1:end-4) '.mat'];
            save(GLCMname, 'GLCMatrix' );
            

        end
        
        % 4. Save subjects' roi data as table format:
        roi_data = AllsubjTextureData.(fields{m});
        
        roi_tvarnames = {};
        for tv = 1:numFeatures
            roi_tvarnames{1,tv} = strcat(ROIs_short{m},'_T',num2str(tv,'%i'));
        end
        
        roi_table = array2table(roi_data, 'VariableNames', roi_tvarnames);
        
        AllsubjTextureData_combined = [AllsubjTextureData_combined roi_table];
        
        
        
        % 5. Done with one ROI       
        tElapsed = toc(tStart); 
        fprintf('Processing time: %.3f min \n', tElapsed / 60);
    end
    
    % 6. Put it all together and save:
    AllsubjTextureData_combined = [array2table(AllsubjTextureData.Subjects,'VariableNames',{'Subjects'}) AllsubjTextureData_combined];
    
    rundate = datestr(now, 'yymmdd'); 
    runroi = strjoin(ROIs_short, ',');
    
    workspacename = [pwd '/log_TA_run' rundate '_' runroi '.mat'];
    save(workspacename) 
    
    
    
