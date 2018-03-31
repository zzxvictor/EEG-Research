function [GFPSignal, Mean] = CalculateGFP(EEGData)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
[channelNum, dataLength] = size(EEGData);
%   calculating mean
Mean = SummEEGData(EEGData,channelNum);
%calculate Global Field Power

Sum = zeros(1,dataLength);
for i = 1:channelNum
    EEGData(i,:) = (EEGData(i,:) - Mean).^2;
end
for j = 1:channelNum
    Sum = Sum + EEGData(j,:);
end
GFPSignal = sqrt(Sum./channelNum);

end

