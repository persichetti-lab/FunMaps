# FunMaps V0.1 - BETA    <img src="https://github.com/persichetti-lab/images/blob/main/funmaps_logo_dots3.png" width="300" height="270" align="right">


FunMaps is a matlab-based toolbox developed to perform flexible and data-driven functional parcellations of the brain to derive network maps with relatively small resting-state fMRI datasets collected in individual labs. FunMaps is a set of functions that are controlled through a wrapper script. Below, you will find a list of the software needed to run FunMaps and how to download them, and detailed instructions for using the toolbox. Please download this paper for more details about FunMaps and a demonstration of how to use it: xxx. A rs-fMRI dataset used in the paper is available on the OSF website: XXX. Please download the data and have **fun** making brain **maps!**

## Contributors
- Andrew Persichetti
- Jiayu Shao 
- Stephen J. Gotts
## TOC
- [FunMaps v0.1 - BETA](#funmaps-v01---beta)
    - [software dependencies](#dependencies)
    - [Installation](#installation)
    - [How to make funmaps](#how-to-make-funmaps)

## software dependencies 
- AFNI (added to the path)
  * https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/index.html
- Infomap
  * https://github.com/mapequation/infomap/releases/tag/v2.7.1
  * note this toolbox only supports Infomap v2.0 and beyond as the file structure changed
  * more information about the Infomap dependency can be found here:
  * https://www.mapequation.org/infomap/
- MATLAB
  * https://www.mathworks.com/products/matlab.html
- Connectome Workbench
  * https://www.humanconnectome.org/software/connectome-workbench
## Installation
1. Clone this repository
2. Check you have all the software dependencies listed in the README file (above)
    * Download Infomap binaries
    * Install afni and add to path
    * Check afni installation with afnicheck.py
    * Add the path to your Infomap binaries to parcelWrapper.m to the **infoMapDir** variable
## how to make funmaps
*** Below is a detailed description of each step in the toolbox. Users will modify variables in the wrapper (parcelWrapper.m) that will be passed to the serial set of functions described below.**
1. **Data and materials needed to run FunMaps**
* Before running FunMaps, you will need to make an experiment directory with two subdirectories: One called “brains” that contains the cleaned rs-fMRI timeseries data for all participants in the study and another directory called “masks” that contains two types of masks in the native resolution of the timeseries data. All data needs to be in NiFTI format and a standard volumetric space (the example funmaps data are in Talairach space).
* The first type of mask is the region of interest (ROI) mask, which consists of all the voxels within the brain region(s) that you want to parcellate.
  * The ROI mask can range in size from a small region of study (e.g., the anterior portion of the temporal lobes – Persichetti et al., 2021) to the whole brain (Persichetti et al., 2023). If your ROI includes both cortical and subcortical voxels, then we recommend separating the ROI mask into cortical and subcortical masks. The pipeline can handle multiple ROI masks at a time, if necessary. The cortical and subcortical ROI’s will be parcellated separately and then combined at a later step in the pipeline.
* The second type of mask is the target mask, which will often be a whole-brain mask, but you can also decide to exclude voxels that are in your ROI mask – e.g., if you have a small ROI mask and you do not want to use voxel-to-voxel correlations from within the ROI (see Persichetti et al., 2021 for an example of this approach).
* Additionally, we recommend removing voxels with poor temporal signal-to-noise ratio (tSNR) and prominent blood vessel signal from both types of masks. The toolbox includes an auxiliary function (cleanMask.m) that removes from each mask voxels with poor tSNR and prominent blood vessel signals (identified from a standard deviation map of the volume registered EPI data – (Kalcher et al., 2015).

2. **dumpTS.m - extracts voxelwise timeseries data from each mask**
* The dumpTS function downsamples the data and masks to a lower spatial resolution, then extracts voxelwise time series data from the rs-fMRI volumes and saves it into text files. Downsampling the data before starting the parcellation saves lots of time without sacrificing performance of the parcellation routine.
  * For example, in Persichetti et al. (2023), we started with 2 mm<sup>3</sup> resolution voxels, then downsampled the whole-brain target mask and the cortical ROI mask to 6 mm3 resolution, while the subcortical ROI mask was downsampled to 3 mm<sup>3</sup> resolution because of its smaller starting volume. Users can choose to omit or modify the degree of down sampling to match the needs of their data, using the variables **roiDownDimArray** and **targetDownDim** in the wrapper.
  * Next, to lower data storage requirements, the ROI and target masks are used to extract voxelwise time series data from the rs-fMRI volumes and save it into 1D vectors. Thus, the output of this step will be new downsampled masks in the masks directory (if downsampling is indicated in the wrapper, highly recommended) and a new subdirectory, named timeseries, that contains 1D text files of voxelwise rs-fMRI timeseries data from each participant and each mask in the desired spatial resolution.
  *       
3. **genSplits.m - Creates random split-half datasets**
* The genSplits function randomly splits the participant data into two equal groups, calculates the voxelwise correlation matrices between each ROI mask and the target mask data (done separately for each ROI mask) for each participant, then combines the correlation matrices from all participants in each split-half group to create a group-averaged correlation matrix in each half of the data.
  * This process is repeated over several iterations (we recommend ten split-half iterations as a good tradeoff between finding stability and minimizing computation time), each time randomly splitting the group of participants into two equal sized groups. 
* The group-averaged ROI x target matrix from each half and each iteration is then made square by calculating the column-wise correlation, yielding an ROI-voxels x ROI-voxels matrix that reflects the similarity of connectivity patterns from ROI voxels to the voxels in the target mask.
* The final step formats the matrices to be compatible with the InfoMap algorithm that will be used in the next step of the pipeline. Specifically, the real-valued correlation matrices are thresholded into binary (0 or 1) undirected matrices at a range of threshold values representing the top percentages of connections and then converted to the Pajek file format. 
* *** In the examples used in this paper, we used the following thresholds: 50, 60, 70, 80, 85, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, and 99.5% (indicated in the wrapper by the variable testThreshArray as proportions – e.g., 0.5, 0.6, 0.7, etc.). We used this wide range of thresholds to give the reader a sense of the effect thresholding has on the parcellation routine. However, we recommend that users constrain this range to something closer to steps of 3% between 80-95% to save time, since we have consistently found that ideal thresholds to be 85% for subcortical masks and 90% for cortical masks.

4. **genClusters.m - Creates network prototypes**
* The genClusters function searches for network prototypes in the thresholded matrices of each split-half group using the InfoMap algorithm to form optimal two-level partitions (FunMaps searches for the optimal solution over 100 searches on each split-half iteration). 
* Prototypes found in each half of the data are required to replicate across halves in each iteration. Specifically, in each iteration, a prototype is counted as replicating if the Dice coefficient [(2|X ⋂ Y|∕(|X|+|Y|)] is greater than 0.5 and the volume of the intersecting voxels for the prototype is at least 2% of the ROI mask size. Network prototypes that meet these criteria are retained in each iteration. 
* After repeating the above steps for all iterations, an agreement matrix is created, such that each cell reflects the proportion of iterations in which two voxels were part of the same network prototype that agreed across the split halves. Thus, if two voxels were part of a prototype that was present in eight out of ten iterations, then that cell of the matrix would get a value of 0.8 to indicate that it was present in 80% of the iterations. The matrix is then thresholded such that two voxels are required to be part of the same prototype in at least 50% of the iterations. 
  * *** It is important to note that at this step the matrix has lost the prototype labels and is simply a binarized matrix reflecting generic network prototype membership across voxels. The voxels will be relabeled in the next step of the toolbox (genParcels).

* The above process is completed for all thresholds indicated in the prior step and agreement curves for each ROI mask are constructed across thresholds.
* The agreement curves can be evaluated to find the threshold with the desired split-half agreement in brain coverage (i.e., the percentage of voxels assigned to a prototype at each threshold) and the total number of prototypes retained. 
* **At this point, the program pauses and asks the user to enter on the command line which threshold should be used for each ROI mask.** Once the user enters the desired threshold for each ROI mask on the command line, the program resumes the parcellation for those thresholds only. In the example presented in the paper, we chose 90% for the cortical mask and 85% as the threshold for the subcortical mask because we have consistently found these to be ideal thresholds for these types of masks.
  * However, **it is critical that users evaluate the agreement curves and decide for themselves how they want to proceed**, since the optimal threshold will be dependent on features of each dataset, such as sample size and tSNR. 
* In addition to evaluating the agreement curves, users should run the auxiliary function called **undumpPrototypes.m** that is provided in the FunMaps toolbox to map the prototypes (in the downsampled space) at a given threshold onto the brain volume. The volumetric prototypes are saved in a text file named with the ROI mask and the threshold value (e.g., cortex_prototypeNets_90.1D) and as a NIfTI formatted brain volume with the same name. The resultant brain map will give the user a good idea about whether the parcellation solution at the selected threshold is reasonable or not.

5. **genParcels.m - Assigns network labels in the original volume space**
* The genParcels function assigns final network labels to each voxel in the original spatial resolution. To save time, this step is completed entirely on vectors in the 1D text file format. The network labels will be mapped onto a brain volume in the next step. 
* First, the program iterates through the timeseries data for each ROI mask in each participant and makes a correlation matrix that reflects the pattern of functional connectivity between each voxel in the ROI mask with all voxels in the target mask. These correlation matrices are then averaged across participants in the downsampled space. 
* These voxelwise patterns of connectivity are then assigned prototype labels, and voxels from the same prototype are averaged together to get an average pattern of brain connectivity for each prototype. The average pattern of brain connectivity for each prototype from all ROI masks is then correlated with the pattern from every voxel across the brain in the original spatial resolution of the data. Thus, a prototype that originated in the subcortical ROI mask can include network voxels in the cortex, and vice versa. 
* In a winner-takes-all approach, each voxel is given the label of the network prototype that explains the most variance in that voxel. However, as a final quality assurance step, the winning network prototype must explain at least 50% of the variance (i.e., R2 > 0.5) in the functional connectivity pattern of a given voxel for it to get a final network label, otherwise the voxel does not get a label at this step. We do this to avoid giving “noise voxels” (e.g., voxels with prominent blood vessel signal) a network label. 
* At the end of this step, the final network labels are saved in a 1D text file along with the coordinates of all brain voxels in the original spatial resolution of the data. 
  * In the next and final step of the program, each voxel will be given a network label while remapping the data into the brain volume.

6. **genVolume.m - Create a final volume that includes all networks**
* The genVolume function maps the network labels assigned to each voxel in the original spatial resolution of the data onto the brain volume in the NIfTI (.nii) file format. 
* At this step, every voxel that was not assigned a network label in the previous step is given a label using nearest-neighbor interpolation. 
* **The map of brain-wide functional networks provided by FunMaps is now complete** and the final volumetric rendering of the whole-brain network parcellation can be easily visualized.
* The toolbox also includes an auxiliary function called **vol2surf.m** that uses the HCP Connectome Workbench (Marcus et al., 2013) to create a surface rendering of the cortical networks.

