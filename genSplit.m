%% split participants in half several times and threshold as desired correlation matrices as desired

function y = genSplit(homeDir, roiName, roiDownDim, contextDownDim, contextName, numSplit, testThreshArray)
% 1) homeDir = directory that contains your cleaned time series files
% 2) roiName = names of parcellated regions (taken from roiName Array)
% 3) roiDownDim = the desired spatial resolution for parcellation (from roiDownDimArray)
% 4) contextDownDim = desired spatial resolution for context mask
% 5) contextName = name of the context mask (e.g., 'WB - whole brain')
% 6) numSplit = how many split halves to use (default = 10) 
% 7) testThreshArray = which thresholds to use on the data in each split-half iteration

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
    roiMask1D = sprintf('%s/%s_%imm.1D',maskDir,roiName,roiDownDim);
    contextMask1D = sprintf('%s/%s_%imm.1D', maskDir,contextName, contextDownDim);
    roiCoords = load(roiMask1D);
    contextCoords = load(contextMask1D);
    half1 = zeros(length(contextCoords), length(roiCoords));
    half2 = zeros(length(contextCoords), length(roiCoords));
    
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

function convertToPAJ(SimMat, outname)
%convertToPAJ         Convert to Pajek
%   convertToPAJ(SimMat, outname, arcs);
%   This function writes a Pajek .net file from a MATLAB simalarity matrix

H = size(SimMat,1);
fid = fopen(cat(2,outname,'.net'), 'w');

%%%VERTICES
fprintf(fid, '*vertices %6i \n', H);
for xx = 1:H
    fprintf(fid, '%6i "%6i" \n', [xx xx]);
end

%%%ARCS/EDGES
fprintf(fid, '*edges \n');

for xx = 1:H
    for yy = 1:H
        if SimMat(xx,yy) ~= 0
            fprintf(fid, '%6i %6i %6f \n', [xx yy SimMat(xx,yy)]);
        end
    end
end

fclose(fid);
end

end
