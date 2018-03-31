function [dataSet] = importDataFromFile  (fileName, m, n, isRowVector)

 filePointer = fopen(fileName, "r");
 if filePointer == -1
    error('cannot open file');
 end
 formatSpec = '%f';
 if (isRowVector)
    disp("Hello test")
    dataSet = fscanf(filePointer, formatSpec, [m n]);
 else
    dataSet = fscanf(filePointer, formatSpec, [n m]);
    dataSet = dataSet.' ; 
 end
 fclose(filePointer);
