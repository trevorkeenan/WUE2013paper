# this script will ...
# load the raw data from US-UMB
# Filter the data to:
#   1. Remove non-summer data
#   2. Remove night time data
#   3. Remove data from day of and day after precipitation event
#	4. Plot the calculated yearly Wei and We.

# NB - you must set the location of the data file dataUMB_forWeiCalc.csv
#		to its directory on your computer

# written by Trevor Keenan (December 2012)
# for:
# Keenan, T. F. et al. Increase in forest water-use efficiency as atmospheric carbon dioxide concentrations rise. 
# Nature 499, 324–327 (2013).

###########################################################################
## 1. load the raw data csv file
# clear all
data <- read.csv(file="dataUMB_forWeiCalc.csv",head=TRUE,sep=",")

# clean up
rawData<-data;
rm(data)

###########################################################################
# 2. define the structure of the data file
col.year<-1;
col.doy<-2;
col.hour<-3;
col.ppfd<-4;     # units: umol m-2 s-1
col.LE<-5;       # units: W m-2
col.GPP<-6;      # units: umol m-2 s-1
col.VPD<-7;      # units: hPa
col.precip<-8;   # units: mm h-1

# define the start and end of summer
seasonStart<-5*30;   # will delete data before this doy
seasonEnd<-8*30;     # will delete data after this doy


###########################################################################
# 3. loop through each year, apply filtering, unit conversions and calculate Wei

# initialize the results matrix
Wei=matrix(0,3,11);
We=matrix(0,3,11);

# identify the number of years in the data
yearID<-unique(rawData[,col.year]);

# loop through each year and apply the same filtering
for (i in 1:11){

	# find the location of the data for the current year
		indX<-rawData[,col.year]==yearID[i];
		
	# extract the current years data
		currentYearData<-rawData[indX,];
		
	###################################################################
	# filter currentYearData to remove data points we're not interested in
	# Those are:
	# 1. Night time data
	# 2. Non-summer data
	# 3. Bad data (negative GPP, LE or VPD)
	# 4. Gap-filled data

		# remove off season data
		IndX2<-(currentYearData[,col.doy]<seasonStart | currentYearData[,col.doy]>seasonEnd);
		currentYearData[IndX2,4:8]<--9999;

		# remove night-time data
		IndX<-currentYearData[,col.ppfd]<250;
		currentYearData[IndX,4:8]<--9999;

		# find bad LE values
		IndX<-(currentYearData[,col.LE]<0);
		currentYearData[IndX,4:8]<--9999;

		# find bad GPP values
		IndX<-(currentYearData[,col.GPP]<=0);
		currentYearData[IndX,4:8]<--9999;

		# find bad VPD values
		IndX<-(currentYearData[,col.VPD]<0.5);
		currentYearData[IndX,4:8]<--9999;

		# remove all data from the day of rain
		# get positive precip hours
		IndX<-(currentYearData[,col.precip]>0);
		# find the days on which rain events occur
		uniqueDays<-unique(currentYearData[IndX,col.doy]);
		# find the index of hours for these days in the year
		IndX<-is.element(currentYearData[,col.doy],uniqueDays);
		# remove the data for rain days
		currentYearData[IndX,4:8]<--9999;

		# remove all data from the day AFTER the day of rain
		# get positive precip hours
		IndX<-(currentYearData[,col.precip]>0);
		# find the day after days with rain events
		uniqueDays<-unique(currentYearData[IndX,col.doy])+1;
		# find the index of hours for these days in the year
		IndX<-is.element(currentYearData[,col.doy],uniqueDays);
		# remove the data for rain days
		currentYearData[IndX,4:8]<--9999;

		# remove -9999 values
		IndX<-(currentYearData==-9999);
		currentYearData[IndX]<-NaN;

	###################################################################
	# Apply unit conversions to GPP and LE

		tmpGPP<-(currentYearData[,col.GPP]);    # umol m-2 s-1.
		tmpVPD<-currentYearData[,col.VPD];    # hPA
		tmpLE<-currentYearData[,col.LE];      # W m-2


		######### convert GPP from umol m-2 s-1 to gC m-2 hr-1
		tmpGPPgc<-tmpGPP*0.0432;
		# Conversion is: gC/m2/hhr = umol/m2/s * (3600 sec/hr) * (12.011 gc/mol) * (10^-6  mol/umol) = umol/m2/s * 0.0432

		######### convert LE from W m-2 to kg H20 m-2 hr-1
		tmpLE<-(60*60)*tmpLE/2454000;
		# W m-2 = J s-1
		# kg m-2 s-1 = J s-1/2454000 (= J s-1/latent heat of vaporization [2.5*10^6 J kg-1])
		# kg m-2 hr-1 = kg m-2 s-1*(60*60)


	###################################################################
	# Calculate Intrinsic Water Use Efficiency (Wei) from GPP*VPD/LE
	# units are in gC/kgH20.hPa

	Wei[1,i]<-yearID[i];
	Wei[2,i]<-sum(tmpGPPgc*tmpVPD,na.rm=TRUE)/(sum(tmpLE,na.rm=TRUE));

	###################################################################
	# Calculate Water Use Efficiency (We) from GPP/LE
	# units are in gC/kgH20
	We[1,i]<-yearID[i];
	We[2,i]<-sum(tmpGPPgc,na.rm=TRUE)/(sum(tmpLE,na.rm=TRUE));

}



###########################################################################
## 4. Plot the calculated Wei and We

# Plot Wei
x<-Wei[1,];
y<-Wei[2,];

plot(x,y, main="Wei",
     xlab="Year", ylab="Wei (gC kgH20-1 hPa)",xlim=c(1998,2011), ylim=c(25,45))


# Plot Wei
x<-We[1,];
y<-We[2,];

plot(x,y, main="We",
     xlab="Year", ylab="We (gC kgH20-1)",xlim=c(1998,2011), ylim=c(2,4))
