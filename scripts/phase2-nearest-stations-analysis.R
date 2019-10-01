# aim: analyse train travel to stations based on nearest station in/around Luton

library(sf)
library(tidyverse)
library(tmap)
tmap_mode("view")

region = read_sf("output-data/region.geojson")

z = pct::get_pct_zones("bedfordshire", geography = "lsoa") %>% st_transform(27700)
c = pct::get_pct_centroids("bedfordshire", geography = "lsoa") %>% st_transform(27700)
summary(z$geo_code == c$geo_code)
z = z[match(c$geo_code, z$geo_code), ]
summary(z$geo_code == c$geo_code)

stns = sf::read_sf("output-data/stns.geojson") %>% st_transform(27700)
names(stns)
summary(stns$X1617.Entries...Exits)
stns_major = filter(stns, X1617.Entries...Exits > 1e6)
stns_minor = filter(stns, X1617.Entries...Exits < 1e6)

names(s)

z_nearest_points = sf::st_nearest_feature(c, stns_major)
# z_nearest_station = sf::st_join(z, s, op = sf::st_nearest_feature)
z$nearest_station = stns_major$Station.Name[z_nearest_points]
c$nearest_station = stns_major$Station.Name[z_nearest_points]


names(stns_major)
stns_major = stns_major %>% 
  select(station_name = Station.Name, entries_exits = X1617.Entries...Exits )

c = c %>% st_transform(4326)
z = z %>% st_transform(4326)
stns_major = stns_major %>% st_transform(4326)
  
sf::st_write(stns_major, "../stars-data/data/local-survey/sttns_major-orr-entries.geojson", delete_dsn = T)
sf::st_write(z, "../stars-data/data/zones-nearest-station.geojson", delete_dsn = T)

tm_shape(c) +
  tm_dots("nearest_station") +
  tm_shape(stns_major) + tm_dots(size = "entries_exits", col = "red") 
  

m = tm_shape(z) +
  tm_polygons("nearest_station", alpha = 0.3, legend.show = FALSE) +
  tm_shape(c) +
  tm_dots("nearest_station") +
  tm_shape(stns_major) + tm_dots(size = "entries_exits", col = "red", alpha = 0.4) +
  tm_scale_bar()
m
tmap_save(m, "region-overview-stations.html")
