function [g, graphCluster,sampledEEG, physDist, sigDist, sigGauss,phyGauss,multi,b,u,a,inD] = runGSP(sensorNum, dimension,sigma1, sigma2, edgeNum, clusterNum, filterN)
% functino: runGSP is used to run graph signal processing 
% sensorNum: number of sensors 
% dimension: 2/3 indicating different dimensions of the signal
% author: Zixuan Zhang, 2018 at University of Southern California
% parameter recommendation: sigma1 0.4 sigma2 0.6, edgeNum 10

    %First step: import data
    sensorLocation = ReadEEGLocation('location_num.txt',sensorNum, dimension);
    eegData = ReadEEGLocation('prominentPeak.txt', 108,sensorNum);
    eegData = eegData.';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %eegData = eegData(2:32, :);
    %sensorLocation = sensorLocation(2:32,:);
    %sensorNum = sensorNum - 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j = 1: sensorNum
        fs = 100;  
        fY = fft(eegData(j,:));
        size(fY);
        n = length(eegData(j,:));
        f = (0:n-1)*(fs/n);
        power = abs(fY).^2/n;
        plot(f,power);
        xlabel('Frequency');
        ylabel('Power');
        hold on ;
    end
    figure;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %coefficient = ones(1,filterN)/filterN;
    %b = 1;
    %eegData = filter(coefficient, b, eegData);
    %eegData = medfilt1(eegData,3);
        %calculate physical and signal distances
        physDist = pdist2(sensorLocation,sensorLocation,'euclidean');
        sigDist = CalculateDistance(eegData);
        %normalization
        physDist = physDist/mean2(physDist);
        sigDist = sigDist/mean2(sigDist);
       
    %Second step: create graph plane
    grasp_start();
    g = grasp_plane_rnd(32);
    g.layout = sensorLocation;
        %coordinates normalization 
        g.layout = (g.layout+100)./25;
        %combine sigDist and phyDist togther
        sigGauss = exp( -sigDist.^ 2 / (2 * sigma1 ^ 2)) - eye(sensorNum);
        phyGauss = exp( -physDist.^ 2 / (2 * sigma2 ^ 2)) - eye(sensorNum);
        multi = sigGauss.*phyGauss;
        %assign the multiplication to the struct 
        g.A = multi;
        %reduce edges 
        g.A = grasp_adjacency_knn(g,edgeNum);
    fprintf('showing initial graph: press enter to continue\n');
    grasp_show_graph(gca,g);
    pause;
    
    %third step: run graph signal analysis
        %calculate laplacian matrix of the graph
        g = grasp_eigendecomposition(g);
        %g.L = grasp_laplacian_standard(g);
        [u,lambda] = eig(full(g.L),full(grasp_degrees(g)));
        g.Finv = u;
        
    %fourth step: do kmean clustering 
    mini = 10000;
    for i = 1:1000
        [a,tempB,inD] = kmeans(u,clusterNum,'MaxIter',500);
        sum = inD(1)+inD(2)+inD(3)+inD(4);
        if (sum<mini)
            display("in loop");
            b = tempB;
        end
        
    end
    
    
        %padding zeros at the end of b
        %b = [b zeros(clusterNum, sensorNum - clusterNum)];
        %retrieve four graph clusters
        graphCluster = (b*g.F).';
        %normalization
        graphCluster(:,1) = graphCluster(:,1)/norm(graphCluster(:,1));
        graphCluster(:,2) = graphCluster(:,2)/norm(graphCluster(:,2));
        graphCluster(:,3) = graphCluster(:,3)/norm(graphCluster(:,3));
        graphCluster(:,4) = graphCluster(:,4)/norm(graphCluster(:,4));
  
    %fifth step: plot data
     
        %first cluster
        grasp_show_graph(gca,g,'node_values',graphCluster(:,1));
        grasp_set_blue_red_colormap(gca);
        title('First EEG Cluster');
        
        %second cluster
        figure;
        grasp_show_graph(gca,g,'node_values',graphCluster(:,2));
        grasp_set_blue_red_colormap(gca);
        title('second EEG Cluster');
        
        %third cluster
        figure;
        grasp_show_graph(gca,g,'node_values',graphCluster(:,3));
        grasp_set_blue_red_colormap(gca);
        title('third EEG Cluster');
        
        %fourth cluster
        figure
        grasp_show_graph(gca,g,'node_values',graphCluster(:,4));
        grasp_set_blue_red_colormap(gca);
        title('fourth EEG Cluster');
    %sixth step: read EEG data
    filePointer = fopen('EEGData.txt','r');
    EEGData = fscanf(filePointer,'%f ', [32 30504]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %EEGData = EEGData(2:32,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %seventh step: sampling and do fourier transformation 
        %fourier transform of signal
        sampledEEG = zeros(sensorNum, floor(size(EEGData,2)/10));
        %store similarity
        sigSim  = zeros(4,floor(size(EEGData,2)/10));
    for i = 1:floor(size(EEGData,2)/10)
        %for each time point 
        %sampledEEG(:,i) = g.F*EEGData(:,i*100);
        %sampledEEG(:,i) = EEGData(:,i*100);
        sampledEEG(:,i) = EEGData(:,i);
        %temp2 = corrcoef(sampledEEG(:,i),graphCluster(:,1));
        temp2 = sampledEEG(:,i).'*graphCluster(:,1);
        sigSim(1,i) = (temp2);
        %temp2 = corrcoef(sampledEEG(:,i),graphCluster(:,2));
        temp2 = sampledEEG(:,i).'*graphCluster(:,2);
        sigSim(2,i) = (temp2);
        %sigSim(2,i) = abs(temp2(2,1));
        %temp2 = corrcoef(sampledEEG(:,i),graphCluster(:,3));
        temp2 = sampledEEG(:,i).'*graphCluster(:,3);
        sigSim(3,i) = (temp2);
        %sigSim(3,i) =  abs(temp2(2,1));
        %temp2 = corrcoef(sampledEEG(:,i),graphCluster(:,4));
        temp2 = sampledEEG(:,i).'*graphCluster(:,4);
        sigSim(4,i) = (temp2);
        %sigSim(4,i) =  abs(temp2(2,1));
      
    end
    %eighth step: plot similarity
    figure;
    subplot(2,2,1);
    %stem(sigSim(1,:),'red');
    plot(sigSim(1,:),'red');
    title('similarity of Clusters');
    ylim([-300 300]);
    scrollplot();
    %hold on
      
    subplot(2,2,2);
    %stem(sigSim(2,:),'green');
    plot(sigSim(2,:),'green');
    title('similarity of 2nd Cluster');
    ylim([-300 300]);
    scrollplot();
    
    subplot(2,2,3);
    %stem(sigSim(3,:),'blue');
    plot(sigSim(3,:),'blue');
    ylim([-300 300]);
    scrollplot();
    title('similarity of 3rd Cluster'); 
     
    subplot(2,2,4);
    %stem(sigSim(4,:),'black');
    plot(sigSim(4,:),'black');
    title('similarity of 4th Cluster');
    ylim([-300 300]);
    scrollplot();
    
    %find major componenet  
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