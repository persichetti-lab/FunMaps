function f = genVolume( homeDir, roiNameArray, contextName, originDim, roiThreshArray, roiDownDimArray)
    %generate volume for prototype 
    for i = 1:length(roiNameArray)
        roiClustDir = sprintf('%s/clusters/%s',homeDir,roiNameArray(i));
        inFile = sprintf('%s/%s_prototypeNets_%.3f.1D', roiClustDir,roiNameArray(i),roiThreshArray(i));
        maskFile = sprintf('%s/masks/%s_%imm.nii', homeDir, roiNameArray(i), roiDownDimArray(i));
        outFile = sprintf('%s/%s_prototypeNets_%.3f.nii', homeDir, roiNameArray(i), roiThreshArray(i));
        tempCmd = sprintf('3dUndump -master %s -prefix %s %s', maskFile, outFile, inFile);
        system(tempCmd);
    end
    %generate volume for parcellation
    inFile = sprintf('%s/%s_parcellation.1D', homeDir,contextName);
    maskFile = sprintf('%s/masks/%s_%imm.nii', homeDir,contextName, originDim);
    outFile = sprintf('%s/%s_parcellation.nii', homeDir,contextName);
    tempCmd = sprintf('3dUndump -master %s -prefix %s %s', maskFile, outFile, inFile);
    system(tempCmd);
    %fills in all voxels using nearest neighbor algorithmn 
    tempCmd = sprintf('3dinfill -input %s -prefix %s_fillA.nii -blend MODE', outFile, outFile(1:end-4));
    system(tempCmd);
    tempCmd = sprintf("3dcalc -a %s_fillA.nii -b %s -expr 'a*b' -prefix %s_filled.nii",  outFile(1:end-4), maskFile, outFile(1:end-4));
    system(tempCmd);
    tempCmd = sprintf('rm %s_fillA.nii', outFile(1:end-4));
    system(tempCmd);
    f = "done";
end

