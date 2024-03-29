% About:
% Code for preprocessing MRI scans for texture analysis.
% Run for multiple subjects, one ROI at a time (example: hippocampus).
% Default is to run all step at once. 
% Steps can be run individually, but note that each step requires output from previous step.
%
% Input:
% Specify directory where files are.
% Specify the name of ROI (user-define) and FreeSurfer label corresponding to that ROI (reference FreeSurfer LookUp Table)
%
% Output:
% Masking step 
%   - a nifti file that contains MRI intensities in ROI only
% 
% CollewetNormalize step and IntensityNormalize step
%   - a nifti file that contains MRI intensities in ROI that are between -3 and +3 standard deviations range from mean intensity.
%   - a nifti file that contains MRI intensities in ROI that are successively normalized to mean CSF intensity (default is lateral ventricles).
%   - a table 'All_PreprocessingStatsROI' that summarizes original and processed intensity values of ROI.
%   - a workspace 'log_prep_run_<date>_<ROI>.mat' that saves this table and other variables.
%
% Quantize step
%   - a nifti file that contains MRI intensities in ROI that are successively quantized to specified quantization level (default is 32).

%++++++++++++++++++++Specify Accordingly+++++++++++++++++++++++++++++++++++
% Define paths to files
MAINFolder = '/media/ws1/DATA/TEXTURE_PRD';
T1Folder =           [MAINFolder '/1_nii'];
FSMaskFolder =       [MAINFolder '/2_fsmasks']; 
ROIMasked_T1Folder = [MAINFolder '/3_roimasked'];  
CollewetFolder =     [MAINFolder '/4_collewet']; 
IntNormFolder =      [MAINFolder '/5_intnorm'];
QuantizedFolder =    [MAINFolder '/6_quant']; 

% Define which ROI will be processed:
ROIname = 'hippocampus'; 
                % string for user-defined ROI full name

ROIname_short = 'hpc';
                % string for user-defined ROI name short-verison
                
ROI = [17 53];
                % vector containing FreeSurfer-defined labels of ROI (example is from aparc+aseg.mgz):
                
% Define what steps to run (0 for don't and 1 for do):
DO_MASKING = 1;
DO_COLLEWETNORMALIZE= 1; 
DO_INTNORMALIZE = 1; %0=no 1=do 9=already did so skip
    Ref_ROILabel = [4 43]; %Lateral Ventricles default
DO_QUANTIZE = 1;
    QuantLevel = 32;
 
 
%++++++++++++++++++++Do Not Change Below+++++++++++++++++++++++++++++++++++++++++++++++++++++   
ROIMasked_T1Folder = [ROIMasked_T1Folder '/' ROIname];
CollewetFolder = [CollewetFolder '/' ROIname];
IntNormFolder = [IntNormFolder '/' ROIname];
QuantizedFolder = [QuantizedFolder '/' ROIname];

if exist(ROIMasked_T1Folder, 'dir')==0
    mkdir(ROIMasked_T1Folder)
end
if exist(CollewetFolder, 'dir')==0
    mkdir(CollewetFolder)
end
if exist(IntNormFolder, 'dir')==0
    mkdir(IntNormFolder)
end
if exist(QuantizedFolder, 'dir')==0 
    mkdir(QuantizedFolder)
end


%---------------------------------------------------
if DO_MASKING == 1
    T1Files = dir(fullfile(T1Folder, '*.nii'));
    FSMaskFiles = dir(fullfile(FSMaskFolder, '*.nii'));
    
    if length(T1Files) ~= length(FSMaskFiles)
        error('Error during DO_MASKING: \nNumber of T1 (%i) and FSMasks (%i) dont match', length(T1Files), length(FSMaskFiles))
    end
    
    for idx = 1:length(T1Files)
        
        fprintf('====masking subject %i ====\n', idx) 
        fprintf('-------%s, \n-------%s \n', T1Files(idx).name, FSMaskFiles(idx).name)
        
        SubjectT1 = load_untouch_nii(strcat(T1Folder, '/', T1Files(idx).name));
        SubjectROIMask = load_untouch_nii(strcat(FSMaskFolder, '/', FSMaskFiles(idx).name));

        SubjectROIMask.img(~ismember(SubjectROIMask.img, ROI)) = 0;
        SubjectROIMask.img(ismember(SubjectROIMask.img,ROI)) = 1;

        ROIMasked_T1 = SubjectT1;
        ROIMasked_T1.img = zeros(size(SubjectT1.img));
        
        ROIMasked_T1.img = Masking(SubjectT1.img, SubjectROIMask.img);
    
        outputname = strcat(ROIMasked_T1Folder, '/', ROIname,'_', T1Files(idx).name);
        save_untouch_nii(ROIMasked_T1, outputname);
        
        clear SubjectTI SubjectROIMask
    end
end

%---------------------------------------------------
if DO_COLLEWETNORMALIZE == 1
    ROIMasked_T1Files = dir(fullfile(ROIMasked_T1Folder, '*.nii'));
    FSMaskFiles = dir(fullfile(FSMaskFolder, '*.nii'));
    
    if length(ROIMasked_T1Files) ~= length(FSMaskFiles)
        error('Error during COLLEWETNORMALIZE: \nNumber of ROIMasked_T1 and FSMaskFiles dont match ')
    end  
    
    All_orig_stats = []; All_theoretical_stats = []; All_collewetnorm_stats = [];
    
    for idx = 1:length(ROIMasked_T1Files)
        
        fprintf('====collewet normalizing subject %i ====\n', idx) 
        fprintf('-------%s, \n-------%s \n', ROIMasked_T1Files(idx).name, FSMaskFiles(idx).name)
        
        Subject_ROIMasked_T1 = load_untouch_nii(strcat(ROIMasked_T1Folder, '/', ROIMasked_T1Files(idx).name));
        Subject_FSMask = load_untouch_nii(strcat(FSMaskFolder, '/', FSMaskFiles(idx).name));
        
        if size(Subject_ROIMasked_T1.img) ~= size(Subject_FSMask.img)
            error('Error during DO_COLLEWETNORMALIZE: \nROIMasked T1 and FSMask size dont match for Subject %i', idx)
        end
    
        ROI_for_collewet = ROI;
        
        % Collewet method (remove voxels beyond 3SD range of designated ROI)
        collewetnorm_ROI = Subject_ROIMasked_T1;
        collewetnorm_ROI.img = zeros(size(Subject_ROIMasked_T1.img));
        
        [collewetnorm_ROI.img, orig_stats, theoretical_range_stats, collewetnorm_stats] = ...
            CollewetMethod_v2(Subject_ROIMasked_T1.img, Subject_FSMask.img, ROI_for_collewet, idx);
            
        All_orig_stats = [All_orig_stats; orig_stats ];
        All_theoretical_stats = [All_theoretical_stats; theoretical_range_stats ];
        All_collewetnorm_stats = [All_collewetnorm_stats; collewetnorm_stats ];
        
        outputname = strcat(CollewetFolder, '/', '3SDexcl_',ROIMasked_T1Files(idx).name);
        save_untouch_nii(collewetnorm_ROI, outputname);           
    end
end


%---------------------------------------------------
if DO_INTNORMALIZE == 1
    
    CollewetFiles = dir(fullfile(CollewetFolder, '*.nii'));
    FSMaskFiles = dir(fullfile(FSMaskFolder, '*.nii'));   
    T1Files = dir(fullfile(T1Folder, '*.nii'));
    
    if length(CollewetFiles) ~= length(FSMaskFiles)
        error('Error during INTNORMALIZE: \nNumber of CollewetFiles and FSMaskFiles dont match ')
    end
    
    All_LatVent_MeanIntensity = zeros(length(FSMaskFiles), 1);
    All_intnorm_stats = [];
    
    for idx = 1:length(FSMaskFiles)
        
       fprintf('====intensity normalizing subject %i ====\n', idx) 
       fprintf('-------%s, \n-------%s \n-------%s\n', CollewetFiles(idx).name, FSMaskFiles(idx).name, T1Files(idx).name)
       
       Subject_CollewetImg = load_untouch_nii(strcat(CollewetFolder, '/', CollewetFiles(idx).name));
       Subject_FSMask = load_untouch_nii(strcat(FSMaskFolder, '/', FSMaskFiles(idx).name));
       SubjectT1 = load_untouch_nii(strcat(T1Folder, '/', T1Files(idx).name));
       
       Subject_IntNormImg = Subject_CollewetImg;
       Subject_IntNormImg.img = zeros(size(Subject_CollewetImg.img));
        
       [Subject_IntNormImg.img, Subject_ref_meanintensity, intnorm_stats] = ...\
           IntensityNormalize(Subject_CollewetImg.img, Subject_FSMask.img, Ref_ROILabel, SubjectT1.img);
       
       All_LatVent_MeanIntensity(idx,1) = Subject_ref_meanintensity;
       All_intnorm_stats = [All_intnorm_stats; intnorm_stats ];
       
       outputname = strcat(IntNormFolder, '/', 'IN_',CollewetFiles(idx).name);
       save_untouch_nii(Subject_IntNormImg, outputname);  
    end
end



%---------------------------------------------------
if DO_QUANTIZE == 1
    
    if DO_INTNORMALIZE==0
        PreprocessedFolder = CollewetFolder;
    elseif DO_INTNORMALIZE==1 || DO_INTNORMALIZE==9
        PreprocessedFolder = IntNormFolder;
    end
    PreprocessedFiles = dir(fullfile(PreprocessedFolder, '*.nii'));
    
    quantmax_values = [];
    for idx = 1:length(PreprocessedFiles)
        
        fprintf('====quantizing subject %i ====\n', idx) 
        fprintf('-------%s\n', PreprocessedFiles(idx).name)
        
        Subject_preprocessed = load_untouch_nii(strcat(PreprocessedFolder, '/', PreprocessedFiles(idx).name));        
        
        QuantizedImg = Subject_preprocessed;
        QuantizedImg.img = zeros(size(Subject_preprocessed.img));

        % Quantized ROI image:
        [QuantizedImg.img, max_value] = Quantization(Subject_preprocessed.img, QuantLevel);
        quantmax_values = [quantmax_values; max_value];
        
        outputname = strcat(QuantizedFolder,'/Quant', num2str(QuantLevel,'%i'),'_',PreprocessedFiles(idx).name);
        save_untouch_nii(QuantizedImg, outputname);       
    end
end

%---------------------------------------------------
% Put it all together and save:
if DO_COLLEWETNORMALIZE == 1 && DO_INTNORMALIZE == 1

    varnames = {['origmin_' ROIname_short], ['origavg_' ROIname_short], ['origmax_' ROIname_short] ...
               ['theoretmin_' ROIname_short], ['theoretmax_' ROIname_short] ...
                ['colmin_' ROIname_short], ['colavg_' ROIname_short], ['colmax_' ROIname_short] ...
               ['inmin_' ROIname_short], ['inavg_' ROIname_short], ['inmax_' ROIname_short] ...
                };

    data = [All_orig_stats All_theoretical_stats All_collewetnorm_stats All_intnorm_stats];

    All_PreprocessingStatsROI = array2table(data, 'VariableNames', varnames);

    rundate = datestr(now, 'yymmdd');

    workspacename = [pwd '/log_prep_run' rundate '_' ROIname '.mat'];
    save(workspacename)
end
    
%---------------------------------------------------        
        
      
