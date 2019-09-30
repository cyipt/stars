library(readxl)
library(tidyr)
library(dplyr)

# bedford_entry = read.csv("../stars/luton-survey/bedford-entry.csv")
# bedford_exit = read.csv("../stars/luton-survey/bedford-exit.csv")

bedford_entry = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford!A9:I37")
dim(bedford_entry)
bedford_entry = bedford_entry %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
bedford_entry = drop_na(bedford_entry)

bedford_exit = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford!K9:R37") 
bedford_exit = bedford_exit %>% rename(Time = ...1,OnFoot = "On Foot",PrivateCarDropOff = "Private Car Drop off")
bedford_exit = cbind(bedford_entry$Time,bedford_exit)
bedford_exit = drop_na(bedford_exit)

bedford_sj_entry = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford St John!A9:H37")
bedford_sj_entry = drop_na(bedford_sj_entry)

bedford_sj_exit = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Bedford St John!J9:P37") 
bedford_sj_exit = drop_na(bedford_sj_exit)

flitwick_entry = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Flitwick!A9:I37")
flitwick_entry = drop_na(flitwick_entry)

flitwick_exit = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Flitwick!K9:R37") 
flitwick_exit = drop_na(flitwick_exit)

harlington_entry = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Harlington!A9:I37")
harlington_entry = drop_na(harlington_entry)

harlington_exit = read_excel("../stars/luton-survey/Luton-Rail-Stations-Reports/1335-WTR_EntryExit_1-7_27th-29thNov.xlsx", range = "Harlington!K9:R37") 
harlington_exit = drop_na(harlington_exit)

################

bed_entry_totals = bedford_entry[nrow(bedford_entry),-ncol(bedford_entry)]
bed_entry_totals = t(bed_entry_totals[,-1])
colnames(bed_entry_totals) = "count"

bed_entry_totals = as.vector(bed_entry_totals)
barplot(bed_entry_totals)

read.x

