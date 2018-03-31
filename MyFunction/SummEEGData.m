function [SumSignal] = SummEEGData (EEGDataSet, ChannelNum)
    %summation of data
    for i = 1:ChannelNum
        SumSignal = EEGDataSet(i,:);
    end
    %normalization:
    SumSignal = SumSignal./ChannelNum;
    
end