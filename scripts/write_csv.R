library(readr)
totals = as.data.frame(totals)
totals = totals[,2:6]
write_csv(totals,"./output-data/totals.csv")
totals = readr::read_csv("./output-data/totals.csv")
totals = read.csv("./output-data/totals.csv")
totals

colnames(totals) = c("Sum", "Phase 1 (all stations)", "Phase 1 (ten stations)", "Phase 2 (ten stations)", "Census 2011")


s_counts_dutch = s_counts_dutch[,2:6]
write_csv(s_counts_dutch,"./output-data/s_counts_dutch.csv")
s_counts_dutch = readr::read_csv("./output-data/s_counts_dutch.csv")
s_counts_dutch
colnames(s_counts_dutch) = c("Station", "Phase 1", "Phase 2", "Takeup (Phase 1)", "Takeup (Phase 2)")

racks
racks = racks[,2:5]
write_csv(racks,"./output-data/racks.csv")
racks = readr::read_csv("./output-data/racks.csv")
racks
colnames(racks) = c("Station", "Cycle racks", "Phase 1 Go Dutch", "Phase 2 Go Dutch")
