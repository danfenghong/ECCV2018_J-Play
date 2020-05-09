clc;
clear all;
close all;

%% Add path
addpath('functions');
addpath('SVM');
addpath('CCF');


%% First step  : input your data with the size of D*N: D is the dimension and N is the number of samples.
%                e.g. I=double(imread('XX.tif')); or load('XX.mat'); % 2D data (D*N)
%% Second step : data normalization.
%                e.g. I=DataNormlization(I);
%% Third step  : generate training samples (D*N_train), testing samples (D*N_test),
%                training labels (1*N_train) and testing labels (1*N_test).
%% Fourth step : generate label matrix
%                e.g. Y=GeneLableY(TrainLabel,max(TrainLabel)); % l*N_train: l is the number of class

%% Parameter setting
          Maxln=3; % Maximal layers (You can choose what you expect)
          %The following parameters can be set by running 10-kfold cross-validation on training samples
          k=10; % k nearest neighbor
          tao=0.1; % Gaussian kernel parameter
          SubD=20; % Final subspace dimension  
          %Regularization Parameters for the proposed method (You can set up them experimentally or empirically.)
          alfa; % For J-PLAY  (default: 1)
          beta; % For J-PLAY  (default: 0.1)
          gama; % For J-PLAY  (default: 0.1)
          eta; % For AutoRULe (default: 0.1)
          maxiter; % Maximum iterations (default: 1000)
         
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
       [M_CCF,oa_CCF,pa_CCF,ua_CCF,kappa_CCF]=CCF(traindata,TrainLabel,testdata,TestLabel,300);

