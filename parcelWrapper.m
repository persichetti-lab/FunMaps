%%Variables to run the parcellation routine from start to finish
currentFolder = pwd;
addpath(currentFolder);
%home directory for your parcellation data
homeDir = '/misc/data17/persichettias/jiayu/methodsPaper/TDRun2';
%shared formatting text for your brain files
brainHead = 'clean_restTS';
%Name, native, and downsampled resolution(mm) of your target region
targetName = 'WB';
originDim = 2;
targetDownDim = 6;
%Name and downsampled resolution(mm) of your ROI 
roiNameArray = ["cortex", "subcortex"];
roiDownDimArray = [6 3];


%number of split half iterations you are using
numSplit = 10;
%make clear you have to point it to the Infomap directory afni has to be
%added to path
%path to infomap installlation make sure infomap binary is in your OS
infoMapDir = '/misc/data17/persichettias/jiayu/methodsPaper/Infomap/Infomap';

%Threshold arrays to test to determine which is optimal for your data,
%change to suit your needs
testThreshArray = [0.5 0.6 0.7 0.8 0.85 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 0.995];
%selected threshold for use for each of your rois
roiThreshArray = zeros(length(roiNameArray),1);

%Dump your brain time series into 1D files for each of the roi's
for i = 1:length(roiNameArray)
    dumpTS(homeDir, brainHead, roiNameArray(i), originDim, roiDownDimArray(i))
end

%Dump your brain time series into 1D files for target region
dumpTS(homeDir, brainHead, targetName, originDim, targetDownDim)

%Generate split halves for each roi
for i = 1:length(roiNameArray)
    genSplit(homeDir, roiNameArray(i), roiDownDimArray(i), targetDownDim, targetName, numSplit, testThreshArray)
end

%Generate preliminary clusters for each roi
for i = 1:length(roiNameArray)
    genClust(infoMapDir, homeDir, roiNameArray(i), numSplit, roiDownDimArray(i), testThreshArray)
end

%Remap clusters for each ROI back onto the target and combine them
for i = 1:length(roiNameArray)
    promptText = sprintf('input selected threshold for %s:',roiNameArray(i));
    roiThreshArray(i,1) = input(promptText);
end
genParc( homeDir,infoMapDir, roiNameArray, targetName, roiDownDimArray, targetDownDim, originDim, roiThreshArray)

%generate volumes of prototypes and parcels for visualization
genVolume( homeDir, roiNameArray, targetName, originDim, roiThreshArray, roiDownDimArray)