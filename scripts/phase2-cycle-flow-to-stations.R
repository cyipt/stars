# Aim: generate first principles estimates of cycling to stations potential based on the PCT
library(tidyverse)
library(tmap)
library(sf)
library(stplanr)
tmap_mode("view")

region = read_sf("output-data/region.geojson")

stns = sf::read_sf("output-data/stns.geojson") %>% st_transform(27700)
mainline = c("Luton Airport Parkway", "Luton", "Leagrave", "Harlington", "Flitwick", "Bedford Midland", "Leighton Buzzard", "Arlesey", "Biggleswade", "Sandy")
s = filter(stns, Station.Name %in% mainline)
s$Station.Name = gsub(pattern = "Luton Airport Parkway", replacement = "Luton Airport", x = s$Station.Name)
s = s %>% 
  select(station_name = Station.Name, entries_exits = X1617.Entries...Exits )

sf::st_write(s, "../stars-data/data/local-survey/stns-mainline-orr-entries.geojson", delete_dsn = T)
######

z = pct::get_pct_zones("bedfordshire", geography = "lsoa") %>% st_transform(27700)
c = pct::get_pct_centroids("bedfordshire", geography = "lsoa") %>% st_transform(27700)
summary(z$geo_code == c$geo_code)
z = z[match(c$geo_code, z$geo_code), ]
summary(z$geo_code == c$geo_code)

qtm(z) + qtm(c)

names(s)

#######

od = z %>% st_drop_geometry() %>% select(geo_code, train_tube, all)

####Trying to workaround stplanr bug#######
s = st_as_sf(as.data.frame(s))

mapview::mapview(c)
mapview::mapview(s)

odex = expand.grid(geo_code = c$geo_code, station_used = s$station_name)
odex_line = od2line(flow = odex, as(c, "Spatial"), as(s, "Spatial")) %>%
  sf::st_as_sf()
plot(odex_line)

odex_line$geo_code = as.character(odex_line$geo_code) 
# Otherwise it would be coerced to character when performing left_join. But should they both be factors instead?
odex_line = left_join(odex_line, od, by = "geo_code")

odex_line$distance_crow = sf::st_length(odex_line) # calculate distance (m)
odex_line$distance_crow = as.numeric(odex_line$distance_crow) / 1000

names(odex_line)[3] = "rail"

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

l_short$id = as.character(1:nrow(l_short))
plot(l_short)


# l_short = l_short[1:20, ] # for testing, uncomment when done for real!

##Change the projection for cyclestreets
l_short_longlat = l_short %>% st_transform(4326)

r_all_short = route(l = l_short_longlat, route_fun = cyclestreets::journey)
dim(r_all_short)
mapview::mapview(r_all_short)
summary(r_all_short)
head(r_all_short$id)

r_all_short$busyness = r_all_short$busynance / r_all_short$distances

# r_all_short$elev_change = abs(diff(r_all_short$elevations))

plot(r_all_short$distances, r_all_short$busynance)
# busynance is simply distance times busyness
plot(r_all_short$distances * r_all_short$busyness, r_all_short$busynance)

###find route distance by road######
r_aggregated = r_all_short %>% 
  group_by(id) %>% 
  summarise(
    distance_road = sum(distances),
    max_busynance = max(busynance),
    average_busyness = sum(busynance)/sum(distances),
    average_incline = sum(abs(diff(elevations))) / sum(distances)
    #, max_incline = max(abs(diff(elevations))/distances[1])
  )

plot(r_aggregated)
summary(r_aggregated)

# r_aggregated$id == l_short$id
l_short_df = l_short %>%
  st_drop_geometry()
r_joined = inner_join(r_aggregated, l_short_df)

plot(r_joined$distance_crow, r_joined$distance_road)


###select only routes that are nearest by road###
r_nearest_by_road = r_joined %>%
  group_by(geo_code) %>%
  dplyr::filter(distance_road == min(distance_road))

r_nearest_by_road = st_as_sf(as.data.frame(r_nearest_by_road))

mapview::mapview(r_joined %>% filter(geo_code == "E01015719"))
mapview::mapview(l_short %>% filter(geo_code == "E01015719"))
mapview::mapview(r_nearest_by_road %>% filter(geo_code == "E01015719"))

# length(unique(r_all_short$geo_code))
# length(r_nearest_by_road$geo_code) # to check the number of geo_codes remains the same

mapview::mapview(r_nearest_by_road)
mapview::mapview(r_all_short)


####Filter the route segments to select only those that are part of routes to stations nearest by road 
r_all_selected = r_all_short %>%
  filter(id %in% r_nearest_by_road$id)

tm_shape(r_all_selected) + tm_lines("busynance")
tm_shape(r_all_selected) + tm_lines("busyness")
saveRDS(r_all_selected, "../stars-data/data/routing/phaseII-route-segments-nearest-station.Rds")


# plot(r_all_selected$distances, r_all_selected$busynance)
# # busynance is simply distance times busyness
# plot(r_all_selected$distances * r_all_selected$busyness, r_all_selected$busynance)



#######Route networks and grouping by segment

# rnet = overline2(r_all_selected, "rail")

r_grouped_by_segment = r_all_selected %>% 
  group_by(name, distances, busynance, busyness) %>% ##may need to add more columns in to this line
  summarise(n = n(), rail = sum(rail))


####

#Are these three lines necessary?
r_grouped_by_segment$rail[r_grouped_by_segment$rail > 1000] = 1000 # This just makes the line widths on the busyness and all journey tmaps easier to read - they show more detail away from stations
# r_grouped_linestring = r_grouped_by_segment %>% st_cast("LINESTRING")
# rnet_segment = overline(r_grouped_linestring, "all")

#Map busyness of route segments
png(filename = "./figures/bedford-busyness.png", height = 1000, width = 700)
tmap_mode("plot")
tm_shape(r_grouped_by_segment) +
  tm_lines("busyness", lwd = "rail", scale = 9, palette = "plasma", breaks = c(0, 1, 2, 3, 5, 10, 25)) +
  tm_shape(region) + tm_borders()
dev.off()
# tmap_save(.Last.value, "./figures/bedford-busyness.png")

#Map total number of journeys to stations on each route segment
png(filename = "./figures/bedford-rnet-all-phase2.png", height = 1000, width = 700)
tmap_mode("view")
tm_shape(r_grouped_by_segment) +
  tm_lines("rail", lwd = "rail", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() +
  tm_scale_bar()
dev.off()


##Create estimates for the Go Dutch scenario
r_nearest_by_road$go_dutch = pct::uptake_pct_godutch(distance = r_nearest_by_road$distance_road, gradient = r_nearest_by_road$average_incline) * r_nearest_by_road$rail

saveRDS(r_nearest_by_road, "../stars-data/data/routing/phaseII-routes-nearest-station.Rds")


r_grouped_lines = r_nearest_by_road %>% st_cast("LINESTRING") # Is this the best approach or should we be using `r_all_selected` with inner_join instead?
rnet_go_dutch = overline2(r_grouped_lines, "go_dutch")

# ###Testing
# rnet_all_rail = overline2(r_grouped_lines, "rail")
# tm_shape(rnet_all_rail) +
#   tm_lines("rail", lwd = "rail", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
#   tm_shape(region) + tm_borders() + tm_scale_bar()
# ###

#Map modelled Go Dutch cycle journeys to stations
tm_shape(rnet_go_dutch) +
  tm_lines("go_dutch", lwd = "go_dutch", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() + tm_scale_bar()

tm_shape(rnet_go_dutch) +
  tm_lines("go_dutch", lwd = "go_dutch", scale = 9, palette = "plasma", breaks = c(0, 10, 200, 500, 1000)) +
  tm_shape(region) + tm_borders() + tm_scale_bar() +
  tm_basemap(server = "https://npttile.vs.mythic-beasts.com/commute/v2/olc/{z}/{x}/{y}.png", )




#########Counting the number of journeys to each station#######
phase2flow = r_nearest_by_road %>% 
  group_by(station_used) %>%
  summarise(rail = sum(rail),
            go_dutch = sum(go_dutch)) %>%
  rename(station = station_used,phase_2_all_rail = rail,phase_2_go_dutch = go_dutch)

phase2flow = as.data.frame(phase2flow)
phase2flow = phase2flow[,c(1,2,3)]
phase2flow$phase_2_go_dutch = round(phase2flow$phase_2_go_dutch)
phase2flow$station = as.character(phase2flow$station)

phase2flow$station = gsub(pattern = "Bedford Midland", replacement = "Bedford", x = phase2flow$station)
phase2flow$station = gsub("Luton Airport", "Luton Airport Parkway", phase2flow$station)

write_csv(phase2flow[,c(1,2,3)],"./figures/phase2flow.csv")

phase1flow = readRDS("../stars-data/data/station_flow_estimates.Rds") %>%
  rename(phase_1_all_rail = Train_in, phase_1_go_dutch = Dutch_in)


compare_phases = left_join(phase2flow, phase1flow, by = "station")

compare_phases = compare_phases %>%
  mutate(diff_all_rail = round(phase_1_all_rail/phase_2_all_rail,2),
         diff_go_dutch = round(phase_1_go_dutch/phase_2_go_dutch,2),
         takeup_phase_1 = round(phase_1_go_dutch/phase_1_all_rail,2),
         takeup_phase_2 = round(phase_2_go_dutch/phase_2_all_rail,2),)

compare_phases[is.na(compare_phases)] = 0
phase1flow[is.na(phase1flow)] = 0


s_counts_all = compare_phases[,c(1,2,5,16)] %>%
  select(1,3,2,4)
s_counts_all 

write_csv(s_counts_all, "../stars-data/data/flow/s_counts_all.csv")


s_counts_dutch = compare_phases[,c(1,3,7,18:19)] %>%
  select(1,3,2,4,5)
s_counts_dutch 

write_csv(s_counts_dutch, "../stars-data/data/flow/s_counts_dutch.csv")



######Grouped bar charts

takeup = gather(compare_phases[,c(1,2,3,5,7)], `phase_1_go_dutch`, `phase_2_go_dutch`,`phase_1_all_rail`, `phase_2_all_rail`, key = "phase", value = "trips")

takeup$type = substr(takeup$phase, 9,str_length(takeup$phase))
takeup$phase = substr(takeup$phase, 1,7)

library(RColorBrewer)

# ggplot(takeup, aes(fill=type, y=trips, x=station)) +
#   geom_bar(position="stack", stat="identity") +
#   theme_minimal() 


ggplot(data=takeup, aes(x=phase, y=trips, fill=type)) + 
  geom_bar(stat="identity",position = "dodge") + 
  facet_grid(~station) +
  theme_gray() + 
  theme(axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y.left = element_text(size = 11)) +
  scale_fill_brewer(palette = "Dark2")



########Counting total rail journeys#######

sum(z$train_tube)

p1_pc = round(sum(phase1flow$phase_1_go_dutch)/sum(z$train_tube)*100)
p1_10_pc = round(sum(compare_phases$phase_1_all_rail)/sum(z$train_tube)*100)
p2_pc = round(sum(compare_phases$phase_2_all_rail)/sum(z$train_tube)*100)

p1 = c(sum(phase1flow$phase_1_all_rail),p1_pc)
p1_10 = c(sum(compare_phases$phase_1_all_rail),p1_10_pc)
p2 = c(sum(compare_phases$phase_2_all_rail),p2_pc)
c_2011 = c(sum(z$train_tube),100)

totals = data.frame(p1,p1_10,p2,c_2011, row.names = c("Total journeys","% accounted for"))
colnames(totals) = c("Phase1(all_stations)","Phase1(ten_stations)","Phase2(ten_stations)","Census2011")
totals

write_csv(totals, "../stars-data/data/flow/totals.csv")


p1dt = round(sum(phase1flow$phase_1_go_dutch)/sum(phase1flow$phase_1_all_rail)*100)
p1dt_10 = round(sum(compare_phases$phase_1_go_dutch)/sum(compare_phases$phase_1_all_rail)*100)
p2dt = round(sum(compare_phases$phase_2_go_dutch)/sum(compare_phases$phase_2_all_rail)*100)

p1d = c(round(sum(phase1flow$phase_1_go_dutch)),p1dt)
p1d_10 = c(sum(compare_phases$phase_1_go_dutch),p1dt_10)
p2d = c(sum(compare_phases$phase_2_go_dutch),p2dt)

totals_dutch = data.frame(p1d,p1d_10,p2d, row.names = c("Go Dutch journeys cycled","% takeup"))
colnames(totals_dutch) = c("Phase1(all_stations)","Phase1(ten_stations)","Phase2(ten_stations)")
totals_dutch

write_csv(totals_dutch, "../stars-data/data/flow/totals_dutch.csv")

# sum(phase1flow$phase_1_all_rail)/sum(compare_phases$phase_2_all_rail)
# sum(compare_phases$phase_1_all_rail)/sum(compare_phases$phase_2_all_rail)
sum(compare_phases$phase_1_go_dutch)/sum(compare_phases$phase_2_go_dutch)
sum(compare_phases$phase_2_all_rail)/sum(compare_phases$AllMethods_in)

####Cycle racks per station

existing = read_csv("../stars-data/data/orr/cycle-spaces-updated.csv") %>%
  rename(station = Station)

racks = inner_join(s_counts_dutch,existing)
racks = racks %>% select(station, Cycle_spaces, phase_1_go_dutch, phase_2_go_dutch)
racks

write_csv(racks,"./output-data/racks.csv")

racks = read_csv("./output-data/racks.csv")

spaces = gather(racks, `Cycle spaces`, `Phase 1 Go Dutch`,`Phase 2 Go Dutch`, key = "phase", value = "spaces")
# spaces = gsub("Cycle spaces", "Current provision",spaces)

ggplot(data=spaces, aes(x=Station, y=spaces, fill=phase)) + 
  geom_bar(stat="identity",position = "dodge") + 
  theme_gray() + 
  theme(axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y.left = element_text(size = 11),
        axis.text.x = element_text(angle = 90)) +
  scale_fill_brewer(palette = "Dark2")



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
