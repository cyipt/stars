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

# get mainline to london
# library(geofabric)
# england = geofabric::get_geofabric("england")

# england_rail = sf::read_sf("~/hd/data/osm/england.osm.pbf", layer = "multilinestrings",
#                            query = "select * from multilinestrings where name = 'Midland Main Line trackage'")
# 
# 
# saveRDS(england_rail, "../stars-data/data/osm/midland_mainline_trackage.Rds")
# england_rail_small = rmapshaper::ms_simplify(england_rail)
# saveRDS(england_rail_small, "../stars-data/data/osm/midland_mainline_trackage_small.Rds")
# pryr::object_size(england_rail_small)

# fails
# library(osmdata)
# osm_data = opq("united kingdom") %>% 
#   add_osm_feature("name", "Midland Main Line") %>% 
#   osmdata_sf()


midland_mainline = readRDS("../stars-data/data/osm/midland_mainline_trackage_small.Rds")

m = tm_shape(z) +
  tm_polygons("nearest_station", alpha = 0.3, legend.show = FALSE) +
  tm_shape(c) +
  tm_dots("nearest_station") +
  tm_shape(stns_major) + tm_dots(size = "entries_exits", col = "red", alpha = 0.4) +
  tm_text(text = "station_name") +
  tm_shape(midland_mainline) +
  tm_lines() +
  tm_scale_bar()
m
tmap_save(m, "region-overview-stations.html")
