function [Data] = classifyData(Y, index)
    m = size(Y);
    Data = ones(m(:,1),1);
    for i = 1:m(:,1)
        if(Y(i,index)<=0)
            Data(i) = 0;
        else
            Data(i) = 1;
        end 
    end
end