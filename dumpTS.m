%%function takes in 4 inputs
% 1) directory that contains your cleaned time series files (i.e., homeDir)
% 2) header format of your time series files (optional)
% 3) roiMask in your scanner resolution
% 4) downsampled mask in your target resolution (optional)
% 5) how much you want to resample by (optional)

%start with brain data and 
%%%%make the downsampled mask, include how much to downsample it by
%have downsample mask result be in target ratio instead
%have a comment about needing to be isotropic -or that you would have to
%run your own thing to be nonisotropic
%add an if statement for downsampling
%check to see if people have run this already
%in wrapper make all directories
%check if directory already exists so as not to rerun it
%add option to prefix
%call nifti files brains or something like that
%feed in wb ts files into context mask and undump it
%dump ts in roi of choice and then don't save the og resolution 
function y = dumpTS(homeDir, brainHead, roiName, originRes, downRes)
    if exist(homeDir,"dir")
        cd(homeDir)
    else
        error("the given home directory doesn't exist")
    end
    brainDir = sprintf('%s/brain', homeDir);
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

%%
