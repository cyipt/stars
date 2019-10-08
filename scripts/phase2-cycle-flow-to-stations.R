# Aim: generate first principles estimates of cycling to stations potential based on the PCT
library(tidyverse)
library(tmap)
library(sf)
tmap_mode("view")

s = sf::read_sf("../stars-data/data/local-survey/sttns_major-orr-entries.geojson")
z = sf::read_sf("../stars-data/data/zones-nearest-station.geojson")
c = pct::get_pct_centroids(region = "bedfordshire", geography = "lsoa")
summary(z$geo_code == c$geo_code)

qtm(z) + qtm(c)

names(s)
od = z %>% st_drop_geometry() %>% select(geo_code, nearest_station, train_tube, all) 
stations_duplicated = s[match(z$nearest_station, s$station_name), ]
centroids = sf::st_sf(od, geometry = c$geometry)
origin_coordinates = st_coordinates(centroids)
dest_coordinates = st_coordinates(stations_duplicated)
odc = cbind(origin_coordinates, dest_coordinates)
l = stplanr::od_coords2line(odc)
l$all = centroids$all
l$rail = centroids$train_tube
# l$distance_km = sf::st_length(l) / 1000 %>% as.numeric()
# weighted.mean(l$distance_km, centroids$all)

names(l)[1:4] = c("fx", "fy", "tx", "ty")
plot(l)

r = stplanr::route_cyclestreet(origin_coordinates[1, ], to = dest_coordinates[1, ])
plot(r)

# r = cyclestreets::journey(origin_coordinates[1, ], to = dest_coordinates[1, ])
# plot(r)
# 
# r19 = lapply(1:nrow(l), FUN = function(x) {
#   r = cyclestreets::journey(origin_coordinates[x, ], to = dest_coordinates[x, ])
#   r$fx = origin_coordinates[x, 1]
#   r$fy = origin_coordinates[x, 2]
#   r$tx = dest_coordinates[x, 1]
#   r$ty = dest_coordinates[x, 2]
#   r
# })
# r_all = do.call(rbind, r19)
# plot(r_all)

# with latest version of stplanr
devtools::install_github("ropensci/stplanr", ref = "dev")
library(stplanr)
r_all = route(l = l, route_fun = cyclestreets::journey)
r_all$quietness = r_all$busynance / r_all$distances
tm_shape(r_all[1:2222, ]) + tm_lines("quietness")
saveRDS(r_all, "../stars-data/data/routing/phaseII-nearest-stplanr-dev.Rds")
names(r_all)

plot(r_all$distances, r_all$busynance)
# busynance is simply distance time (the cost of) quietness
plot(r_all$distances * r_all$quietness, r_all$busynance)
rnet = overline2(r_all, "rail")

r_grouped_by_segment = r_all %>% 
  group_by(name, distances, busynance) %>% 
  summarise(n = n(), all = sum(rail), busyness = mean(quietness))

r_grouped_by_segment$all[r_grouped_by_segment$all > 1000] = 1000
r_grouped_linestring = r_grouped_by_segment %>% st_cast("LINESTRING")
rnet_segment = overline(r_grouped_linestring, "all")

tm_shape(r_grouped_by_segment) +
  tm_lines("busyness", lwd = "all", scale = 9, palette = "plasma", breaks = c(0, 1, 2, 3, 5, 10, 25)) +
  tm_shape(region) + tm_borders()

tm_shape(r_grouped_by_segment) +
  tm_lines("all", lwd = "all", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() +
  tm_scale_bar()

# experiments with grouping
nrow(r_all)
summary(r_all$elevations)
r_grouped = r_all %>% 
  group_by(fx, fy, tx, ty) %>% 
  summarise(
    n = n(),
    average_incline = sum(abs(diff(elevations))) / sum(distances),
    distance_m = sum(distances),
    quietness = mean(quietness)
    ) %>% 
  ungroup()

summary(r_grouped)


n = 1:9
plot(r_grouped$geometry[n], col = n)
plot(l$geometry[n], col = n, add = T) # mismatching routes

# l_routes = inner_join(st_drop_geometry(l), r_grouped)
# class(l_routes)
# l_routes = st_sf(l_routes)
# plot(l_routes)

# plot(l$geometry[n], col = n) # mismatching routes
# plot(l_routes$geometry[n], col = n, add = T) # mismatching routes

# l_routes$rail = od$train_tube
# l_routes$all = od$all
# plot(z["train_tube"])
# plot(l_routes["rail"])

# calculate pct scenarios
l_routes$godutch = pct::uptake_pct_godutch(distance = r_grouped$average_incline, gradient = r_grouped$average_incline) *
  l_routes$all 

plot(l_routes$all, l_routes$godutch)


l_routes = st_cast(l_routes, "LINESTRING")
rnet = stplanr::overline2(l_routes, "godutch")
plot(rnet) # works but looses segment-level geometries...

r_all_flow = aggregate(rnet, r_all, FUN = max)
plot(r_all_flow)
nrow(r_all_flow)
nrow(r_all)

plot(r_all[5555,])
plot(r_all_flow[5555, ]) # they are the same

r_all$flow = r_all_flow$godutch
plot(r_all["flow"], lwd = r_all$godutch / mean(r_all$godutch))

# save results
saveRDS(r_all, "r_all_from_lsoa_to_stations.Rds")
piggyback::pb_upload("r_all_from_lsoa_to_stations.Rds")

# create map
tm_shape(r_all) +
  tm_lines("flow", palette = "-viridis", breaks = c(0, 50, 100, 200, 400, 1000, 2000, 20000), lwd = "flow", scale = 7) +
  tm_scale_bar()


# test matches
# od$geo_code %in% z$geo_code
# od$nearest_station %in% s$station_name

# l = stplanr::od2line(flow = od, zones = z, destinations = s) # fail

# compare with previous results

r_phase1 = readRDS("../stars-data/data/routing/routes_scenarios.Rds")
class(r_phase1)
names(r_phase1)
summary(r_phase1)

sum(r_phase1$Train) / sum(r_phase1$AllMethods)

r_phase1_cycle1 = r_phase1 %>% select(AllMethods, Train, Bicycle, cycle1_baseline_slc, cycle1_dutch_slc) %>% 
  st_sf(geometry = r_phase1$geom_cycle1) %>% 
  filter(!lengths(geometry) == 0)

summary(r_phase1_cycle1$geometry)
summary({empty = lengths(r_phase1_cycle1$geometry) == 0})

class(r_phase1_cycle1)
class(r_phase1_cycle1$geometry)

r_phase1_cycle1 = r_phase1_cycle1 %>% st_zm()
rnet_phase1_cycle1 = overline2(r_phase1_cycle1, "Train")

tm_shape(rnet_phase1_cycle1) +
  tm_lines("Train", lwd = "Train", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders()
