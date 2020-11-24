# Aim: estimate cycling potential at the route network level for multiple trip purposes

library(tidyverse)
zones = pct::get_pct_zones("bedfordshire")
zones_luton = zones %>% 
  filter(lad_name == "Luton")
r_stations = readRDS("../stars-data/data/routing/phaseII-routes-nearest-station.Rds")
names(r_stations)
sum(sf::st_length(r_stations))
r_stations_ls = sf::st_cast(r_stations, to = "LINESTRING")
sum(sf::st_length(r_stations_ls)) # the same

rnet_stations = stplanr::overline(r_stations_ls, "go_dutch")
mapview::mapview(rnet_stations)

rnet_commute = pct::get_pct_rnet(region = "bedfordshire")
rnet_school = pct::get_pct_rnet(region = "bedfordshire", purpose = "school")
library(tmap)
tmap_mode("view")

bb = sf::st_bbox(zones_luton)
brks = c(0, 10, 50, 100, 500, 1000, 3000)
m1 = tm_shape(rnet_stations, bbox = bb) +
  tm_lines("go_dutch", palette = "viridis", lwd = 2, breaks = brks) 
m2 = tm_shape(rnet_commute, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL)
m3 = tm_shape(rnet_school, bbox = bb) +
  tm_lines("cambridge_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL)
tmap_arrange(m1, m2, m3)
tmap_mode("plot")
tmap_arrange(m1, m2, m3)
sum(rnet_commute$dutch_slc, na.rm = TRUE)
sum(rnet_school$cambridge_slc, na.rm = TRUE)
sum(rnet_school$dutch_slc, na.rm = TRUE)

rnet_all = rbind(
  rnet_commute %>% select(dutch_slc) %>% mutate(layer = "commute"),
  rnet_school %>% select(dutch_slc) %>% mutate(layer = "school"),
  rnet_stations %>% select(dutch_slc = go_dutch) %>% mutate(layer = "stations")
)
plot(rnet_all)
tm_shape(rnet_all, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) +
  tm_facets(by = "layer")
