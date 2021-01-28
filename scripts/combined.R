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
rnet_commutej = st_join(rnet_commute, zones %>% select(lad_name))
rnet_commutej_by_la = rnet_commutej %>% 
  sf::st_drop_geometry() %>% 
  na.omit() %>% 
  group_by(lad_name) %>% 
  summarise(total_2011 = round(sum(bicycle) / 1000)) %>% 
  pull(total_2011)
rnet_school = pct::get_pct_rnet(region = "bedfordshire", purpose = "school")
rnet_schoolj = st_join(rnet_school, zones %>% select(lad_name))
rnet_schoolj_by_la = rnet_schoolj %>% 
  sf::st_drop_geometry() %>% 
  na.omit() %>% 
  group_by(lad_name) %>% 
  summarise(total_2011 = round(sum(bicycle) / 1000)) %>% 
  pull(total_2011)
library(tmap)
tmap_mode("view")

bb = sf::st_bbox(zones_luton)
luton_hr = sf::read_sf("luton-houghton-regis-region.geojson")
bb = sf::st_bbox(luton_hr)

region_luton = zones_luton %>%
  sf::st_union() %>% 
  sf::st_buffer(dist = 0.001)
plot(region_luton)
brks = c(0, 10, 50, 100, 500, 1000, 3000)
m1 = tm_shape(rnet_stations, bbox = bb) +
  tm_lines("go_dutch", palette = "viridis", lwd = 2, breaks = brks) + 
  tm_shape(region_luton) + tm_borders()
m2 = tm_shape(rnet_commute, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) + 
  tm_shape(region_luton) + tm_borders()
m3 = tm_shape(rnet_school, bbox = bb) +
  tm_lines("cambridge_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) + 
  tm_shape(region_luton) + tm_borders()
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
# plot(rnet_all)
tm_shape(rnet_all, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) + 
  tm_facets(by = "layer", nrow = 3) +
  tm_shape(region_luton) + tm_borders() +
  tm_layout(legend.outside.position = "right", legend.outside.size = 0.2)

rnet_allj = st_join(rnet_all, zones %>% select(lad_name))
mapview::mapview(rnet_allj["lad_name"])
table(rnet_allj$lad_name)
rnet_all$km_cycled = as.numeric(sf::st_length(rnet_all)) * rnet_all$dutch_slc
sumtab = rnet_allj %>% 
  sf::st_drop_geometry() %>% 
  na.omit() %>%
  group_by(lad_name, layer) %>% 
  summarise(
    total_distance_cycled = sum(dutch_slc)
    ) %>%
  ungroup() %>% 
  tidyr::pivot_wider(lad_name, names_from = layer, values_from = total_distance_cycled) 
s_all = rowSums(sumtab %>% select(where(is.numeric)))
sumtab_percent = sumtab %>% mutate_if(is.numeric, function(x) round(x / s_all * 100)) 
sumtab$all = s_all
sumtab_thousands = sumtab %>% mutate_if(is.numeric, function(x) round(x / 1000))
sumtab_thousands$commute_2011 = rnet_commutej_by_la
sumtab_thousands$school_2011 = rnet_schoolj_by_la

rnet_combined = stplanr::overline(rnet_all, "dutch_slc")
rnet_combined$dutch_slc = round(rnet_combined$dutch_slc)
tm_shape(rnet_combined, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) 
tmap_mode("view")
tm_shape(rnet_combined, bbox = bb) +
  tm_lines("dutch_slc", palette = "viridis", lwd = 2, breaks = brks, colorNA = NULL) 
# library(gtsummary)
# rnet_allj %>% 
#   sf::st_drop_geometry() %>% 
#   na.omit() %>%
#   gtsummary::tbl_summary(
#     by = lad_name,
#     type = list(dutch_slc ~ "continuous"),
#     stat
#   )
