% this script will ...
% load the raw data from US-UMB
% Filter the data to:
%   1. Remove non-summer data
%   2. Remove night time data
%   3. Remove data from day of and day after precipitation event

% written by Trevor Keenan (December 2012)
# for:
# Keenan, T. F. et al. Increase in forest water-use efficiency as atmospheric carbon dioxide concentrations rise. 
# Nature 499, 324–327 (2013).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. load the raw data csv file
clear all
data=importdata('./dataUMB_forWeiCalc.csv');

% clean up
rawData=data.data;
clear data


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. define the structure of the data file
col.year=1;
col.doy=2;
col.hour=3;
col.ppfd=4;     % units: umol m-2 s-1
col.LE=5;       % units: W m-2
col.GPP=6;      % units: umol m-2 s-1
col.VPD=7;      % units: hPa
col.precip=8;   % units: mm h-1

% define the start and end of summer
seasonStart=5*30;   % will delete data before this doy
seasonEnd=8*30;     % will delete data after this doy


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. loop through each year, apply filtering, unit conversions and calculate Wei

% identify the number of years in the data
yearID=unique(rawData(:,col.year));

% loop through each year and apply the same filtering
for i=1:length(yearID)
    
    % find the location of the data for the current year
    indX=rawData(:,col.year)==yearID(i);
    
    % extract the current years data
    currentYearData=rawData(indX,:);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % filter currentYearData to remove data points we're not interested in
    % Those are:
    % 1. Night time data
    % 2. Non-summer data
    % 3. Bad data (negative GPP, LE or VPD)
    % 4. Gap-filled data
    
    % remove off season data
    IndX2=(currentYearData(:,col.doy)<seasonStart | currentYearData(:,col.doy)>seasonEnd);
    currentYearData(IndX2,4:end)=NaN;
    
    % remove night-time data
    IndX=currentYearData(:,col.ppfd)<250;
    currentYearData(IndX,4:end)=NaN;
    
    % find bad LE values
    IndX=(currentYearData(:,col.LE)<0);
    currentYearData(IndX,4:end)=NaN;
    
    % find bad GPP values
    IndX=(currentYearData(:,col.GPP)<=0);
    currentYearData(IndX,4:end)=NaN;
    
    % find bad VPD values
    IndX=(currentYearData(:,col.VPD)<0.5);
    currentYearData(IndX,4:end)=NaN;
    
    % remove all data from the day of rain
    % get positive precip hours
    IndX=(currentYearData(:,col.precip)>0);
    % find the days on which rain events occur
    uniqueDays=unique(currentYearData(IndX,col.doy));
    % find the index of hours for these days in the year
    IndX=ismember(currentYearData(:,col.doy),uniqueDays);
    % remove the data for rain days
    currentYearData(IndX,4:end)=NaN;
    
    % remove all data from the day AFTER the day of rain
    % get positive precip hours
    IndX=(currentYearData(:,col.precip)>0);
    % find the day after days with rain events
    uniqueDays=unique(currentYearData(IndX,col.doy))+1;
    % find the index of hours for these days in the year
    IndX=ismember(currentYearData(:,col.doy),uniqueDays);
    % remove the data for rain days
    currentYearData(IndX,4:end)=NaN;
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply unit conversions to GPP and LE
    
    tmpGPP=currentYearData(:,col.GPP);    % umol m-2 s-1.
    tmpVPD=currentYearData(:,col.VPD);    % hPA
    tmpLE=currentYearData(:,col.LE);      % W m-2
    
    %%%%%%%%% convert GPP from umol m-2 s-1 to gC m-2 hr-1
    tmpGPPgc=tmpGPP*0.0432;
    % Conversion is: gC/m2/hhr = umol/m2/s * (3600 sec/hr) * (12.011 gc/mol) * (10^-6  mol/umol) = umol/m2/s * 0.0432
    
    %%%%%%%%% convert LE from W m-2 to kg H20 m-2 hr-1 (1 Kg/m^2 is equivalent to 1 mm of depth.)
    tmpLE=(60*60)*tmpLE/2454000;
    % W m-2 = J s-1
    % kg m-2 s-1 = J s-1/2454000 (= J s-1/latent heat of vaporization [2.5*10^6 J kg-1])
    % kg m-2 hr-1 = kg m-2 s-1*(60*60)
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate Intrinsic Water Use Efficiency (Wei) from GPP*VPD/LE
    % units are in gC/kgH20.hPa
    
    Wei(1,i)=yearID(i);
    Wei(2,i)=nansum(tmpGPPgc.*tmpVPD)/(nansum(tmpLE));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate Water Use Efficiency (We) from GPP/LE
    % units are in gC/kgH20
    We(1,i)=yearID(i);
    We(2,i)=nansum(tmpGPPgc)/(nansum(tmpLE));
    
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Plot the calculated Wei and We

% Plot Wei
figure1=figure;

% set up the axes
axes1 = axes('Parent',figure1,'FontSize',24,'XTick',[1998,2002,2006,2010]);
hold on
xlabel('Year')
ylabel({'W_{ei}'; '(gC kgH20^{-1} hPa)'})
xlim([1998 2011])
ylim([25 45])

% plot Wei calculated above
plot(Wei(1,:),Wei(2,:),'r')
hold off

% Plot Wei
figure1=figure;

% set up the axes
axes1 = axes('Parent',figure1,'FontSize',24,'XTick',[1998,2002,2006,2010]);
hold on
xlabel('Year')
ylabel({'W_{e}'; '(gC kgH20^{-1})'})
xlim([1998 2011])
ylim([2 4])

% plot Wei calculated above
plot(We(1,:),We(2,:),'r')
hold off
