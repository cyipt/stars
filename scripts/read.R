# library(readxl)
library(tidyr)
# library(dplyr)
# # library(stringr)
# library(lubridate)
library(tidyverse)

# bedford_entry = read.csv("../stars-data/luton-survey/bedford-entry.csv")
# bedford_exit = read.csv("../stars-data/luton-survey/bedford-exit.csv")

bedford_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford!A9:I35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(bedford_entry)
bedford_entry = bedford_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
bedford_entry$Time = hms::as_hms(bedford_entry$Time)
# bedford_entry = drop_na(bedford_entry)
# bedford_entry_hourly = bedford_entry[str_which(bedford_entry$Time, "Hr"),]
# bedford_entry_15min = bedford_entry[str_which(bedford_entry$Time, "0"),]
bedford_entry_hourly = bedford_entry %>% 
  filter(is.na(Time))
bedford_entry_15min = bedford_entry %>% 
  filter(!is.na(Time))
bedford_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))



bedford_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford!K9:R35") 
bedford_exit = bedford_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
# bedford_exit = drop_na(bedford_exit)
bedford_exit = bind_cols(Time = bedford_entry$Time,bedford_exit)
bedford_exit_hourly = bedford_exit %>% 
  filter(is.na(Time))
bedford_exit_15min = bedford_exit %>% 
  filter(!is.na(Time))
bedford_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))


bedford_sj_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford St John!A9:H35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(bedford_sj_entry)
bedford_sj_entry = bedford_sj_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
bedford_sj_entry$Time = hms::as_hms(bedford_sj_entry$Time)
bedford_sj_entry_hourly = bedford_sj_entry %>% 
  filter(is.na(Time))
bedford_sj_entry_15min = bedford_sj_entry %>% 
  filter(!is.na(Time))
bedford_sj_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))




bedford_sj_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford St John!J9:P35") 
bedford_sj_exit = bedford_sj_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
bedford_sj_exit = bind_cols(Time = bedford_sj_entry$Time,bedford_sj_exit)
bedford_sj_exit_hourly = bedford_sj_exit %>% 
  filter(is.na(Time))
bedford_sj_exit_15min = bedford_sj_exit %>% 
  filter(!is.na(Time))
bedford_sj_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))



flitwick_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Flitwick!A9:I35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(flitwick_entry)
flitwick_entry = flitwick_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
flitwick_entry$Time = hms::as_hms(flitwick_entry$Time)
flitwick_entry_hourly = flitwick_entry %>% 
  filter(is.na(Time))
flitwick_entry_15min = flitwick_entry %>% 
  filter(!is.na(Time))
flitwick_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

flitwick_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Flitwick!K9:R35") 
flitwick_exit = flitwick_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
flitwick_exit = bind_cols(Time = flitwick_entry$Time,flitwick_exit)
flitwick_exit_hourly = flitwick_exit %>% 
  filter(is.na(Time))
flitwick_exit_15min = flitwick_exit %>% 
  filter(!is.na(Time))
flitwick_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

harlington_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Harlington!A9:I35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(harlington_entry)
harlington_entry = harlington_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
harlington_entry$Time = hms::as_hms(harlington_entry$Time)
harlington_entry_hourly = harlington_entry %>% 
  filter(is.na(Time))
harlington_entry_15min = harlington_entry %>% 
  filter(!is.na(Time))
harlington_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

harlington_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Harlington!K9:R35") 
harlington_exit = harlington_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
harlington_exit = bind_cols(Time = harlington_entry$Time,harlington_exit)
harlington_exit_hourly = harlington_exit %>% 
  filter(is.na(Time))
harlington_exit_15min = harlington_exit %>% 
  filter(!is.na(Time))
harlington_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

##########Histogram of mode and time######

# bedford_all_15min = inner_join(bedford_entry_15min,bedford_exit_15min,by = bedford_entry_15min$Time)

bedford_entry_15min$Total = NULL
bedford_entry_15min = bedford_entry_15min %>% 
  pivot_longer(-Time, names_to = "Mode",values_to = "Entries")

bedford_exit_15min$Total = NULL
bedford_exit_15min = bedford_exit_15min %>% 
  pivot_longer(-Time, names_to = "Mode",values_to = "Exits")

ggplot(bedford_entry_15min,aes(col=Mode,Time,Entries)) + geom_freqpoly(stat = "identity",size = 1) +theme_minimal()

ggplot(bedford_exit_15min,aes(col=Mode,Time,Exits)) + geom_freqpoly(stat = "identity",size = 1) +theme_minimal()

#######Entries and exits together

bedford_all_hourly = bind_cols(bedford_entry_hourly,bedford_exit_hourly[2:9])


# barplot(bedford_entry_15min,xlab = "Time")
# 
# bed_entry_totals = bedford_entry[nrow(bedford_entry),-ncol(bedford_entry)]
# bed_entry_totals = t(bed_entry_totals[,-1])
# colnames(bed_entry_totals) = "count"
# 
# bed_entry_totals = as.vector(bed_entry_totals)
# barplot(bed_entry_totals)
# 
# read.x


