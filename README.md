# FunMaps V0.1 - BETA

This is a matlab toolbox to perform functional mapping analyses on resting state fMRI data. Mostly a set of wrapper functions for AFNI and INFOMAP tailored for functional parcellations of resting state data.
FunMaps is designed to streamline the process of conducting resting state functional mapping analyses. The toolbox takes in preprocessed resting state time series data in NIFTI format, converts the brain data into 1-dimensional vectors using AFNI, and conducts a parcellation analysis using the INFOMAP algorithm. Below the parcellation procedure is described in more detail for the whole brain.

## Contributors
- Jiayu Shao 
- Andrew Persichetti 
- Stephen J. Gotts
## TOC
- [FunMaps v0.1 - BETA](#funmaps-v01---beta)
    - [dependencies](#dependencies)
    - [data and directory structure](#data-and-directory-structure)
    - [Installation](#installation)
    - [What is inside this toolbox](#What-is-inside-this-toolbox)
    - [How to make funmaps](#how-to-make-funmaps)

## software dependencies 
- AFNI (added to the path)
  * https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/index.html
- Infomap
  * https://github.com/mapequation/infomap/releases/tag/v2.7.1
  * note this toolbox only supports Infomap v2.0 and beyond as the file structure changed
- MATLAB
  * https://www.mathworks.com/products/matlab.html
- Human Connectome Workbench
## data and directory structure 
- Mask files for the target and roi's you would like to analyze
- Resting state timeseries in .nii format
- DIR STRUCTURE SCHEMATIC
## Installation
1. Clone this repo
2. Check you have all the software dependencies listed in the README file
3. Download Infomap binaries
4. Install afni and add to path
5. Check afni installation with afnicheck.py
7. Add the path to your Infomap binaries to parcelWrapper.m to the **infoMapDir** variable
-include screenshot of where to edit wrapper
## What is inside this toolbox
1. parcelWrapper: a wrapper function that contains all of the variables the average user will need to modify to run the toolbox
2. dumpTS: converts .nii brain timeseries data to 1-dimensional vectors using AFNI's 3dmaskdump command
   * The dumpTS function extracts native resolution brain voxel-wise time series data into a 1-Dimensional (1D) vector for voxels in each ROI mask in native and down sampled resolution. 
4. genSplit: creates group-averaged split half matrices, threshholds said matrices, and converts these into PAJEK format
5. genClust: takes thresholded PAJEK matrices and searches for cluster prototypes using infoMAP 
6. genParc: remaps the your chosen prototype onto your target
## how to make funmaps
1. Create a home directory following the prescribed structure
2. Place your time series files in the brain subdirectory
    * time series files must be in NIFTI format
3. Place your mask files in the mask subdirectory
    * mask files must be in NIFTI format
    * (ADD SOMETHING ABOUT deveining MASKS AND MASK SELECTION)
    * We recommend deveining your masks before using them in your analysis pipeline. Veins can be identified from a standard deviation map of the volume-registered EPI data.
4. Edit parcelWrapper.m to match your specific requirements
    * Define your starting resolution for ROI's and target
    * Define your ending resolution for ROI's and target
    * Define your ROI's and target names
    * ![alt text](https://www.biorxiv.org/content/biorxiv/early/2023/12/18/2023.12.15.571854/F2.large.jpg?width=800&height=600&carousel=1)
    * Define your threshholds for each ROI
    * Define number of split half iterations
5. Run parcelWrapper.m
6. Select thresholds for each ROI after viewing agreement curves and add themn to parcelWrapper.m 
7. Run second part of parcelWrapper.m
8. Undump resultant parcellation files using AFNI

## INTEGRATE WITH THE ABOVE SECTION 
![alt text](https://www.biorxiv.org/content/biorxiv/early/2023/12/18/2023.12.15.571854/F3.large.jpg?width=800&height=600&carousel=1)

First, we made two masks using the Freesurfer cortical and subcortical segmentations a cortical mask that included cerebellar voxels and a subcortical mask that included brain stem voxels. Voxels with poor tSNR (< 10) and prominent blood vessel signal (identified from a standard deviation map of the volume-registered EPI data) were removed from the masks. The cortical mask was then downsampled to 6 mm3-resolution to speed up analysis run times, while the subcortical mask was downsampled to 3 mm3-resolution, because of its smaller starting volume. From there the whole-brain time series data was transformed into a 1D vector, downsampled, and masked for both cortex and subcrotex using AFNI's 3dmaskdump command. 

Next, we randomly split the participants into halves for 10 iterations. For each iteration we calculated the average ROI-to-non-ROI functional connectivity matrices. For each of ten iterations, group-average correlation matrices between the mask and whole-brain voxels were calculated for each half of data (done separately for the cortical and subcortical masks). These matrices were made square by correlating each column of the whole-brain x mask (cortical or subcortical) matrix with themselves. The real-valued correlation matrices were then thresholded into binary. 

Then, we searched for functional network prototypes (i.e., sets of voxels in the group-averaged data with similar patterns of whole brain connectivity) across each mask using the InfoMap clustering algorithm. The thresholded matrices of each half were  clustered using InfoMap to form optimal two-level partitions (i.e., the optimal solution found over one hundred searches). This gives a set of network prototypes that are evaluated for replication. A network prototype was counted as replicating across halves on each iteration if the Dice coefficient [Dice(x,y) = (2*(x∩y))/(x+y)] was ≥0.5, and the volume of the intersection was at least 2% of the size of the cortical or subcortical mask, respectively. The intersection of each network prototype that replicated across the two halves of data was retained for that iteration. After repeating the above steps for each of the ten iterations, one average parcellation of the retained network prototypes was formed, keeping voxels from any prototype that co-occurred in 50% or more of the iterations. Agreement curves were constructed across thresholds, and the threshold with the optimal proportion of coverage and number of detected prototypes was identified in each mask. We found that the split-half agreement and the number of detected prototypes were jointly optimized at the 90% threshold in the cortical mask and at the 85% threshold for the subcortical mask. The subcortex has a lower threshhold due to the comparatively weaker signal to noise ratio in that region. After choosing threshholds for each mask, we consolidated the replicating networks into a unified set of network prototoypes. At this stage of the parcellation, every voxel is not guaranteed to have a network label due to the stringent requirements for replication across iterations described above. 

Finally, we used a best-match criterion to ensure that all voxels were labelled in the end. We used InfoMap was again to search for networks in the unified set of network prototypes. We combined the subcortex and cortex masks and prototypes so that all network prototypes were in the same space. This ensured that when we next ran the best-match procedure, every voxel in the whole brain was assigned a network label. Any voxel could have a label that originated in either the cortical or subcortical mask. We calculated the pattern of connectivity between each network prototype and the whole brain. The pattern of whole-brain functional connectivity for each network prototype was then compared with the pattern of connectivity from each voxel in the whole brain, and we assigned the label of the network prototype with the most similar pattern (Pearson correlation) to that voxel, provided the best match was within a threshold level of similarity (R2 > 0.5). Since the cortical and subcortical voxels were combined before assigning a final network label to each voxel, cortical voxels could, in principle, be labeled as belonging to a subcortical network, and vice versa, according to the best-match criterion.

This procedure can also be done for specfic ROI's instead of across the whole brain. For example we conducted a parcellation analysis of the ATL that used the same parcellation procedure as decribed above. This time a ATL mask was used in place of the whole-brain mask, and ATL cortical/subcortical masks were used in place of their whole-brain counterparts. 



