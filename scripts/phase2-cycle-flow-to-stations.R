# Aim: generate first principles estimates of cycling to stations potential based on the PCT
library(tidyverse)
library(tmap)
library(sf)
tmap_mode("view")

s = sf::read_sf("../stars-data/data/local-survey/stns-mainline-orr-entries.geojson")
z = sf::read_sf("../stars-data/data/zones-nearest-station.geojson")
c = pct::get_pct_centroids(region = "bedfordshire", geography = "lsoa")
summary(z$geo_code == c$geo_code)

qtm(z) + qtm(c)

names(s)


od = z %>% st_drop_geometry() %>% select(geo_code, nearest_station, train_tube, all) 

####Trying to workaround stplanr bug#######
s = st_as_sf(as.data.frame(s))

mapview::mapview(c)
mapview::mapview(s)

odex2 = expand.grid(o = c$geo_code, d = s$station_name)
odex2$flow = 1
odex_line = od2line(flow = odex2, as(c, "Spatial"), as(s, "Spatial")) %>%
  sf::st_as_sf()
plot(odex_line)

###Previous attempt uses odex and l_ex###but might still need centroids_ex

# odex = left_join(odex, od[,-2], by = "geo_code")
# stations_duplicated_ex = s[match(odex$nearest_station, s$station_name), ]
# centroids_ex = sf::st_sf(odex, geometry = c$geometry)
# 
# #####
# 
# 
# origin_coordinates_ex = st_coordinates(centroids_ex)
# dest_coordinates_ex = st_coordinates(stations_duplicated_ex)
# odc_ex = cbind(origin_coordinates_ex,dest_coordinates_ex)
# 
# l_ex = stplanr::od_coords2line(odc_ex)
# 
# ##is this where things went wrong? should it have been an inner join?
# l_ex$all = centroids_ex$all
# l_ex$rail = centroids_ex$train_tube
# l_ex$nearest_station = centroids_ex$nearest_station
# l_ex$geo_code = centroids_ex$geo_code
# l_ex$distance_crow = sf::st_length(l_ex) # calculate distance (m)
# l_ex$distance_crow = as.numeric(l_ex$distance_crow) / 1000

####Latest attempt uses odex_line
odex_line = left_join(odex_line, od[,-2], by = c("o" = "geo_code"))

odex_line$distance_crow = sf::st_length(odex_line) # calculate distance (m)
odex_line$distance_crow = as.numeric(odex_line$distance_crow) / 1000

##these names might want changing esp 'nearest_station' which is not correct. Do we really need flow?
names(odex_line)[1:4] = c("geo_code", "nearest_station", "flow", "rail")

###Removing all desire lines longer than 5km
l_short = filter(odex_line, distance_crow < 5) # change to increase max

l_short = l_short %>% 
  group_by(geo_code) %>% 
  mutate(
    n_stations_near = n(),
    distance_crow_nearest = min(distance_crow),
    distance_crow_ratio = distance_crow / distance_crow_nearest
    ) %>% 
  ungroup()

summary(l_short$distance_crow_ratio) # mean is a ratio of 1.7

###Removing all desire lines where the distance to the station is more than 1.5x the distance to the nearest station
l_short = l_short %>% 
  filter(distance_crow_ratio < 1.5)

summary(l_short$distance_crow_ratio) # mean is a ratio of 1.05

stations_duplicated_short = s[match(l_short$nearest_station, s$station_name), ]

l_short$id = as.character(1:nrow(l_short))
plot(l_short)


#r_ex = stplanr::route_cyclestreet(origin_coordinates_ex[1, ], to = dest_coordinates_ex[1, ])
#plot(r_ex)

library(stplanr)
# l_short = l_short[1:20, ] # for testing, uncomment when done for real!
r_all_short = route(l = l_short, route_fun = cyclestreets::journey)
# r_all_short = route(l = l_short, route_fun = cyclestreets::journey)
dim(r_all_short)
mapview::mapview(r_all_short)
summary(r_all_short)
head(r_all_short$id)

###find route distance by road######

r_aggregated = r_all_short %>% 
  group_by(id) %>% 
  summarise(
    distance_road = sum(distances) / 1000,
    average_busynance = mean(busynance),
    max_busynance = max(busynance)
  )

plot(r_aggregated)
summary(r_aggregated)

# r_aggregated$id == l_short$id
l_short_df = l_short %>%
  st_drop_geometry()
r_joined = inner_join(r_aggregated, l_short_df)
# plot(r_joined)
plot(r_joined$distance_crow, r_joined$distance_road)
mapview::mapview(r_joined %>% filter(geo_code == "E01015720"))
mapview::mapview(l_short %>% filter(geo_code == "E01015720"))

###select only routes that are nearest by road###
r_nearest_by_road = r_joined %>%
  group_by(geo_code) %>%
  dplyr::filter(distance_road == min(distance_road))

mapview::mapview(r_nearest_by_road %>% filter(geo_code == "E01015719"))

# length(unique(r_all_short$geo_code))
# length(r_nearest_by_road$geo_code))

plot(r_all_short[,20])
plot(r_nearest_by_road[,5])

mapview::mapview(r_nearest_by_road)
mapview::mapview(r_all_short)

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
  group_by(name, distances, busynance) %>% ##will probably need to add more columns in to this line
  summarise(n = n(), all = sum(rail), busyness = mean(quietness))


####

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
