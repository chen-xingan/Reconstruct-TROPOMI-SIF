%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
%--------------------------------------------%
%                RTSIF output                %
%--------------------------------------------%
%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
clc;clear;close all
%% define the geo-reference
latlim = [-90 90];
lonlim = [-180 180];
R = georefcells(latlim,lonlim,[3600 7200],'ColumnsStartFrom','north');
%% make 8-day RTSIF GEOTIFF
year = 2001:2009;
for i = 1:length(year)
    
    OutputPath = ['.\SIF_output\', num2str(year(i))];
    if exist(OutputPath)==0
        mkdir(OutputPath);
    end
    
    SouDir_id = ['.\SIF_input\data_id\' num2str(year(i)),'\'];
    files_id = dir(fullfile(SouDir_id, '*.mat'));
    
    SouDir_sif = ['.\SIF_output\output_csv\' num2str(year(i)),'\'];
    files_sif = dir(fullfile(SouDir_sif, '*.csv'));
    
    for ii = 1:46
        
        time = datetime(year(i),1,1,0,0,0) + days(8*(ii-1));
        filepath_sif = fullfile(SouDir_sif, files_sif(ii).name);
        xx = csvread(filepath_sif);
        filepath_id = fullfile(SouDir_id, files_id(ii).name);
        load(filepath_id)
        data = double(data_id)*nan;
        
        j = 1;
        for m = 1:length(data_id)
            if data_id(m,1)==1
                data(m,1) = xx(j,1);
                j = j+1;   
            end
        end
        clear j m
        char(time)
        RTSIF = reshape(data,3600,7200);
        RTSIF(isnan(RTSIF)) = -9999;
        clear data
        geotiffwrite([OutputPath,'\RTSIF_',char(time),'.tif'],RTSIF,R);
        clear RTSIF
    end
end