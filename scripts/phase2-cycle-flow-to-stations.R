# Aim: generate first principles estimates of cycling to stations potential based on the PCT
library(tidyverse)
library(tmap)
library(sf)
tmap_mode("view")

#the next line is changed to use all mainline Bedfordshire stations 
# s = sf::read_sf("../stars-data/data/local-survey/sttns_major-orr-entries.geojson")
s = sf::read_sf("../stars-data/data/local-survey/stns-mainline-orr-entries.geojson")
z = sf::read_sf("../stars-data/data/zones-nearest-station.geojson")
c = pct::get_pct_centroids(region = "bedfordshire", geography = "lsoa")
summary(z$geo_code == c$geo_code)

qtm(z) + qtm(c)

names(s)
od = z %>% st_drop_geometry() %>% select(geo_code, nearest_station, train_tube, all) 

#####distance as the crow flies########

stations_duplicated = s[match(z$nearest_station, s$station_name), ]
centroids = sf::st_sf(od, geometry = c$geometry)
origin_coordinates = st_coordinates(centroids)
dest_coordinates = st_coordinates(stations_duplicated)
odc = cbind(origin_coordinates, dest_coordinates)
l = stplanr::od_coords2line(odc)
l$all = centroids$all
l$rail = centroids$train_tube
# l$distance_crow = sf::st_length(l) / 1000 %>% as.numeric()
# weighted.mean(l$distance_crow, centroids$all)

names(l)[1:4] = c("fx", "fy", "tx", "ty")
plot(l)

r = stplanr::route_cyclestreet(origin_coordinates[1, ], to = dest_coordinates[1, ])
plot(r)


#########finding the shortest route distance, instead of distance as the crow flies

odex = expand(od, geo_code, nearest_station)
odex = left_join(odex,od[,-2], by = "geo_code")
stations_duplicated_ex = s[match(odex$nearest_station, s$station_name), ]
centroids_ex = sf::st_sf(odex, geometry = c$geometry)
origin_coordinates_ex = st_coordinates(centroids_ex)
dest_coordinates_ex = st_coordinates(stations_duplicated_ex)
odc_ex = cbind(origin_coordinates_ex,dest_coordinates_ex)

l_ex = stplanr::od_coords2line(odc_ex)

l_ex$all = centroids_ex$all
l_ex$rail = centroids_ex$train_tube
l_ex$nearest_station = centroids_ex$nearest_station
l_ex$geo_code = centroids_ex$geo_code
l_ex$distance_crow = sf::st_length(l_ex) / 1000 %>% as.numeric()

names(l_ex)[1:4] = c("fx", "fy", "tx", "ty")
plot(l_ex)

l_short = filter(l_ex,unclass(distance_crow)<5)
stations_duplicated_short = s[match(l_short$nearest_station, s$station_name), ]

id = 1:dim(l_short)[1]
l_short = cbind(l_short,id)
plot(l_short)


#r_ex = stplanr::route_cyclestreet(origin_coordinates_ex[1, ], to = dest_coordinates_ex[1, ])
#plot(r_ex)

library(stplanr)
r_all_short = route(l = l_short, route_fun = cyclestreets::journey)
dim(r_all_short)

###find route distance by road######
route_dist = aggregate(r_all_short$distances,by = list(id = r_all_short$id), FUN = sum)

r_all_short$id = as.character(r_all_short$id)
route_dist$id = as.character(route_dist$id)
r_all_short = full_join(r_all_short,route_dist,by = "id")

r_all_short = r_all_short %>% rename(distance_road = x)

# r_all_short$route_dist = lapply(,sum(r_all_short$distances))
# 
# r_all_short = as.tibble(r_all_short)
# 
# mapped = r_all_short[,c(2,18)] %>%
#   group_by(id) %>%
#   group_map( ~ sum(.x))
# 
# r_all_short %>%
#   split(.$id) %>%
#   lapply(X = distances,sum)
# 
# r_all_short %>%
#   split(.$id) %>%
#   map(.f = sum(.$distances))

###select only routes that are nearest by road###
r_nearest_by_road = r_all_short %>%
  group_by(geo_code) %>%
  filter(distance_road == min(distance_road))

# length(unique(r_all_short$geo_code))
# length(unique(r_nearest_by_road$geo_code))



# test = r_all_short[which(r_all_short$geo_code == "E01015693"),c(1,2,3,18,19,20)]
# filter(test,distance_road == min(distance_road))




###

r_nearest_by_road$quietness = r_nearest_by_road$busynance / r_nearest_by_road$distances
tm_shape(r_nearest_by_road) + tm_lines("quietness")
saveRDS(r_nearest_by_road, "../stars-data/data/routing/phaseII-nearest-stplanr-dev.Rds")
names(r_nearest_by_road)

plot(r_nearest_by_road$distances, r_nearest_by_road$busynance)
# busynance is simply distance time (the cost of) quietness
plot(r_nearest_by_road$distances * r_nearest_by_road$quietness, r_nearest_by_road$busynance)
rnet = overline2(r_nearest_by_road, "rail")

r_grouped_by_segment = r_nearest_by_road %>% 
  group_by(name, distances, busynance) %>% 
  summarise(n = n(), all = sum(rail), busyness = mean(quietness))

##still need to remove the routes that don't go to the nearest station. So far we have routes split into route segments, so these route segments will need to be reconstituted back into routes then the longer ones culled from the dataset.


###########distance as the crow flies###########

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

# with latest version of stplanr - no longer required
# devtools::install_github("ropensci/stplanr", ref = "dev")
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

#########both versions################

r_grouped_by_segment$all[r_grouped_by_segment$all > 1000] = 1000
r_grouped_linestring = r_grouped_by_segment %>% st_cast("LINESTRING")
rnet_segment = overline(r_grouped_linestring, "all")

#Map busyness of route segments
png(filename = "./figures/bedford-busyness.png", height = 1000, width = 700)
tmap_mode("plot")
tm_shape(r_grouped_by_segment) +
  tm_lines("busyness", lwd = "all", scale = 9, palette = "plasma", breaks = c(0, 1, 2, 3, 5, 10, 25)) +
  tm_shape(region) + tm_borders()
dev.off()
# tmap_save(.Last.value, "./figures/bedford-busyness.png")

#Map total number of journeys to stations on each route segment
png(filename = "./figures/bedford-rnet-all-phase2.png", height = 1000, width = 700)
tmap_mode("plot")
tm_shape(r_grouped_by_segment) +
  tm_lines("all", lwd = "all", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() +
  tm_scale_bar()
dev.off()

# experiments with grouping - estimate uptake
nrow(r_all)
summary(r_all$elevations)
r_grouped = r_all %>% 
  group_by(fx, fy, tx, ty) %>% 
  summarise(
    n = n(),
    rail = mean(rail),
    average_incline = sum(abs(diff(elevations))) / sum(distances),
    distance_m = sum(distances),
    quietness = mean(quietness)
    ) %>% 
  ungroup()

summary(r_grouped)
summary(r_grouped$rail)
summary(l$rail) # good sense check: identical
r_grouped$go_dutch = pct::uptake_pct_godutch(distance = r_grouped$distance_m, gradient = r_grouped$average_incline) *
  r_grouped$rail
r_grouped_lines = r_grouped %>% st_cast("LINESTRING")
rnet_go_dutch = overline2(r_grouped_lines, "go_dutch")

#Map modelled Go Dutch cycle journeys to stations
tm_shape(rnet_go_dutch) +
  tm_lines("go_dutch", lwd = "go_dutch", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() + tm_scale_bar()

tm_shape(rnet_go_dutch) +
  tm_lines("go_dutch", lwd = "go_dutch", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() + tm_scale_bar() +
  tm_basemap(server = "https://npttile.vs.mythic-beasts.com/commute/v2/olc/{z}/{x}/{y}.png", )


####Is this section needed?###########

r_grouped_by_segment = left_join(r_grouped_by_segment, r_grouped %>% select())

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

rnet_phase1_godutch1 = overline2(r_phase1_cycle1, "cycle1_dutch_slc")

tm_shape(rnet_phase1_godutch1) +
  tm_lines("cycle1_dutch_slc", lwd = "cycle1_dutch_slc", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders()

# plot rail travel
r_phase1_rail = r_phase1 %>% select(AllMethods, Train, Bicycle, cycle1_baseline_slc, cycle1_dutch_slc) %>% 
  st_sf(geometry = r_phase1$geom_train) %>% 
  filter(!lengths(geometry) == 0)

class(r_phase1_rail)
class(r_phase1_rail$geometry)

r_phase1_rail = r_phase1_rail %>% st_zm() %>% st_cast("LINESTRING")
rnet_phase1_rail = overline2(r_phase1_rail, "Train")
rnet_phase1_rail = rmapshaper::ms_simplify(rnet_phase1_rail)
summary(rnet_phase1_rail$Train)

tm_shape(rnet_phase1_rail) +
  tm_lines("Train", lwd = "Train", scale = 9, palette = "plasma", breaks = c(0, 1000, 2000, 10000, 20000)) +
  tm_shape(region) + tm_borders() + tm_scale_bar()
