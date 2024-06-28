function f = vol2Surf( parcFile, fillHoles, labelFile, transformMat, workbenchDir, Lsurface, Rsurface, homeDir)
    if isequal(fillholes,"true")
        %upsamples parcellation to 0.5 mm 
        parcName = parcFile(1:end-4);
        tempCmd = sprintf('3dresample -dxyz 0.5 0.5 0.5 -prefix %s/%s_up.nii -input %s/%s', homeDir, parcName, homeDir, parcFile);
        system(tempCmd)
        %aligns to mni space
        tempCmd = sprintf('3dWarp -matvec_out2in %s/%s -NN -prefix %s/%s_mni.nii %s/%s_up.nii', homeDir, transformMat, homeDir, parcName, homeDir, parcName);
        system(tempCmd)
        %fills holes in parcellation
        tempCmd = sprintf("3dcalc -a %s/%s_mni.nii -dicom -expr 'a*step(x)' -prefix %s/l.%s_mni.nii", homeDir, parcName, homeDir, parcName);
        system(tempCmd)
        tempCmd = sprintf("3dcalc -a %s/%s_mni.nii -dicom -expr 'a*step(x)' -prefix %s/l.%s_mni.nii", homeDir, parcName, homeDir, parcName);
        system(tempCmd)
    else

    end
    
    f = "done";
end