function [DistanceMatrix] = CalculateDistance(Signal)
[node] = size(Signal,1);
DistanceMatrix = zeros(node,node);
for i = 1:node
    for j = 1:node
        DistanceMatrix(i,j) = CalculateTwoPoints(Signal(i,:), Signal(j,:));
    end
end

end