# transport data - pct method

library(tidyverse)
library(pct)
library(sf)

od = get_od()
od

msoa_centroids = get_centroids_ew()

bedfordshire = pct_regions %>% 
  filter(region_name == "bedfordshire")

mapview::mapview(bedfordshire)
msoa_bedfordshire = msoa_centroids[bedfordshire, ]
mapview::mapview(msoa_bedfordshire)

od_in_bedfordshire = od %>% 
  filter(geo_code1 %in% msoa_bedfordshire$msoa11cd) %>% 
  filter(geo_code2 %in% msoa_bedfordshire$msoa11cd) # todo: remove intrazonal flows

summary(od_in_bedfordshire)

desire_lines = stplanr::od2line(flow = od_in_bedfordshire, msoa_bedfordshire)

mapview::mapview(desire_lines)


desire_lines_car_heavy = desire_lines %>% 
  filter(car_driver > 100)

mapview::mapview(desire_lines_car_heavy)

routes_car_heavy = stplanr::line2route(desire_lines_car_heavy)
mapview::mapview(routes_car_heavy) # why did some fail???
mapview::mapview(routes_car_heavy[209, ]) # intrazonal flows...

routes_car_heavy_with_data = st_drop_geometry(desire_lines_car_heavy)
routes_car_heavy_with_data = st_as_sf(routes_car_heavy_with_data, geometry = routes_car_heavy$geometry)

mapview::mapview(routes_car_heavy_with_data, zcol = "car_driver")

rnet = stplanr::overline2(x = routes_car_heavy_with_data, attrib = "car_driver")

mapview::mapview(rnet, zcol = "car_driver")
