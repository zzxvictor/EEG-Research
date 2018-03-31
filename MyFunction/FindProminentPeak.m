function [location] = FindProminentPeak(EEGData,channel, filterN, threshold, choice)
    location = 0;
    %Summation and mormalization
    sumY = SummEEGData(EEGData, channel);
    plot(sumY, 'y');
    %Do moving average
    if choice == 1
        coefficient = ones(1,filterN)/filterN;
        b = 1;
        filtY = filter(coefficient, b, sumY);
    elseif choice == 0
        filtY = medfilt1(sumY,10);
    end
        
    hold on;
    plot(filtY, 'g');
    %Find local Maximum 
    [value, loc, width, pro] = findpeaks(filtY);
    for i = 1: length(loc)
        if pro(i) > threshold
            location = [location loc(i)];
            hold on;
            plot(loc(i), value(i), 'r*');
        end    
    end
    scrollplot();
end