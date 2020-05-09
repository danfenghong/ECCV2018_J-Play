function [Normalized_traindata,Normalized_testdata] = featureNormalization(featureTotal,TrainImage_Label,TestImage_Label,len,wid,SubD)

%%Feature level normalization 
        %Normalization for total samples  
        NormalizedFeature=zeros(size(featureTotal));
        for j=1:size(featureTotal,1)
              NormalizedFeature(j,:)=double(mat2gray(featureTotal(j,:)));
        end
        NormalizedFeature3d=hyperConvert3d(NormalizedFeature,len,wid,SubD);
        %Reproduce the normalizaed training and testing samples
        [Normalized_traindata, Normalized_testdata]=GetSampleLabel(NormalizedFeature3d,TrainImage_Label,TestImage_Label);
end