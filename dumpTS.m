%% start with original brain timeseries volumes. creeate 1d files and masks 
% for all ROIs and context at the desired spatial resolutions

function y = dumpTS(homeDir, brainHead, roiName, originRes, downRes)
% homeDir = directory that contains your cleaned time series files (i.e., homeDir)
% 2) brainHead = common name of your time series files (e.g., if naming
% convention is 's1.clean_ts.nii, s2.clean_ts.nii, etc.', then brainHead = clean_ts)
% 3) roiName = names of parcellated regions (taken from roiName Array)
% 4) originRes = original spatial resolution of the timeseries data
% 5) downRes = the desired spatial resolution for the parcellation
% ** originRes (e.g. 2mm voxles) will be downsampled to the downRes (e.g.,
% 6mm voxels)

    if exist(homeDir,"dir")
        cd(homeDir)
    else
        error("the given home directory doesn't exist")
    end
    brainDir = sprintf('%s/brains', homeDir);
    maskDir = sprintf('%s/masks', homeDir);
    tsDir = sprintf('%s/timeseries', homeDir);
    roiTsDir = sprintf('%s/timeseries/%s',homeDir, roiName);
    roiMask = sprintf('%s_%imm.nii',roiName,originRes);
    downROImask = extractBefore(roiMask,'_');
    downROImask = sprintf('%s_%imm.nii',downROImask,downRes);
    if ~exist(tsDir,'dir')
        mkdir(tsDir)
    end
    if ~exist(roiTsDir, 'dir')
        mkdir(roiTsDir);
    else
        error("time series directory already exists, please check your inputs")
    end
    
    if ~exist(maskDir, 'dir')
       error("no mask directory exists");
    end
    cd(brainDir)
    brainHeader = sprintf('*%s*',brainHead);
    fnames = dir(brainHeader);

    tempCmd = sprintf('3dmaskdump -mask %s/%s -o %s/%s.1D %s/%s', maskDir, roiMask, maskDir, roiMask(1:end-4), maskDir, roiMask);
 	[~, ~] = system(tempCmd);
    tempCmd = sprintf('3dresample -dxyz %0.1f %0.1f %0.1f -rmode NN -prefix %s/%s -input %s/%s', downRes, downRes, downRes, maskDir, downROImask, maskDir, roiMask);
 	[~, ~] = system(tempCmd);
    tempCmd = sprintf('3dmaskdump -mask %s/%s -o %s/%s.1D %s/%s', maskDir, downROImask, maskDir, downROImask(1:end-4), maskDir, downROImask);
 	[~, ~] = system(tempCmd);
    
    for i = 1:length(fnames)
        tempCmd = sprintf('rm *tsA*');
        [~, ~] = system(tempCmd);
        tempCmd = sprintf('3dmaskdump -mask %s/%s -noijk -o %s/%s_%i.1D %s/%s', maskDir, roiMask, roiTsDir, roiName, i, brainDir, fnames(i).name);
% 	    [returncode, ~] = system(tempCmd);
        [~, ~] = system(tempCmd);
        tempCmd = sprintf('3dcalc -a %s/%s -b %s/%s -datum float -expr ''a*b'' -prefix tsA_1.nii', maskDir, roiMask, brainDir, fnames(i).name);
%        [returncode, ~] = system(tempCmd);
        [~, ~] = system(tempCmd);
        tempCmd = sprintf('3dresample -master %s/%s -rmode Li -prefix tsA_2.nii -input tsA_1.nii', maskDir, downROImask);
% 	    [returncode, ~] = system(tempCmd);
        [~, ~] = system(tempCmd);
        tempCmd = sprintf('3dmaskdump -mask %s/%s -noijk -o %s/%s_%imm_%i.1D tsA_2.nii', maskDir, downROImask,roiTsDir, roiName, int32(downRes), i);
% 	    [returncode, ~] = system(tempCmd);
        [~, ~] = system(tempCmd);
        tempCmd = sprintf('rm *tsA*');
        [~, ~] = system(tempCmd);
%         [returncode, ~] = system(tempCmd);
    end
    y = 'done';
end
