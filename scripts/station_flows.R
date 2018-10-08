# Estimate Cycle Flow into and out of stations
library(dplyr)
library(sf)

flows = readRDS("../stars-data/routes_scenarios.Rds")

flows.in = flows[,c("id", "from_lsoa","from_point_name","AllMethods","Train","cycle1_baseline_slc","cycle1_dutch_slc","cycle1_ebike_slc")]
flows.out = flows[,c("id","to_point_name", "to_lsoa","AllMethods","Train","cycle2_baseline_slc","cycle2_dutch_slc","cycle2_ebike_slc")]

flows.in = flows.in[!is.na(flows.in$cycle1_baseline_slc),]
flows.out = flows.out[!is.na(flows.out$cycle2_baseline_slc),]

flows.in = flows.in %>%
  group_by(from_point_name) %>%
  summarise(AllMethods_in = sum(AllMethods, na.rm = T),
            Train_in = sum(Train, na.rm = T),
            Baseline_in = sum(cycle1_baseline_slc, na.rm = T),
            Dutch_in = sum(cycle1_dutch_slc, na.rm = T),
            Ebike_in = sum(cycle1_ebike_slc, na.rm = T))

flows.out = flows.out %>%
  group_by(to_point_name) %>%
  summarise(AllMethods_out = sum(AllMethods, na.rm = T),
            Train_out = sum(Train, na.rm = T),
            Baseline_out = sum(cycle2_baseline_slc, na.rm = T),
            Dutch_out = sum(cycle2_dutch_slc, na.rm = T),
            Ebike_out = sum(cycle2_ebike_slc, na.rm = T))


flows.bothways = data.frame(station = unique(c(flows.in$from_point_name, flows.out$to_point_name)), stringsAsFactors = F)
flows.bothways = left_join(flows.bothways, flows.in, by = c("station" = "from_point_name"))
flows.bothways = left_join(flows.bothways, flows.out, by = c("station" = "to_point_name"))

flows.bothways$annual_entries = flows.bothways$Train_in * 220
flows.bothways$annual_exits = flows.bothways$Train_in * 220

saveRDS(flows.bothways, "../stars-data/station_flow_estimates.Rds")

stations =  st_read("output-data/stations_all.geojson")

flows.bothways = left_join(flows.bothways, stations, by = c("station" = "name"))
flows.bothways = st_as_sf(flows.bothways)

#qtm(flows.bothways, size = )
tm_shape(flows.bothways) +
  tm_bubbles(size = "annual_entries", col = "Ebike_in", breaks = c(0,100,200,300,400,500,600))
