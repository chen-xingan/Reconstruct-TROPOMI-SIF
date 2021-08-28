%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
%--------------------------------------------%
%           InputData  Preparation           %
%--------------------------------------------%
%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
clc;clear;close all
%% make 8-day inputdata for XGBoost model
year = 2001:2019;
for i = 1:length(year)
    
    SouDir_MCD43C4 = ['.\MODIS\MCD43C4\' num2str(year(i)),'\'];
    files_MCD43C4 = dir(fullfile(SouDir_MCD43C4, '*.hdf'));
    
    SouDir_MYD11 = ['.\MODIS\MYD11C1\' num2str(year(i)),'\'];
    files_MYD11 = dir(fullfile(SouDir_MYD11, '*.hdf'));
    
    [PAR_CERES, ~] = geotiffread(['.\CERES_Data\PAR\PAR_',num2str(year(i)),'.tif']);
    
    files_MCD12 = dir(fullfile('.\MODIS\MCD12C1\', '*.hdf'));
    
    time = datetime(year(i),1,1,0,0,0) + days([0 : length(files_MCD43C4)-1]);
    
    % MCD12
    data_IGBP = double(hdfread(['.\MODIS\MCD12C1\',files_MCD12(year(i)-2001+1).name], 'Majority_Land_Cover_Type_1'));
    data_IGBP(data_IGBP==0 | data_IGBP==15 | data_IGBP==16) = nan;
    
    for j = 1:46
        
        if j < 46
            cal_len = 8;
        else
             cal_len = length(files_MCD43C4)-45*8;
        end
        
        % MYD11
        for num = 1:cal_len
            ii = (j-1) * 8+ num;
            filepath_MYD11 = fullfile(SouDir_MYD11, files_MYD11(ii).name);
            data_LST = double(hdfread(filepath_MYD11, 'LST_Day_CMG'));
            data_LST(data_LST < 7500 | data_LST > 65535) = nan;
            data_LST_8day(:,:,num) = data_LST * 0.02;
            clear data_LST
        end
        data_LST_8day_mean = nanmean(data_LST_8day, 3);
        clear data_LST_8day

        % MCD43
        for num = 1:cal_len
            ii = (j-1) * 8+ num;
            filepath_MCD43C4 = fullfile(SouDir_MCD43C4, files_MCD43C4(ii).name);
            data_Quality = double(hdfread(filepath_MCD43C4, 'BRDF_Quality'));
            data_Quality_8day(:,:,num) = data_Quality;
            data_Band1 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band1'));
            data_Band2 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band2'));
            data_Band3 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band3'));
            data_Band4 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band4'));
            data_Band5 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band5'));
            data_Band6 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band6'));
            data_Band7 = double(hdfread(filepath_MCD43C4, 'Nadir_Reflectance_Band7'));
            for band_num = 1:7
                eval(['data_Band',num2str(band_num),'(data_Band',num2str(band_num),' < 0 | data_Band',num2str(band_num),' >32766) = nan;'])
                eval(['data_Band',num2str(band_num),'_8day(:,:,num) = data_Band',num2str(band_num),' * 0.001;'])
            end
        end
        for band_num = 1:7
            eval(['data_Band',num2str(band_num),'_8day(data_Quality_8day > 5) = nan;'])
            eval(['data_Band',num2str(band_num),'_8day_mean = nanmean(data_Band',num2str(band_num),'_8day, 3);']);
        end
        clear data_Quality data_Band1 data_Band2 data_Band3 data_Band4 data_Band5 data_Band6 data_Band7    
        clear data_Band1_8day data_Band2_8day data_Band3_8day data_Band4_8day data_Band5_8day data_Band6_8day data_Band7_8day data_Quality_8day 

        % PAR_CERES
        for num = 1:cal_len
            ii = (j-1) * 8+ num;
            data_PAR = PAR_CERES(:,:,ii);
            data_PAR_8day_CERES(:,:,num) = data_PAR;
            clear data_PAR
        end
        data_PAR_8day_mean_CERES = nanmean(data_PAR_8day_CERES, 3);
        clear data_PAR_8day_CERES
        F = griddedInterpolant(data_PAR_8day_mean_CERES);
        [sx,sy] = size(data_PAR_8day_mean_CERES);
        xq = (0.01:1/20:sx-0.01)';
        yq = (0.01:1/20:sy-0.01)';
        data_PAR_8day_mean_CERES = (F({xq,yq}));
        clear F xq yq sx sy

        data_table = [data_Band1_8day_mean(:),data_Band2_8day_mean(:),data_Band3_8day_mean(:),...
            data_Band4_8day_mean(:),data_Band5_8day_mean(:),data_Band6_8day_mean(:),data_Band7_8day_mean(:),...
            data_LST_8day_mean(:),data_IGBP(:),data_PAR_8day_mean_CERES(:)];
        data_table_new = data_table(all(~isnan(data_table),2),:);
        
        data_id = all(~isnan(data_table),2);
        DesDir_id = ['.\SIF_input\data_id\', num2str(year(i))];
        if exist(DesDir_id)==0
            mkdir(DesDir_id);
        end
        save([DesDir_id,'\',char(time(ii) - days(num-1)),'.mat'],'data_id')

        clear data_table
        clear data_Band1_8day_mean data_Band2_8day_mean data_Band3_8day_mean
        clear data_Band4_8day_mean data_Band5_8day_mean data_Band6_8day_mean
        clear data_Band7_8day_mean data_LST_8day_mean 
        clear data_PAR_8day_mean_CERES 

        % save to CSV
        title={'Red','NIR','Blue','Green','IR1','IR2','IR3','LST','IGBP','PAR_CERES'};
        result_table = table(data_table_new(:,1),data_table_new(:,2),data_table_new(:,3),...
            data_table_new(:,4),data_table_new(:,5),data_table_new(:,6),data_table_new(:,7),...
            data_table_new(:,8),data_table_new(:,9),data_table_new(:,10),...
            'VariableNames', title);
        clear data_table_new

        Name_file = [char(time(ii) - days(num-1)),'.csv']
        
        DesDir_csv = ['.\SIF_input\', num2str(year(i))];
        if exist(DesDir_csv)==0
            mkdir(DesDir_csv);
        end
        writetable(result_table, [DesDir_csv,'\',Name_file]);
        clear result_table 
    end
    clear SouDir_MCD43C4 SouDir_MYD11 files_MCD43C4 files_MYD11
    clear PAR_CERES data_IGBP
end