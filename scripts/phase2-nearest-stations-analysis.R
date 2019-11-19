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

# Include all mainline Bedfordshire stations
mainline = c("Luton Airport Parkway", "Luton", "Leagrave", "Harlington", "Flitwick", "Bedford Midland", "Leighton Buzzard", "Arlesey", "Biggleswade", "Sandy")
stns_mainline = filter(stns, Station.Name %in% mainline)

names(s)
stns_mainline$Station.Name = gsub(pattern = "Luton Airport Parkway", replacement = "Luton Airport", x = stns_mainline$Station.Name)


z_nearest_points = sf::st_nearest_feature(c, stns_mainline)
# z_nearest_station = sf::st_join(z, s, op = sf::st_nearest_feature)
z$nearest_station = stns_mainline$Station.Name[z_nearest_points]
c$nearest_station = stns_mainline$Station.Name[z_nearest_points]


names(stns_mainline)
stns_mainline = stns_mainline %>% 
  select(station_name = Station.Name, entries_exits = X1617.Entries...Exits )

c = c %>% st_transform(4326)
z = z %>% st_transform(4326)
stns_mainline = stns_mainline %>% st_transform(4326)
  
sf::st_write(stns_mainline, "../stars-data/data/local-survey/stns-mainline-orr-entries.geojson", delete_dsn = T)
sf::st_write(z, "../stars-data/data/zones-nearest-station.geojson", delete_dsn = T)

tm_shape(c) +
  tm_dots("nearest_station") +
  tm_shape(stns_mainline) + tm_dots(size = "entries_exits", col = "red") 

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
  tm_shape(stns_mainline) + tm_dots(size = "entries_exits", col = "red", alpha = 0.4) +
  tm_text(text = "station_name") +
  tm_shape(midland_mainline) +
  tm_lines() +
  tm_scale_bar()
m
tmap_save(m, "region-overview-stations.html")


# stats on area of analysis -----------------------------------------------
mapview::mapview(region)
st_area(region) %>% units::set_units(km^2)

z %>% sf::st_drop_geometry() %>% 
  group_by(nearest_station) %>% 
  summarise(
    Commuters = sum(all),
    `% drive` = round(sum(car_driver) / Commuters * 100),
    `% rail` = round(sum(train_tube) / Commuters * 100),
    `% cycle` = round(sum(bicycle) / sum(all) * 100),
    `% active` = round(sum(bicycle + foot) / sum(all) * 100),
    `% Go Dutch` = round(sum(dutch_slc) / sum(all) * 100)
    ) %>% 
  arrange(desc(Commuters))

readr::write_csv(.Last.value, "output-data/mode-data-nearest-catchments.csv")

z %>% sf::st_drop_geometry() %>% 
  group_by(lad_name) %>% 
  summarise(
    Commuters = sum(all),
    `% drive` = round(sum(car_driver) / Commuters * 100),
    `% rail` = round(sum(train_tube) / Commuters * 100),
    `% cycle` = round(sum(bicycle) / sum(all) * 100),
    `% active` = round(sum(bicycle + foot) / sum(all) * 100),
    `% Go Dutch` = round(sum(dutch_slc) / sum(all) * 100)
  ) %>% 
  arrange(desc(Commuters))

readr::write_csv(.Last.value, "output-data/mode-data-local-authority.csv")

# Failed attempt to get dimentions...
# region_lake = lakemorpho::lakeMorphoClass(as(region, "Spatial"))
# lakemorpho::lakeMaxLength(region_lake)
# midland_mainline_region = sf::st_intersection(midland_mainline, region)
# plot(midland_mainline_region)
# mapview::mapview(midland_mainline_region)


###########Is this needed?###########

# desire line analysis
library(pct)
l_pct = pct::get_desire_lines(region = "bedfordshire")
l_pct_modes = l_pct %>% 
  select(all, train, bicycle, foot) 

od_beds = od %>% 
  filter(geo_code1 %in% c_msoa$geo_code ) %>% 
  mutate(is_in_bedfordshire = geo_code2 %in% c_msoa$geo_code)

od_beds_intr = od_beds %>% 
  filter(is_in_bedfordshire) %>% 
  filter(all > 10) %>% 
  select(geo_code1, geo_code2, all, train, bicycle, foot, car_driver) %>% 
  mutate(percent_active = (bicycle + foot) / all * 100)


l_pct_modes = stplanr::od2line(od_beds_intr, c_msoa)
l_pct_modes = stplanr::od_oneway(l_pct_modes)

summary({valid = l_pct_modes %>% sf::st_is_valid()})
l_pct_modes = l_pct_modes %>% filter(valid)

plot(l_pct_modes[3:7], lwd = l_pct_modes$all / mean(l_pct_modes$all)) # only shows inter-zone travel


tm_shape(l_pct_modes) +
  tm_lines("percent_active", lwd = "all", scale = 7)

tm_shape(l_pct_modes) +
  tm_lines(palette = "plasma", breaks = c(0, 5, 10, 20, 40, 100),
           lwd = "all",
           scale = 9,
           title.lwd = "Number of trips",
           alpha = 0.6,
           col = "percent_active",
           title = "Active travel (%)"
  ) +
  tm_scale_bar()

c_msoa = pct::get_pct_centroids(region = "bedfordshire")

od = pct::get_od()
od_beds = od %>% 
  filter(geo_code1 %in% c_msoa$geo_code ) %>% 
  mutate(is_in_bedfordshire = geo_code2 %in% c_msoa$geo_code) %>% 
  select(all, train, bicycle, foot, ccar_driver) 

sum(od_beds$all[od_beds$is_in_bedfordshire]) / sum(od_beds$all) 
