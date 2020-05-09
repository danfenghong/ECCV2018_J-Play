clc;
clear all;
close all;

%% Add path
addpath('dataset');
addpath('functions');
addpath('SVM');
addpath('CCF');

%% Load data
dataset='Houston';
switch dataset
    case 'IndinePine'
          %Get data and labels
          I=double(imread('19920612_AVIRIS_IndianPine_Site3.tif'));
          [len,wid,dim]=size(I);
          TrainImage_Label=double(imread('IndianTR123_temp123.tif'));
          TestImage_Label=double(imread('IndianTE123_temp123.tif'));
          %Generate the training/testing samples and labels : D*N_train and D*N_test
          [TrainSample, TestSample, TrainLabel, TestLabel]=GetSampleLabel(I,TrainImage_Label,TestImage_Label);
          TrainPlusTest=[TrainSample,TestSample];
          %Parameter setting
          Maxln=8; % Maximal layers (You can choose what you expect)
          %The following parameters can be set by running 10-kfold cross-validation on training samples
          k=10; % k nearest neighbor
          tao=0.1; % Gaussian kernel parameter  
          SubD=20; % Final subspace dimension
          alfa=1;
          beta=10.^[-2,-1,0,0,0,-1,0,-1];
          gama=10.^[0,-1,0,0,0,-1,-1,-1];
          eta=10.^[-1,0,-1,-1,-2,-2,-4,-3]; % Eta for 8 layers of AutoRULe 
          maxiter=1000;    
    case 'Houston'
         %Get data and labels
         I=double(imread('2013_IEEE_GRSS_DF_Contest_CASI.tif'));
         [len,wid,dim]=size(I);
         TrainImage_Label=double(imread('2013_IEEE_GRSS_DF_Contest_Samples_TR.tif'));
         TestImage_Label=double(imread('2013_IEEE_GRSS_DF_Contest_Samples_VA.tif'));
         [TrainSample, TestSample, TrainLabel, TestLabel]=GetSampleLabel(I,TrainImage_Label,TestImage_Label);
         TrainPlusTest=[TrainSample,TestSample];
         %Parameter setting
         %The following parameters can be set by running 10-kfold cross-validation on training samples
         k=10; % k nearest neighbor
         tao=0.1; % Gaussian kernel parameter
         eta=10.^[0,-1,-1,0,-1,-1,0]; % Eta for 7 layers of AutoRULe         
         SubD=30; % Final subspace dimension
         alfa=1;
         beta=10.^[-1,-1,-1,0,0,-2,-1];
         gama=10.^[0,-1,-1,-1,0,-1,0];
         maxiter=1000;
end

%% Data normalization
%Data normalization: aganist scaling factors to some extents  
%                    contribute to computer adjacency matrix

         %Total data normalization
         I2d=hyperConvert2d(I); % Convert 3D image cube to 2D: D*N (D: dimension, N: the number of samples)
         I2d=DataNormlization(I2d); % Normalization
         %Train and test samples normalization
         TrainPlusTest=DataNormlization(TrainPlusTest); % D*N 
         TrainSample=TrainPlusTest(:,1:length(TrainLabel)); % D*N_train
         TestSample=TrainPlusTest(:,length(TrainLabel)+1:end); % D*N_test
         %Generate label matrix
         Y=GeneLableY(TrainLabel,max(TrainLabel)); % l*N_train: l is the number of class
         
%% Construct adjacency matrix and Laplacian matrix
        [G,L]=creatLap(TrainSample,k,tao); % Return adjacency matrix G and Laplacian matrix L
%% Evenly give the middle subspace dimensions
        layer=3; % Layers: you can tune it accordingly and here we just give an example.
        d=generatePath(dim,layer,SubD); % Generate the dimension sequence for intermediate subspaces
%% Run JPLAY to learn projections on train samples
        theta=JPLAY(TrainSample,Y,G,L,k,d,tao,alfa,beta(layer),gama(layer),maxiter,eta(layer));
%% Project the test samples to the learned subspaces
        featureTRTE=TrainPlusTest;
        featureTotal=I2d;
        for i=1:length(d)
            featureTRTE=theta{1,i}*featureTRTE;
            featureTotal=theta{1,i}*featureTotal;
        end
%% Performance evaluation via classification using the nearest neighbor (NN)
        traindata=featureTRTE(:,1:length(TrainLabel));
        testdata=featureTRTE(:,length(TrainLabel)+1:end);
        mdl=ClassificationKNN.fit(traindata',TrainLabel','NumNeighbors',1,'distance','euclidean'); 
        characterClass=predict(mdl,testdata');  
        OA=sum(characterClass==TestLabel')/length(TestLabel);
% Before training a classification model, the feature-based normalization is usually suggested.     
       [traindata,testdata] = featureNormalization(featureTotal,TrainImage_Label,TestImage_Label,len,wid,SubD);
%% Performance evaluation via classification using Kernel SVM
       [M_SVM,oa_SVM,pa_SVM,ua_SVM,kappa_SVM]=KSVM(traindata,TrainLabel,testdata,TestLabel);
%% Performance evaluation via classification using CCF
       rng(1);
       [M_CCF,oa_CCF,pa_CCF,ua_CCF,kappa_CCF]=CCF(traindata,TrainLabel,testdata,TestLabel,300);

