%%function takes in 4 inputs
% 1) directory that contains your cleaned time series files
% 2) header format of your time series files (optional)
% 3) roiMask in your scanner resolution
% 4) downsampled mask in your context resolution (optional)
% 5) how much you want to resample by (optional)
%add brain connectivity toolbox to path before running said script
function y = genSplit(homeDir, roiName, roiDownDim, contextDownDim, contextName, numSplit, testThreshArray)
    tsDir = sprintf('%s/timeseries',homeDir);
    maskDir = sprintf('%s/masks',homeDir);
    roiTsDir = sprintf('%s/%s',tsDir,roiName);
    contextTsDir = sprintf('%s/%s', tsDir, contextName);
    splitsDir = sprintf('%s/splitHalves',homeDir);
    roiSplitsDir = sprintf('%s/splitHalves/%s', homeDir, roiName);
    
    cd(homeDir)
    if ~exist(tsDir, 'dir')
       error("time series directory doesn't exist, please check your inputs")
    end
    if ~exist(maskDir, 'dir')
       error("masks directory doesn't exist, please check your inputs")
    end
    if ~exist(roiTsDir, 'dir')
       error("roi directory doesn't exist, please check your inputs")
    end
    if ~exist(contextTsDir, 'dir')
       error("context directory doesn't exist, please check your inputs")
    end
    if ~exist(splitsDir, 'dir')
       mkdir(splitsDir)
    end
    cd(splitsDir)
    if ~exist(roiSplitsDir, 'dir')
       mkdir(roiSplitsDir)
    else
       error("roi split-halves directory already exists, please check your inputs")
    end

    cd(roiTsDir)
    fnames = dir(sprintf('*%s_%imm*.1D',roiName,roiDownDim));
%     roiMask = sprintf('%s/%s_%0.1fmm.nii',maskDir,roiName,roiDownDim);
%     contextMask = sprintf('%s/%s_%0.1fmm.nii', maskDir,contextName, contextDownDim);
    roiMask1D = sprintf('%s/%s_%imm.1D',maskDir,roiName,roiDownDim);
    contextMask1D = sprintf('%s/%s_%imm.1D', maskDir,contextName, contextDownDim);
%     tempCmd = sprintf('3dmaskdump -mask %s -o %s %s', contextMask, contextMask1D, contextMask);
% % 	[returncode, ~] = system(tempCmd);
%     [~, ~] = system(tempCmd);
%     tempCmd = sprintf('3dmaskdump -mask %s -o %s %s', roiMask, roiMask1D, roiMask);
% % 	[returncode, ~] = system(tempCmd);
%     [~, ~] = system(tempCmd);   
    roiCoords = load(roiMask1D);
    contextCoords = load(contextMask1D);
    half1 = zeros(length(contextCoords), length(roiCoords));
    half2 = zeros(length(contextCoords), length(roiCoords));
    %check split halving for odd number subjects, include in documentation
    %a line about it
    %have verbose error reporting
    for i = 1:numSplit
        tempind = randperm(length(fnames));
        for j = 1:(length(fnames)/2)
            temp1 = load(sprintf('%s/%s_%imm_%i.1D',contextTsDir,contextName,contextDownDim, tempind(j)));
            temp2 = load(sprintf('%s/%s_%imm_%i.1D',roiTsDir,roiName,roiDownDim, tempind(j)));
           
            temp1 = temp1';
            temp2 = temp2';

            tempcorr = corr(temp2, temp1)';
            tempi = find(isnan(tempcorr));
            tempcorr(tempi) = 0;

            half1 = half1 + tempcorr;
            disp(strcat(num2str(i),'_',num2str(j)));
        end
        half1 = half1/round(length(fnames)/2);
        save(sprintf('%s/%s_iter%i_half1',roiSplitsDir,roiName, i),'half1','-v7.3')

        for k = round((length(fnames)/2) + 1:length(fnames))
            temp1 = load(sprintf('%s/%s_%imm_%i.1D',contextTsDir,contextName,contextDownDim,tempind(k)));
            temp2 = load(sprintf('%s/%s_%imm_%i.1D',roiTsDir,roiName,roiDownDim,tempind(k)));
            
            temp1 = temp1';
            temp2 = temp2';

            tempcorr = corr(temp2, temp1)';
            tempi = find(isnan(tempcorr));
            tempcorr(tempi) = 0;

            half2 = half2 + tempcorr;
            disp(strcat(num2str(i),'_',num2str(k)));
        end
        half2 = half2/round(length(fnames)/2);
        save(sprintf('%s/%s_iter%i_half2',roiSplitsDir,roiName, i),'half2','-v7.3')

    end
    disp("splitting has been completed")
    
    for threshLoop=1:length(testThreshArray)
    
    threshVal = testThreshArray(threshLoop);
    cd(roiSplitsDir)
        for iters=1:numSplit
        
            fprintf('Thresh=%.3f; Iter=%d',threshVal,iters);
            
            tempStruct1 = load(sprintf('%s_iter%i_half1.mat', roiName,iters));
            tempStruct2 = load(sprintf('%s_iter%i_half2.mat', roiName,iters));
            
            half1_mat = corr(tempStruct1.half1) ;
            half2_mat = corr(tempStruct2.half2) ;
            
            for i=1:length(half1_mat)
                half1_mat(i,i) = 0;
                half2_mat(i,i) = 0;
            end
            
            clear tempStruct*
            
            temp1 = squareform(half1_mat);
            [y,i] = sort(temp1);
            rThresh1 = y(round(threshVal*length(y)));
            
            rTopPercent = 1.0*(half1_mat>rThresh1);
            tempStr = sprintf('%s/%s_iter%i_rThresh_%.3f_half1',roiSplitsDir,roiName,iters,threshVal);
            convertToPAJ(rTopPercent,tempStr);
            
            
            temp2 = squareform(half2_mat);
            [y,i] = sort(temp2);
            rThresh2 = y(round(threshVal*length(y)));
            
            rTopPercent = 1.0*(half2_mat>rThresh2);
            tempStr = sprintf('%s/%s_iter%i_rThresh_%.3f_half2',roiSplitsDir,roiName,iters,threshVal);
            convertToPAJ(rTopPercent,tempStr);

      
        end
    
    end
    disp("thresholding has been achieved")
    y = "done";
end
