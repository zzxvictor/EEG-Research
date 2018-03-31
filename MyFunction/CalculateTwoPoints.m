function [Distance] = CalculateTwoPoints(Signal1, Signal2)
length1 = size(Signal1,2);
length2 = size(Signal2,2);
Distance = 0;
if length1 ~= length2
    disp('error!, signal with different lengths!');
    Distance = -1;
    return 
end

for i=1:length1
    Distance = Distance + (Signal1(i) - Signal2(i))^2;
end

end