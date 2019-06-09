% Written specifically for thalamus subnuclei texture analysis

clear

%% 0. Setting labels,directories,etc:
DX = ''; % SET 
DO_HISTNORM = 1; %0=do;1=don't
ROIs={'left-MGN','left-LGN','left-Pul'}; % SET (ROIname)
Labels=[8200 8201 8202]; %SET (ROIlabels)
numROIs = length(ROIs);

ImageFolder =strcat('');  %SET (Input file directory; rT1 images)
ImageFiles = dir(fullfile(ImageFolder, '*.nii'));
numImageFiles = size(ImageFiles);

FSoutputFolder = strcat('');  %SET (Input file directory; FreeSurfer ROI masks)

OutputFolder = strcat(''); %SET(optional Output file directory; subnuclei ROI masks, orig_ROIs, HN_ROIs)
QuantFolder = strcat(''); %SET(Main Output file directory; histnorm/quantized ROIs)

%%
for idx = 1:numImageFiles
    
    fprintf('Doing %d of %d \n',idx,numImageFiles)
    
    Subjectname = strcat(ImageFiles(idx).name(1:15)); % To bring only 'xxxxxxxx_xxxxxx' and exclude the latter part of filename
    
    %OriginalImage = load_untouch_nii(strcat(ImageFolder, '/', ImageFiles(idx).name));
    OriginalImage2 = load_nii(strcat(ImageFolder, '/', ImageFiles(idx).name));
    FSMask = load_nii(strcat(FSoutputFolder, '/',Subjectname,'/mri/',Subjectname,'_wmparc.nii'));
    
    
    for m = 1:numROIs
        
        %% 1. Make subnuclei mask
        % Make copy of FSROI mask, then only leave labels corresponding to current ROI
        ROI = ROIs{m};
        subnucleiLabel = Labels(m);
        
        subnucleiMask = FSMask; 
        subnucleiMask.img(~ismember(subnucleiMask.img, subnucleiLabel)) = 0;
        subnucleiMask.img(ismember(subnucleiMask.img, subnucleiLabel)) = 1;
        ROIMask = subnucleiMask;
        
        save_nii(ROIMask, strcat(OutputFolder,'/',ROI,'_',Subjectname,'.nii'));
        
        
        
        %% 2. Extract T1 values from ROI:
        
        % load T1 ROI:
        ROI_OriginalImage = OriginalImage2;
        ROI_OriginalImage.img = zeros(size(OriginalImage2.img));
        % make empty HN and Quant ROI matrix in advance (for steps 3~4):
        if DO_HISTNORM ==1
            ROI_HistNormImage = ROI_OriginalImage;   ROI_HistNormImage.img = zeros(size(ROI_OriginalImage.img));
            ROI_QuantHistNormImage = ROI_OriginalImage;  ROI_QuantHistNormImage.img = zeros(size(ROI_OriginalImage.img));
        else 
            ROI_QuantImage = ROI_OriginalImage; ROI_QuantImage.img = zeros(size(ROI_OriginalImage.img));
        end
        
        % fill up roi mask coordinates of empty matrix with t1 values
        [ROIX ROIY ROIZ]= ind2sub(size(ROI_OriginalImage.img), find(ROIMask.img>0));
        ROI_Values = zeros(1,length(ROIX));
        
        for ii = 1:length(ROIX)
            ROI_OriginalImage.img(ROIX(ii),ROIY(ii),ROIZ(ii)) = OriginalImage2.img(ROIX(ii),ROIY(ii),ROIZ(ii));
            ROI_Values(ii) = OriginalImage2.img(ROIX(ii),ROIY(ii),ROIZ(ii));
        end
        save_nii(ROI_OriginalImage, strcat(OutputFolder,'/Orig_',ROI,'_',Subjectname,'.nii'));
        
       
        if DO_HISTNORM == 1
            %% 3A. Histogram Normalization using Collewet Method on T1 ROI + Quantization:
            ImgIntensityMean = mean(ROI_Values); ImgIntensitySD   = std(ROI_Values);
            ImgIntensityIncludeRange = [ImgIntensityMean - 3*ImgIntensitySD; ImgIntensityMean + 3*ImgIntensitySD];
            if ImgIntensityIncludeRange(1) <0
                ImgIntensityIncludeRange(1) = 1
                fprintf('Subject %d has negative Collewet range min \n', idx)
            else
                ImgIntensityIncludeRange(1)=ImgIntensityIncludeRange(1);
            end
            % The original intensity range of the ROI before Collewet Histnorm!
            AllSubjOrigIntensityRangeMin(idx,m) = min(ROI_Values);
            AllSubjOrigIntensityRangeMax(idx,m) = max(ROI_Values);
            % This is theoretical range! Actual image may not have the exact specified min max values.
            AllSubjImgIntensityIncludeRangeMin(idx,m) = ImgIntensityIncludeRange(1);
            AllSubjImgIntensityIncludeRangeMax(idx,m) = ImgIntensityIncludeRange(2);
            
            [HX,HY,HZ] = ind2sub(size(ROI_OriginalImage.img), find(ROI_OriginalImage.img >= ImgIntensityIncludeRange(1) & ROI_OriginalImage.img <= ImgIntensityIncludeRange(2) ));
            
            
            ROI_HistNormValues = ROI_Values(ROI_Values>=ImgIntensityIncludeRange(1) & ROI_Values<=ImgIntensityIncludeRange(2));
            ROI_HistNorm_Min=min(ROI_HistNormValues); ROI_HistNorm_Max=max(ROI_HistNormValues);
            Range = ROI_HistNorm_Max - ROI_HistNorm_Min;
            % This is the actual range of this image after Collewet Histnorm!
            ActualROIHNIntensitiesMin(idx,m) = ROI_HistNorm_Min;
            ActualROIHNIntensitiesMax(idx,m) = ROI_HistNorm_Max;
            Collection_HNImgIntensityMeans(idx,m) = mean(ROI_HistNormValues);
            
            % 3a-2) Actual Quantization
            for iii = 1: length(HX)
                ROI_HistNormImage.img(HX(iii),HY(iii),HZ(iii)) = ROI_OriginalImage.img(HX(iii),HY(iii),HZ(iii)); %making copy of original t1 (excluding parts outside HN range) before quantizing
                
                ROI_QuantHistNormImage.img(HX(iii),HY(iii),HZ(iii)) = (((ROI_HistNormValues(iii) -ROI_HistNorm_Min)*(63))/Range)+1; %qunatizing to 64 bins
                ROI_QuantHistNormImage.img(HX(iii),HY(iii),HZ(iii)) = floor(ROI_QuantHistNormImage.img(HX(iii),HY(iii),HZ(iii))); %make into discrete values
            end
            save_nii(ROI_HistNormImage, strcat(OutputFolder,'/HistNorm_',Subjectname,'.nii'));
            save_nii(ROI_QuantHistNormImage, strcat(QuantFolder,'/',ROI,'/QuantHistNorm_',ROI,'_',Subjectname,'.nii'));
            
        else
            %% 3B. Just Quantization:
            ROI_Min = min(ROI_Values); 
            ROI_Max = max(ROI_Values);
            Range = ROI_Max - ROI_Min;
            for iii = 1:length(ROIX)
                %ROI_QuantImage.img(ROIX(iii),ROIY(iii),ROIZ(iii)) = ROI_OriginalImage.img(ROIX(iii),ROIY(iii),ROIZ(iii)); %making copy of original t1 before quantizing
                
                ROI_QuantImage.img(ROIX(iii),ROIY(iii),ROIZ(iii)) = (((ROI_Values(iii) - ROI_Min)*(63))/Range)+1; %quantizing to 64 bins
                ROI_QuantImage.img(ROIX(iii),ROIY(iii),ROIZ(iii)) = floor(ROI_QuantImage.img(ROIX(iii),ROIY(iii),ROIZ(iii)); %make into discrete values
            end
            save_nii(ROI_QuantImage, strcat(QuantFolder,'/',ROI,'/Quant_',ROI,'_',Subjectname,'.nii'));       
            
        end
    end %end of a ROI
end %end of a subject



Collection_OrigImgRanges = [AllSubjOrigIntensityRangeMin(:,1:m) AllSubjOrigIntensityRangeMax(:,1:m)];
Collection_CollewetRanges = [AllSubjImgIntensityIncludeRangeMin(:,1:m) AllSubjImgIntensityIncludeRangeMax(:,1:m)];
Collection_FinalHNIntensities = [ActualROIHNIntensitiesMin(:,1:m) ActualROIHNIntensitiesMax(:,1:m)];
Collection_HNImgIntensityMeans = [Collection_HNImgIntensityMeans(:,1) Collection_HNImgIntensityMeans(:,2) Collection_HNImgIntensityMeans(:,3)];


