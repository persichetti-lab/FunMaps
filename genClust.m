%in wrapper default is to delete tree file

function f = genClust(infoMapDir, homeDir, roiName, numSplit, roiDownDim, testThreshArray)
            cd(homeDir)
            splitDir = sprintf('%s/splitHalves/%s',homeDir, roiName);
            clustDir = sprintf('%s/clusters',homeDir);
            clustRoiDir = sprintf('%s/clusters/%s',homeDir, roiName);
            if exist(clustDir,"dir")
                cd(clustDir)
            else
                mkdir(clustDir)
                cd(clustDir)
            end

            if exist(clustRoiDir,"dir")
                error("the given cluster directory already exists, please check your inputs")
            else
                mkdir(clustRoiDir)
                clustRoiDir = sprintf('%s/clusters/%s',homeDir, roiName);
            end

            maskDir = sprintf('%s/masks', homeDir);
            roiMask = sprintf('%s/%s_%imm.1D',maskDir, roiName, roiDownDim);

            cd(splitDir)
            coordFile = sprintf('%s/%s_%imm.1D',maskDir, roiName, roiDownDim);
            
            threshData = zeros(numSplit,length(testThreshArray));
            numNets = zeros(numSplit,length(testThreshArray));
            nullThresh = zeros(numSplit,length(testThreshArray));
            nullNets = zeros(numSplit,length(testThreshArray));
            
            for i = 1:numSplit
                for j=1:length(testThreshArray)
                    for h = 1:2
                        inFile = sprintf('%s_iter%i_rThresh_%.3f_half%i.net',roiName,i,testThreshArray(j),h);
                        tempStr = sprintf('%s  --out-name outTree -N 100 --two-level --tree %s %s', infoMapDir, inFile, clustRoiDir);
                        [~, ~] = system(tempStr);
                        %gets ASCII for colon symbol
                        %colon = char(58);
                        %read in tree file
                        fileID = fopen(sprintf('%s/outTree.tree',clustRoiDir),'r');
                        inTab = textscan(fileID,'%d:%d %s %s %s %d',...
                        'TreatAsEmpty',{'NA','na'},'CommentStyle','#');
                        fclose(fileID);
                        inCoords = load(coordFile);
                        outTab = zeros(length(inCoords),4);
                        outTab(:,1:3) = inCoords(:,1:3);
                        for k = 1:length(inTab{1,1})
                            index = inTab{1,6}(k);
                            value = inTab{1,1}(k);
                            outTab(index,4) = value;
                        end
                        writematrix(outTab, sprintf('%s/%s.1D',clustRoiDir, inFile(1:end-4)), FileType="text", Delimiter=' ');
                    end
                end
            end

            cd(clustRoiDir)
            
            maxSize = load(roiMask);
            sizeThresh = .02 * length(maxSize);
            for i = 1:length(testThreshArray)
               adjMat = zeros(length(maxSize));

               for j = 1:numSplit
                    threshVal = testThreshArray(i);
                    inHalf_1 = load(sprintf('%s_iter%i_rThresh_%.3f_half1.1D',roiName,j,threshVal));
                    half1Class = inHalf_1(:,4);
                    inHalf_2 = load(sprintf('%s_iter%i_rThresh_%.3f_half2.1D',roiName,j, threshVal));
                    half2Class = inHalf_2(:,4);
                    
                    maxClass1 = max(half1Class);
                    maxClass2 = max(half2Class);
                
                    tempind1 = randperm(length(half1Class));
                    randClass1 = half1Class(tempind1);
                
                    tempind2 = randperm(length(half2Class));
                    randClass2 = half2Class(tempind2);
                
                
                    agreeCounter = 0;
                    agreeKey = zeros(length(half1Class),1);
                
                    for k=1:maxClass1
                        
                        temp1 = 1.0*(half1Class==k);
                        tempSum1 = sum(temp1);
                        
                        for kk=1:maxClass2
                            
                            temp2 = 1.0*(half2Class==kk);
                            tempSum2 = sum(temp2);
                            
                            tempConj = temp1.*temp2;
                            diceCoeff = 2*sum(tempConj)/(tempSum1+tempSum2);
                            
            
                            % Why > 7?  This is the 2% cutoff of total volume (/388)
                            if ((diceCoeff > 0.5) && (sum(tempConj) > sizeThresh))
                                
                                agreeCounter = agreeCounter + 1;
                                tempind = tempConj>0;
                                agreeKey(tempind) = agreeCounter;
                            end
                            
                            
                        end
                    end
                
                    threshData(j,i) = length(find(agreeKey>0))/length(agreeKey);
                    numNets(j,i) = agreeCounter;
                
                    for k=1:agreeCounter
                    tempind = find(agreeKey==k);
                    
                        for rows = 1:length(tempind)
                            for cols = 1:length(tempind)
                                adjMat(tempind(rows),tempind(cols))=adjMat(tempind(rows),tempind(cols))+1;
                            end
                        end
                    
                    end
                
                
                    agreeCounter = 0;
                    agreeKey = zeros(length(half1Class),1);
                
                    for k=1:maxClass1
                    
                        temp1 = 1.0*(randClass1==k);
                        tempSum1 = sum(temp1);
                    
                        for ii=1:maxClass2
                        
                            temp2 = 1.0*(randClass2==kk);
                            tempSum2 = sum(temp2);
                        
                            tempConj = temp1.*temp2;
                            diceCoeff = 2*sum(tempConj)/(tempSum1+tempSum2);
                        
                            if ((diceCoeff > 0.5) && (sum(tempConj) > sizeThresh))
                            
                                agreeCounter = agreeCounter + 1;
                                tempind = tempConj>0;
                                agreeKey(tempind) = agreeCounter;
                            end
                        
                        
                        end
                    end
                
                    nullThresh(j,i) = length(find(agreeKey>0))/length(agreeKey);
                    nullNets(j,i) = agreeCounter;
                                
                end
            
            adjMat = adjMat/numSplit;
            
            threshMat = 1.0*(adjMat>=0.5);
            tempStr = sprintf('%s_consolidatedNets_%.3f',roiName, threshVal);
            
            convertToPAJ(threshMat,tempStr);
            
            end

            save("agreeTable.mat","threshData","numNets");
            
            %%plot curves

            figure
            hold on
            plot(testThreshArray,mean(threshData));
            plot(testThreshArray,mean(threshData)+std(threshData)/sqrt(numSplit));
            plot(testThreshArray,mean(threshData)-std(threshData)/sqrt(numSplit));
            plot(testThreshArray,mean(nullThresh));
            plot(testThreshArray,mean(nullThresh)+std(nullThresh)/sqrt(numSplit));
            plot(testThreshArray,mean(nullThresh)-std(nullThresh)/sqrt(numSplit));
            
            figure
            hold on
            plot(testThreshArray,mean(numNets));
            plot(testThreshArray,mean(numNets)+std(numNets)/sqrt(numSplit));
            plot(testThreshArray,mean(numNets)-std(numNets)/sqrt(numSplit));
            plot(testThreshArray,mean(nullNets));
            plot(testThreshArray,mean(nullNets)+std(nullNets)/sqrt(numSplit));
            plot(testThreshArray,mean(nullNets)-std(nullNets)/sqrt(numSplit));

            f = "done";

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
