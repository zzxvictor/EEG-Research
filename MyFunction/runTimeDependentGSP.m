function [g,sigSim, graphCluster, fourierSample,centroid, sensorLocation,rawEEG,sampledEEG, phyDist, sigDist] = runTimeDependentGSP()
%% function introduction: run GSP and using Kmeans to find major componants
%of a EEG graph signal
%parameters: sensorNum : number of sensors(Node) used in the analysis
%            dimension : dimensions of the position of nodes (i.e 3/2/1)
%            sigSigma  : sigma for signal distance used in the gaussian
%            kernel 
%            phySigma  : sigma for physical distance used in the gaussian
%            kernel 
%            knnNum    : number of neighbors remains after running KNN
%            killNode  : remove node(s) No.killNode from the dataset
%return values:
%            g         : graph analysis structure, including eignevectors,
%            sigSim    : similarities between graphCluster and signals
%            graphCluster: store clusters
%            fourier inverse matrix, node position informations ...
%            sensorLocation: sensor locations
%            rawEEG    : return the EEG read from the input file
%            sampledEEG: contains the EEG data at GFP peaks
%            phyDist   : physical distances between two nodes
%            sigDist   : signal distances between two nodes 
%
%Author: Zixuan Zhang
%24 March 2018 @ University of Southern California

%% Initialization
close all; clc;
locationFile = 'location_num.txt';
prominantPeakFile = 'prominantPeak.mat';
rawEEGFile = 'rawEEG.mat';
sensorNum = 32;
dimension = 3;
sigSigma = 0.4;
phySigma = 0.6;
knnNum = 10;
killNode = [1];
clusterNum = 4;
numRemains = 5;
%% Import data from the input file 
m = sensorNum; n = dimension; isRow = false;
sensorLocation = importDataFromFile(locationFile, m , n, isRow);
sampledEEG = load(prominantPeakFile);
rawEEG = load (rawEEGFile);
%% Kill nodes
sensorNum = sensorNum - size(killNode,2);
for i = 1: size(killNode,2)
    node = killNode(i);
    %sensorLocation = sensorLocation([1:node-1,node+1:end],:);
    sensorLocation(node-i+1,:) = [];
    sampledEEG.prominantPeadk (node-i+1,:) = [];
    rawEEG.rawEEG(node-i+1,:) = [];
end
%% Calculate distances between nodes
phyDist = pdist2(sensorLocation,sensorLocation,'euclidean');
sigDist = CalculateDistance(sampledEEG.prominantPeadk);
%normalization
phyDist = phyDist/mean2(phyDist);
sigDist = sigDist/mean2(sigDist);
%% Create Graph Singal 
grasp_start();
g = grasp_plane_rnd(sensorNum);
g.layout = sensorLocation;
%coordinates normalization 
g.layout = (g.layout+100)./25;
%combine sigDist and phyDist togther
sigGauss = exp( -sigDist.^ 2 / (2 * sigSigma ^ 2)) - eye(sensorNum);
phyGauss = exp( -phyDist.^ 2 / (2 * phySigma ^ 2)) - eye(sensorNum);
multi = sigGauss.*phyGauss;
%assign the multiplication to the struct 
g.A = multi;
%reduce edges 
g.A = grasp_adjacency_knn(g,knnNum);
%fprintf('showing initial graph: press enter to continue\n');
%grasp_show_graph(gca,g);
%pause;
%% Graph fourier transformation
g = grasp_eigendecomposition(g);
[u,lambda] = eig(full(g.L),full(grasp_degrees(g)));
%get F^-1
g.Finv = u; 
F = u.'* full(grasp_degrees(g));
% or use g.F directly? not sure
%% Get data sample for machine learning
%sampling
fourierSample = zeros(sensorNum, floor(size(rawEEG.rawEEG,2)/10));
for i = 1:floor(size(rawEEG.rawEEG,2)/10)
    fourierSample(:,i) = F*rawEEG.rawEEG(:,i*10);
end
%try starting from 1/2/3

fourierSample = fourierSample(2:numRemains,:).';

%% K-Means clustering 
[a,tempB,inD] = kmeans(fourierSample,clusterNum,'MaxIter',500);
mini = sum(inD);
centroid = tempB;
for i = 1:500
    [a,tempB,inD] = kmeans(fourierSample,clusterNum,'MaxIter',500);
    sumDist = sum(inD);
    if (sumDist<mini)
       centroid = tempB;
       mini = sumDist;
    end
        
end
[~,idx] = sort(centroid(:,1));
centroid = centroid(idx,:);
centroid = centroid.' ; 
centroid = [zeros(1,clusterNum);centroid; zeros(sensorNum - numRemains, clusterNum)];

%% Inverse transformation 
graphCluster = g.Finv*centroid;

%% Normalization
for i = 1: clusterNum
    graphCluster(:,i) = graphCluster(:,i)/norm(graphCluster(:,i));
end
%% Plot data
for i = 1: clusterNum
 %first cluster
 figure 
 grasp_show_graph(gca,g,'node_values',graphCluster(:,i));
 grasp_set_blue_red_colormap(gca);
 title(['No.' num2str(i) ' EEG Cluster']);
end
%% Calculate similarities
sigSim  = zeros(clusterNum,floor(size(rawEEG.rawEEG,2)/10));
for i = 1:floor(size(rawEEG.rawEEG,2)/10)
%for each time point 
    for j = 1:clusterNum
    temp2 = rawEEG.rawEEG(:,i).'*graphCluster(:,j);
    sigSim(j,i) = (temp2);  
    end
end

%% Plot similarities
figure
for i = 1: clusterNum
    subplot(2,2,i);
    plot(sigSim(i,:));
    title(['similarity of Clusters: No. ' num2str(i) ]);
    ylim([-300 300]);
    scrollplot();
end
%% Find major component   
maj = ones(1, size(sigSim,2));
for i = 1: size(maj,2)
    max = abs(sigSim(1,i));
    for j = 2: size(sigSim,1)
        if(max<abs(sigSim(j,i)))
           max = abs(sigSim(j,i));
           maj(i) = j;
        end
    end     
end    
figure;
stem(maj(:));
scrollplot();

end