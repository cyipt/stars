library(readxl)
library(lubridate)
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


leagrave_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Leagreave!A9:H35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(leagrave_entry)
leagrave_entry = leagrave_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
leagrave_entry$Time = hms::as_hms(leagrave_entry$Time)
leagrave_entry_hourly = leagrave_entry %>% 
  filter(is.na(Time))
leagrave_entry_15min = leagrave_entry %>% 
  filter(!is.na(Time))
leagrave_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))


leagrave_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Leagreave!J9:P35") 
leagrave_exit = leagrave_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
leagrave_exit = bind_cols(Time = leagrave_entry$Time,leagrave_exit)
leagrave_exit_hourly = leagrave_exit %>% 
  filter(is.na(Time))
leagrave_exit_15min = leagrave_exit %>% 
  filter(!is.na(Time))
leagrave_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))



luton_airpt_pkwy_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Luton Airport Parkway!A9:I35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(luton_airpt_pkwy_entry)
luton_airpt_pkwy_entry = luton_airpt_pkwy_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
luton_airpt_pkwy_entry$Time = hms::as_hms(luton_airpt_pkwy_entry$Time)
luton_airpt_pkwy_entry_hourly = luton_airpt_pkwy_entry %>% 
  filter(is.na(Time))
luton_airpt_pkwy_entry_15min = luton_airpt_pkwy_entry %>% 
  filter(!is.na(Time))
luton_airpt_pkwy_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

luton_airpt_pkwy_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Luton Airport Parkway!K9:R35") 
luton_airpt_pkwy_exit = luton_airpt_pkwy_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
luton_airpt_pkwy_exit = bind_cols(Time = luton_airpt_pkwy_entry$Time,luton_airpt_pkwy_exit)
luton_airpt_pkwy_exit_hourly = luton_airpt_pkwy_exit %>% 
  filter(is.na(Time))
luton_airpt_pkwy_exit_15min = luton_airpt_pkwy_exit %>% 
  filter(!is.na(Time))
luton_airpt_pkwy_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))




luton_entry = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Luton!A9:I35",col_types = c("date","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric"))
dim(luton_entry)
luton_entry = luton_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
luton_entry$Time = hms::as_hms(luton_entry$Time)
luton_entry_hourly = luton_entry %>% 
  filter(is.na(Time))
luton_entry_15min = luton_entry %>% 
  filter(!is.na(Time))
luton_entry_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))

luton_exit = read_excel("../stars-data/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Luton!K9:R35") 
luton_exit = luton_exit %>% rename(OnFoot = "On Foot",PrivateCarPickUp = "Private Car Pick Up")
luton_exit = bind_cols(Time = luton_entry$Time,luton_exit)
luton_exit_hourly = luton_exit %>% 
  filter(is.na(Time))
luton_exit_15min = luton_exit %>% 
  filter(!is.na(Time))
luton_exit_hourly$Time = hm(c("05:00","06:00","07:00","08:00","09:00","10:00"))



##########Histogram of mode and time######

# bedford_all_15min = inner_join(bedford_entry_15min,bedford_exit_15min,by = bedford_entry_15min$Time)

# barplot(bedford_entry_15min,xlab = "Time")

bedford_entry_15min$Total = NULL
bedford_entry_15min = bedford_entry_15min %>% 
  pivot_longer(-Time, names_to = "Mode",values_to = "Entries")

bedford_exit_15min$Total = NULL
bedford_exit_15min = bedford_exit_15min %>% 
  pivot_longer(-Time, names_to = "Mode",values_to = "Exits")

ggplot(bedford_entry_15min,aes(col=Mode,Time,Entries)) + geom_freqpoly(stat = "identity",size = 1) +theme_minimal()

ggplot(bedford_exit_15min,aes(col=Mode,Time,Exits)) + geom_freqpoly(stat = "identity",size = 1) +theme_minimal()

#######Entries and exits together

bedford_all_hourly = bind_cols(bedford_entry_hourly,bedford_exit_hourly[2:ncol(bedford_exit_hourly)])

bedford_all_hourly = bedford_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Bus=(Bus+Bus1),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(bedford_all_hourly$Total)

bedford_sj_all_hourly = bind_cols(bedford_sj_entry_hourly,bedford_sj_exit_hourly[2:ncol(bedford_sj_exit_hourly)])

bedford_sj_all_hourly = bedford_sj_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(bedford_sj_all_hourly$Total)

flitwick_all_hourly = bind_cols(flitwick_entry_hourly,flitwick_exit_hourly[2:ncol(flitwick_exit_hourly)])

flitwick_all_hourly = flitwick_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(flitwick_all_hourly$Total)

harlington_all_hourly = bind_cols(harlington_entry_hourly,harlington_exit_hourly[2:ncol(harlington_exit_hourly)])

harlington_all_hourly = harlington_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(harlington_all_hourly$Total)

leagrave_all_hourly = bind_cols(leagrave_entry_hourly,leagrave_exit_hourly[2:ncol(leagrave_exit_hourly)])

leagrave_all_hourly = leagrave_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(leagrave_all_hourly$Total)

luton_airpt_pkwy_all_hourly = bind_cols(luton_airpt_pkwy_entry_hourly,luton_airpt_pkwy_exit_hourly[2:ncol(luton_airpt_pkwy_exit_hourly)])

luton_airpt_pkwy_all_hourly = luton_airpt_pkwy_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(luton_airpt_pkwy_all_hourly$Total)

luton_all_hourly = bind_cols(luton_entry_hourly,luton_exit_hourly[2:ncol(luton_exit_hourly)])

luton_all_hourly = luton_all_hourly %>%
  mutate(Car = (Car+Car1),Cycle=(Cycle+Cycle1),PrivateCarDropOff=(PrivateCarDropOff+PrivateCarPickUp),Taxi=(Taxi+Taxi1),Motorcycle=(Motorcycle+Motorcycle1),OnFoot=(OnFoot+OnFoot1),Total=(Total+Total1)) %>%
  select(-ends_with("1"),-PrivateCarPickUp)

sum(luton_all_hourly$Total)

##############Compare survey results with ORR 2017-18 data########

orr_data = read.csv("../stars-data/data/orr/beds_stations.csv")
orr_data$EntriesAndExits_1718 = orr_data$EntriesAndExits_1718/1000000

compare = tibble(Station_name = orr_data$Station.Name, EntriesAndExits_1718 = orr_data$EntriesAndExits_1718,survey = c(sum(bedford_all_hourly$Total),sum(bedford_sj_all_hourly$Total),sum(flitwick_all_hourly$Total),sum(harlington_all_hourly$Total),sum(leagrave_all_hourly$Total),sum(luton_all_hourly$Total),sum(luton_airpt_pkwy_all_hourly$Total)))


ggplot(compare,aes(EntriesAndExits_1718,survey)) +
  geom_point(col = "red") +
  geom_text(aes(label = Station_name,hjust=-0.1)) +
  xlab("ORR data 17_18 (million entries and exits)") + ylab("Bedfordshire survey data") +
  coord_cartesian(xlim = c(0,6)) +
  theme_grey()



# bedford_all_hourly$Total = NULL
# bedford_all_hourly = bedford_all_hourly %>% 
#   pivot_longer(-Time, names_to = "Mode",values_to = "Entries_and_Exits")
# 
# ggplot(bedford_all_hourly,aes(col=Mode,Time,Entries_and_Exits)) + geom_freqpoly(stat = "identity",size = 1) +theme_minimal()

# 
# bed_entry_totals = bedford_entry[nrow(bedford_entry),-ncol(bedford_entry)]
# bed_entry_totals = t(bed_entry_totals[,-1])
# colnames(bed_entry_totals) = "count"
# 
# bed_entry_totals = as.vector(bed_entry_totals)
# barplot(bed_entry_totals)
# 
# read.x


