
function f = genParc( homeDir,infoMapDir, roiNameArray, targetName, roiDownDimArray, targetDownDim, targetOriginDim, roiThreshArray)
% function f = genParc( inParc_1, outParc_1,combine, outName_2, inName_2,...
% wrkDir_1, outDir,wrkDir_2, tsDir,ts_1,ts_2,ts_whole_down,ts_whole, mask1,...
% mask2, target_Down_Mask, target_Mask, outMap)
    cd(homeDir)
    %roiTab = cell(length(roiNameArray));
    targetTsDir = sprintf('%s/timeseries/%s', homeDir, targetName);
    maskDir = sprintf('%s/masks', homeDir);

    for i = 1:length(roiNameArray)
        roiName = roiNameArray(i);
        roiDownDim = roiDownDimArray(i);
        roiThresh = roiThreshArray(i);
        clustRoiDir = sprintf('%s/clusters/%s', homeDir, roiName);
        cd(clustRoiDir);
        tempStr = sprintf('%s  --out-name outTree -N 100 --two-level --tree %s_consolidatedNets_%.3f.net %s', infoMapDir, roiName, roiThresh, clustRoiDir);
        [~, ~] = system(tempStr);
        fileID = fopen('outTree.tree','r');
        inTab = textscan(fileID,'%d:%d %s %s %s %d',...
        'TreatAsEmpty',{'NA','na'},'CommentStyle','#');
        fclose(fileID);
        coordFile = sprintf('%s/%s_%imm.1D',maskDir,roiName,roiDownDim);
        inCoords = load(coordFile);
        outTab = zeros(length(inCoords),4);
        outTab(:,1:3) = inCoords(:,1:3);
        for k = 1:length(inTab{1,1})
            index = inTab{1,6}(k);
            value = inTab{1,1}(k);
            outTab(index,4) = value;
        end
        writematrix(outTab, sprintf('%s_consolidatedNets_%.3f.1D', roiName, roiThresh), FileType="text", Delimiter=' ');
        unTrimmedParc = load(sprintf('%s_consolidatedNets_%.3f.1D', roiName, roiThresh));
        sizeCutoff = length(unTrimmedParc) * .02;
        coords = unTrimmedParc(:,1:3);
        tempClass = unTrimmedParc(:,4);

        newClass = zeros(length(tempClass),1);

        netCounter = 0;

        for ii=1:max(tempClass)
    
            tempind = find(tempClass==ii);
    
            if (length(tempind)>sizeCutoff)
                netCounter = netCounter+1;
        
                newClass(tempind)=netCounter;
            end
    
        end

        outTab = [coords newClass];

        writematrix(outTab, sprintf('%s_consolidatedNets_%.3f.1D', roiName, roiThresh), FileType="text", Delimiter=' ');
    
    
        %roiTab{i,1} = load(sprintf('%s_consolidatedNets_%.3f.1D', roiName, roiThresh));
    end
    
    %load in target masks
    cd(maskDir)
    tempCmd = sprintf('3dmaskdump -mask %s_%imm.nii -o %s_%imm.1D %s_%imm.nii', targetName, targetOriginDim,  targetName, targetOriginDim,  targetName, targetOriginDim);
    [~, ~] = system(tempCmd);
    target_Mask = sprintf('%s_%imm.1D', targetName, targetOriginDim); 
    target_Down_Mask = sprintf('%s_%imm.1D', targetName, targetDownDim);
    target_Down_Coords = load(target_Down_Mask); 
    target_Down_Coords = target_Down_Coords(:,1:3);
    target_Origin_Coords = load(target_Mask);
    target_Origin_Coords = target_Origin_Coords(:,1:3);
    target_Mat = zeros(length(target_Down_Coords),length(target_Origin_Coords));
    cd(targetTsDir)
    roi_Down_Fnames = dir(sprintf('*%imm*.1D',targetDownDim));
    
    roi_Mat = cell(length(roiNameArray),1);
%roi_Fnames = cell(1:length(roiArray));

    for i = 1:length(roiNameArray)
        cd(maskDir)
        roiName = roiNameArray(i);
        roi_Down_Mask = sprintf('%s_%imm.1D', roiName, roiDownDimArray(i));
        roi_Down_Coords = load(roi_Down_Mask);
        roi_Down_Coords = roi_Down_Coords(:,1:3);
        roi_Mat{i,1} = zeros(length(target_Down_Coords), length(roi_Down_Coords));
    
        roiTsDir = sprintf('%s/timeseries/%s', homeDir, roiName);
        cd(roiTsDir);
        for j = 1:length(roi_Down_Fnames)
            target_Down_Ts = load(sprintf('%s/%s_%imm_%i.1D', targetTsDir, targetName, targetDownDim, j));
            roi_TS = load(sprintf('%s/%s_%imm_%i.1D', roiTsDir, roiName, roiDownDimArray(i), j));
            target_Down_Ts = target_Down_Ts';
            roi_TS = roi_TS';
            
            roi_2_TargetDown_Corr = corr(roi_TS,target_Down_Ts)';
            tempind = isnan(roi_2_TargetDown_Corr);
            roi_2_TargetDown_Corr(tempind) = 0;
        
            roi_Mat{i,1} = roi_Mat{i,1} + roi_2_TargetDown_Corr;
        end
        roi_Mat{i,1} = roi_Mat{i,1}/length(roi_Down_Fnames);
    end

    for i = 1:length(roi_Down_Fnames)
        target_Origin_Ts = load(sprintf('%s/%s_%i.1D', targetTsDir, targetName,i));
        target_Down_Ts = load(sprintf('%s/%s_%imm_%i.1D', targetTsDir, targetName, targetDownDim, i));
    
        target_Origin_Ts = target_Origin_Ts';
        target_Down_Ts = target_Down_Ts';
    
        target_2_TargetDown_Corr = corr(target_Origin_Ts,target_Down_Ts)';
        tempind = isnan(target_2_TargetDown_Corr);
        target_2_TargetDown_Corr(tempind) = 0;    
        
        target_Mat = target_Mat + target_2_TargetDown_Corr;
    end

    target_Mat = target_Mat/length(roi_Down_Fnames);

    threshArray = cell(length(roiNameArray));
    roiCombDim = 0;
    for i = 1:length(roiNameArray)
        clustDir = sprintf('%s/clusters/%s', homeDir, roiNameArray(i));

        inThresh = load(sprintf('%s/%s_consolidatedNets_%.3f.1D',clustDir,roiNameArray(i),roiThreshArray(i)));
        threshArray{i,1} = inThresh(:,4);
        roiCombDim = roiCombDim + max(threshArray{i,1});
    end

    prototypes = zeros(length(target_Down_Coords),roiCombDim);
    prototypeCount = 0; 
    for i = 1:length(roiNameArray)
        tempThresh = threshArray{i,1};
        currProtoCount = max(tempThresh);
        for j=1:currProtoCount
            tempind = tempThresh==j;
            tempMat = roi_Mat{i,1};
            tempMean = mean(tempMat(:,tempind),2);
            prototypes(:,(j+prototypeCount)) = tempMean;
        end
        prototypeCount = prototypeCount + currProtoCount;
    end

    newClass = zeros(length(target_Origin_Coords),1);
    for ii=1:length(target_Origin_Coords)
        temp = corr(prototypes,target_Mat(:,ii));
        [y,i]=sort(temp);
        
        if (y(size(prototypes,2))>sqrt(0.5))
            newClass(ii) = i(size(prototypes,2));  
        end
    end

    tempData = [target_Origin_Coords newClass];
    outMap = sprintf('%s/%s_parcellation.1D',homeDir,targetName);
    save(outMap,'tempData','-ASCII');
    f = "done";
 end
