function [A] = ReadEEGLocation(fileName, m, n)
    filePointer = fopen(fileName, "r");
    if filePointer == -1
        error('cannot open file');
    end
    formatSpec = '%f';
    A = fscanf(filePointer, formatSpec, [n m]);
    A = A.';
end
    