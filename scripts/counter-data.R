# Run this after combined.R
if(!exists("rnet_combined")){
  source("scripts/combined.R")
}
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
  summarise(across(latitude:longitude, mean, na.rm = TRUE)) %>% 
  filter(!is.na(longitude))

d_roads_sf = sf::st_as_sf(d_roads_sf, coords = c("longitude", "latitude"), crs = 4326)
d_roads_luton = d_roads_sf[region_luton, ]
d_roads_luton_all = d_roads %>%
  filter(count_point_id %in% d_roads_luton$count_point_id)


# top roads
d_roads_luton_all %>% 
  filter(estimation_method == "Counted") %>% 
  group_by(road_name) %>% 
  summarise(n = sum(pedal_cycles)) %>% 
  top_n(6, wt = n)

roads_of_interest = c(
  "A505",
  "A5228",
  "A6",
  "B579"
)

d_roads_luton_all %>% 
  ggplot() +
  geom_line(aes(year, pedal_cycles, group = count_point_id), colour = "grey")

d_roadss = d_roads_luton_all %>% 
  group_by(road_name, year) %>% 
  summarise(across(pedal_cycles:all_motor_vehicles, mean))
  # geom_line(aes(year, all_motor_vehicles, colour = count_point_id), data = d_las_of_interest, size = 1.2)

d_roadss %>% 
  ggplot() +
  geom_line(aes(year, pedal_cycles, group = road_name, colour = road_name)) +
  geom_smooth(aes(year, pedal_cycles), size = 3, fill = NA) 

summary(d_roads_luton_all$pedal_cycles)

s = 2010:2014
e = 2015:2019

d_roads_luton_summary = d_roads_luton_all %>%
  filter(pedal_cycles > 0) %>% 
  filter(year >= 2010) %>% 
  filter(estimation_method == "Counted") %>% 
  group_by(count_point_id) %>% 
  summarise(
    n_counters = n(),
    nstart = sum(year %in% s),
    nend = sum(year %in% e),
    road_name = first(road_name),
    road_type = first(road_type),
    total_cycling = sum(pedal_cycles),
    mean_cycling = mean(pedal_cycles),
    mean_motor_vehicles = mean(all_motor_vehicles),
    change_motor_vehicles = (mean(all_motor_vehicles[year %in% e], na.rm = TRUE) / mean(all_motor_vehicles[year %in% s], na.rm = TRUE) - 1) * 100,
    change_cycling = (mean(pedal_cycles[year %in% e], na.rm = TRUE) / mean(pedal_cycles[year %in% s], na.rm = TRUE) - 1) * 100
  ) %>% 
  filter(!is.na(change_cycling))

d_roads_luton_summary
table(d_roads_luton_all$estimation_method)
summary(d_roads_luton_summary$change_cycling)
summary(d_roads_luton_summary$n_counters)
summary(d_roads_luton_summary$change_motor_vehicles)
d_roads_joined = left_join(d_roads_luton, d_roads_luton_summary)
nrow(d_roads_joined)
plot(d_roads_joined)

d_roads_joined$n_counters[is.na(d_roads_joined$n_counters)] = 1
qtm(d_roads_joined, dots.size = "n_counters")

tm_shape(d_roads_joined %>% filter(nstart > 1, nend > 1)) +
  tm_dots(size = "total_cycling", col = "change_cycling", palette = "RdBu", midpoint = 0, breaks = c(-100, -50, 0, 50, 100))
# max(d_roads_joined$total_cycling, na.rm = TRUE)

d_roads_averaged = d_roads_luton_all %>% 
  group_by(road_name) %>% 
  mutate(
    total_cycling = sum(pedal_cycles),
    # across(pedal_cycles:cars_and_taxis, .fns = function(x) x / mean(x))
    ) %>% 
  group_by(road_name, year) %>% 
  summarise(pedal_cycles = weighted.mean(pedal_cycles, total_cycling), total_cycling = mean(total_cycling)) %>% 
  ungroup()

d_roads_averaged %>% 
  ggplot() +
  geom_path(aes(year, pedal_cycles, size = total_cycling, group = road_name), alpha = 0.3, linejoin = "mitre") +
  geom_smooth(aes(year, pedal_cycles, weight = total_cycling))


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
