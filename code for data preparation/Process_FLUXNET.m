%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
%--------------------------------------------%
%             Process_FLUXNET                %
%--------------------------------------------%
%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
clc;clear;close all
%% FLUXNET GPP from daily to 8-day and monthly
[~,NAME] = xlsread('.\FLUXNET\site_info_FLUXNET.xlsx','A2:A300');%
station_info = xlsread('.\FLUXNET\site_info_FLUXNET.xlsx');
YEAR = station_info;YEAR=YEAR(:,1:2);

DOM_1=[0,31,59,90,120,151,181,212,243,273,304,334,365];
DOM_2=[0,31,60,91,121,152,182,213,244,274,305,335,366];
m=max(YEAR(:,2))-min(YEAR(:,1))+1;MIN=min(YEAR(:,1));
n=length(NAME);

FIX=ones(46*m,n)*NaN;len=8;% fixed length
MONTH=ones(12*m,n)*NaN;

N=dir(['.\FLUXNET\Global\FLUXSET_DD\','*.csv']);
for j=1:length(NAME)
    j
    mon_LIST=[];fix_LIST=[];day_LIST=[];
    clearvars column column_qc
    [~,VAR] = xlsread(['.\FLUXNET\Global\FLUXSET_DD\FLX_',char(NAME(j)),'_FLUXNET2015_FULLSET_DD.csv']);
    for COL=1:length(VAR)
		if strcmpi(VAR(COL),'GPP_NT_VUT_REF')%'GPP_NT_VUT_REF' gC m-2 d-1
			column=COL;
		end
		if strcmpi(VAR(COL),'NEE_VUT_REF_QC')
			column_qc=COL;
        end
    end
    if exist('column')
        A = xlsread(['.\FLUXNET\Global\FLUXSET_DD\FLX_',char(NAME(j)),'_FLUXNET2015_FULLSET_DD.csv']);
        A(:,1)=floor(A(:,1)./10000);
        for year=YEAR(j,1):YEAR(j,2)
            k=year-YEAR(j,1);
            index=find(A(:,1)==year);
            yearlist=A(index,:);      
            % daily to fixed time :8-day
            for i=1:46
                if i~=46
                    daily_list=yearlist((i-1)*8+1:i*8,column);
                    daily_qc=yearlist((i-1)*8+1:i*8,column_qc);            
                else
                    daily_list=yearlist((i-1)*8+1:end,column);
                    daily_qc=yearlist((i-1)*8+1:end,column_qc);  
                end
                daily_list(daily_list<0)=nan;
                %pre=A(index,69);
                % threshold for ustar 0.4 m/s minimum 0.1 m/s for short vegeation 0.01 m/s%ustar<0.1 | | daily_qc>2
                % daytime 5:00 - 21:00 (8:00 19:00), retain day with 20 entries during daytime
                index=find(daily_qc<0.2 | daily_list==-9999);%fraction between 0-1, indicating percentage of measured and good quality gapfill data
                if length(index)>0.5*len
                    fix_LIST(k*46+i)=NaN;
                else
                    daily_list(index)=[];fix_LIST(k*46+i)=nanmean(daily_list);
                end						
            end
            % daily to monthly; retain month with 20 days (gap longer than 3 days were discarded)
            for mon=1:12
                if mod(year,4)~=0
                    month_list=yearlist(DOM_1(mon)+1:DOM_1(mon+1),column);
                    month_qc=yearlist(DOM_1(mon)+1:DOM_1(mon+1),column_qc);
                else
                    month_list=yearlist(DOM_2(mon)+1:DOM_2(mon+1),column);
                    month_qc=yearlist(DOM_2(mon)+1:DOM_2(mon+1),column_qc);
                end
                month_list(month_list<0)=nan;
                index=find(month_qc<0.2 | month_list==-9999);
                if length(index)>15
                    mon_LIST(k*12+mon)=NaN;
                else
                    month_list(index)=[];mon_LIST(k*12+mon)=mean(month_list);
                end
            end
		
        end
        FIX((YEAR(j,1)-MIN)*46+1:(YEAR(j,2)-MIN+1)*46,j)=fix_LIST;
        MONTH((YEAR(j,1)-MIN)*12+1:(YEAR(j,2)-MIN+1)*12,j)=mon_LIST;
    end
end
clearvars -except FIX MONTH station_info