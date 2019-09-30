# aim: analyse train travel to stations based on nearest station in/around Luton

library(sf)
library(tidyverse)
library(tmap)
tmap_mode("view")

region = read_sf("output-data/region.geojson")

z = pct::get_pct_zones("bedfordshire")
stns = sf::read_sf("output-data/stns.geojson")
names(stns)
summary(stns$X1617.Entries...Exits)
stns_major = filter(stns, X1617.Entries...Exits > 1e6)
stns_minor = filter(stns, X1617.Entries...Exits < 1e6)

names(s)

z_nearest_points = sf::st_nearest_feature(z, stns_major)
# z_nearest_station = sf::st_join(z, s, op = sf::st_nearest_feature)
z$nearest_station = stns_major$Station.Name[z_nearest_points]


names(stns_major)
stns_major = stns_major %>% 
  select(station_name = Station.Name, entries_exits = X1617.Entries...Exits )
  
sf::st_write(stns_major, "../stars-data/data/local-survey/sttns_major-orr-entries.geojson", delete_dsn = T)
sf::st_write(z, "../stars-data/data/zones-nearest-station.geojson", delete_dsn = T)

m = tm_shape(z) +
  tm_polygons("nearest_station") +
  tm_shape(stns_major) + tm_dots(size = "entries_exits", col = "red") 
m
tmap_save(m, "region-overview-stations.html")
