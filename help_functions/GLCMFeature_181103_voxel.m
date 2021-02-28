function [ FeatureVector, AvgGLCM ] = GLCMFeature_181103_voxel(QuantizedImg, Mask, GLCMGreyLevel) 

    % Initialization
    GLCMDirectionNum = 13;
    GLCMOffsetX = [0 -1 -1 -1 0 0 0 -1 1 -1 1 -1 1];
    GLCMOffsetY = [1 1 0 -1 1 0 -1 0 0 1 -1 -1 1];
    GLCMOffsetZ = [0 0 0 0 -1 1 -1 -1 -1 -1 -1 -1 -1];           
    FeatureNum = 22;            
        % GLCM Features (Soh, 1999; Haralick, 1973; Clausi 2002)
        % f1. Uniformity / Energy / Angular Second Moment (done)
        % f2. Entropy (done)
        % f3. Dissimilarity (done)
        % f4. Contrast / Inertia (done)
        % f5. Inverse difference    
        % f6. correlation
        % f7. Homogeneity / Inverse difference moment
        % f8. Autocorrelation
        % f9. Cluster Shade
        % f10. Cluster Prominence
        % f11. Maximum probability
        % f12. Sum of Squares
        % f13. Sum Average
        % f14. Sum Variance
        % f15. Sum Entropy
        % f16. Difference variance
        % f17. Difference entropy
        % f18. Information measures of correlation (1)
        % f19. Information measures of correlation (2)
        % f20. Maximal correlation coefficient
        % f21. Inverse difference normalized (INN)
        % f22. Inverse difference moment normalized (IDN)    
    FeatureVector = zeros(FeatureNum, 1);

    % Valid voxel list 
    VoxelIndexes = find(Mask);
    VoxelNum = size(VoxelIndexes, 1);
    [MaskX, MaskY, MaskZ] = ind2sub(size(Mask), VoxelIndexes);

    clear VoxelIndexes; 
    IntensityData = zeros(VoxelNum, 1);
    for i=1:VoxelNum
        IntensityData(i) = QuantizedImg(MaskX(i), MaskY(i), MaskZ(i));
    end

     
    % Save each GLCM to average them later             %Added by LSB 181103  
    AllGLCM = zeros(GLCMGreyLevel,GLCMGreyLevel,GLCMDirectionNum);   %Added by LSB 181103 
        
    % Calculate GLCM for each combination of distance and direction
    for idxDirection = 1:GLCMDirectionNum
        GLCMatrix = zeros(GLCMGreyLevel);
        for i=1:VoxelNum
            VoxelIntensity = QuantizedImg(MaskX(i), MaskY(i), MaskZ(i));
            NeighborX = MaskX(i)+GLCMOffsetX(idxDirection);
            NeighborY = MaskY(i)+GLCMOffsetY(idxDirection);
            NeighborZ = MaskZ(i)+GLCMOffsetZ(idxDirection);
            if NeighborX < 1 || NeighborY < 1 || NeighborZ < 1 || NeighborX > size(Mask, 1) || NeighborY > size(Mask, 2) || NeighborZ > size(Mask, 3)
                continue;
            end
            if Mask(NeighborX, NeighborY, NeighborZ) == 1
                NeighborIntensity = QuantizedImg(NeighborX, NeighborY, NeighborZ);
                GLCMatrix(VoxelIntensity, NeighborIntensity) = GLCMatrix(VoxelIntensity, NeighborIntensity) + 1;
                GLCMatrix(NeighborIntensity, VoxelIntensity) = GLCMatrix(NeighborIntensity, VoxelIntensity) + 1;
            end
        end
         
        % Take original GLCM as input and output normalized GLCM and GLCM
        % Features
        [GLCM_norm, GLCMFeatures] = GLCM_Features3_subin(GLCMatrix,0); %<-181103: features are caluclated for 1 glcm at a time
        FeatureVector(1) = FeatureVector(1) + GLCMFeatures.energ;
        FeatureVector(2) = FeatureVector(2) + GLCMFeatures.entro;
        FeatureVector(3) = FeatureVector(3) + GLCMFeatures.dissi;
        FeatureVector(4) = FeatureVector(4) + GLCMFeatures.contr;
        FeatureVector(5) = FeatureVector(5) + GLCMFeatures.homom;
        FeatureVector(6) = FeatureVector(6) + GLCMFeatures.corrp;
        FeatureVector(7) = FeatureVector(7) + GLCMFeatures.homop;
        FeatureVector(8) = FeatureVector(8) + GLCMFeatures.autoc;
        FeatureVector(9) = FeatureVector(9) + GLCMFeatures.cshad;
        FeatureVector(10) = FeatureVector(10) + GLCMFeatures.cprom;
        FeatureVector(11) = FeatureVector(11) + GLCMFeatures.maxpr;
        FeatureVector(12) = FeatureVector(12) + GLCMFeatures.sosvh;
        FeatureVector(13) = FeatureVector(13) + GLCMFeatures.savgh;
        FeatureVector(14) = FeatureVector(14) + GLCMFeatures.svarh;    
        FeatureVector(15) = FeatureVector(15) + GLCMFeatures.senth;
        FeatureVector(16) = FeatureVector(16) + GLCMFeatures.dvarh;
        FeatureVector(17) = FeatureVector(17) + GLCMFeatures.denth;
        FeatureVector(18) = FeatureVector(18) + GLCMFeatures.inf1h;
        FeatureVector(19) = FeatureVector(19) + GLCMFeatures.inf2h;  
        FeatureVector(20) = FeatureVector(20) + GLCMFeatures.corrm;   
        FeatureVector(21) = FeatureVector(21) + GLCMFeatures.indnc;   
        FeatureVector(22) = FeatureVector(22) + GLCMFeatures.idmnc;  
        
        AllGLCM(:,:,idxDirection) = GLCM_norm;        %Added by LSB 181103 
    end  
    
    FeatureVector = FeatureVector / GLCMDirectionNum;  % <- 181103: Averaging feature values from the 13 glcms (lines 66~91)

    AvgGLCM = mean(AllGLCM, 3); %Added by LSB 181103 
end

