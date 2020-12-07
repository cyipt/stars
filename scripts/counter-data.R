# Run this after combined.R
# source("scripts/combined.R")

remotes::install_github("itsleeds/dftTrafficCounts")
library(dftTrafficCounts)

d_las = dtc_import_la()
d_luton = d_las %>% 
  filter(local_authority_name == "Luton")

d_las = d_las %>% 
  group_by(local_authority_name) %>% 
  mutate(
    relative_traffic = all_motor_vehicles / link_length_km 
  )

las_of_interest = unique(zones$lad_name)
d_las_of_interest = d_las %>%
  filter(local_authority_name %in% las_of_interest)
d_las %>% 
  ggplot() +
  geom_line(aes(year, all_motor_vehicles, group = local_authority_name), colour = "grey") +
  geom_line(aes(year, all_motor_vehicles, colour = local_authority_name), data = d_las_of_interest, size = 1.2)

d_las %>% 
  ggplot() +
  geom_line(aes(year, relative_traffic, group = local_authority_name), colour = "grey") +
  geom_line(aes(year, relative_traffic, colour = local_authority_name), data = d_las_of_interest, size = 1.2) +
  theme(legend.position = "top")

d_change = d_las_of_interest %>% 
  group_by(local_authority_name) %>% 
  summarise(
    network_length_km = round(mean(link_length_km)),
    change_2011 = round(max(all_motor_vehicles) / all_motor_vehicles[year == 2011], digits = 3)
    )


d_roads = dftTrafficCounts::dtc_import_roads()
d_roads_luton = d_roads %>% 
  filter(local_authority_name == "Luton")

d_roads_sf = d_roads %>%
  group_by(count_point_id) %>%
  summarise(across(latitude:longitude, mean, na.rm = TRUE))

d_roads_sf = sf::st_as_sf(d_roads_sf, coords = c("longitude", "latitude"), crs = 4326)
d_roads_luton = d_roads_sf[region_luton, ]
d_roads_luton_all = d_roads %>%
  filter(count_point_id %in% d_roads_luton$count_point_id)

d_roads_of_interest = c(
  "81081"
)

d_roads_luton_all %>% 
  ggplot() +
  geom_line(aes(year, pedal_cycles, group = count_point_id), colour = "grey")
+
  # geom_line(aes(year, all_motor_vehicles, colour = count_point_id), data = d_las_of_interest, size = 1.2)

summary(d_roads_luton_all$pedal_cycles)

s = 2010:2014
e = 2015:2019

d_roads_luton_summary = d_roads_luton_all %>%
  filter(pedal_cycles > 0) %>% 
  group_by(count_point_id) %>% 
  summarise(
    road_name = first(road_name),
    road_type = first(road_type),
    mean_cycling = mean(pedal_cycles),
    mean_motor_vehicles = mean(all_motor_vehicles),
    change_motor_vehicles = ((mean(all_motor_vehicles[year %in% s]) / (all_motor_vehicles[year %in% e])) - 1) * 100,
    change_cycling = ((mean(pedal_cycles[year %in% s]) / (pedal_cycles[year %in% e])) - 1) * 100
  )

d_roads_luton_summary
summary(d_roads_luton_summary$change_cycling)
summary(d_roads_luton_summary$change_motor_vehicles)
d_roads_joined = left_join(d_roads_luton, d_roads_luton_summary)
nrow(d_roads_joined)
plot(d_roads_joined)

qtm(d_roads_joined)

tm_shape(d_roads_joined) +
  tm_dots(size = "mean_cycling", col = "change_cycling", palette = "RdBu", midpoint = 0)

# d_roads = dftTrafficCounts::dtc_import_roads()
# names(d_roads)
# 
# 
# d_roads_luton_summary = d_roads_luton_all %>% 
#   group_by(count_point_id) %>% 
#   summarise(
#     road_name = first(road_name),
#     road_type = first(road_type),
#     mean_cycling = mean(pedal_cycles),
#     mean_motor_vehicles = mean(all_motor_vehicles),
#     change_cycling = pedal_cycles[year = 2019] / pedal_cycles[year = 2011],
#     change_motor_vehicles = all_motor_vehicles[year = 2019] / all_motor_vehicles[year = 2011]
#   )
# nrow(d_roads_luton)
# mapview::mapview(d_roads_luton)
