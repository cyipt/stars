# devtools::install_github("robinlovelace/ukboundaries")
# library(ukboundaries)
library(tidyverse)
library(tmap)
library(osmdata)
library(sf)
tmap_mode("view")

# get study region ----
# las = lad2018[grepl(pattern = "Luton|Bedford", lad2018$lau118nm), ]
# plot(las)
# las$lau118nm # 3 local authorities
# region = st_union(las)
# dir.create("output-data")
# write_sf(region, "output-data/region.geojson")
# write_sf(las, "output-data/las.geojson")
region = read_sf("output-data/region.geojson")
las = read_sf("output-data/las.geojson")

# # get rail stations in study region
# u_stations = "http://orr.gov.uk/__data/assets/excel_doc/0012/26130/estimates-of-station-usage-2016-17.xlsx"
# download.file(url = u_stations, destfile = "usage.xlsx")
# stns = readxl::read_excel("usage.xlsx", sheet = 3)
# stns = st_as_sf(stns, coords = c("OS Grid Easting", "OS Grid Northing")) %>% 
#   st_set_crs(27700) %>% 
#   st_transform(4326)
# stns = stns[region, ]
# write_sf(stns, "output-data/stns.geojson")
stns = read_sf("output-data/stns.geojson")
names(stns)
summary(stns$X1617.Entries...Exits)
stns_major = filter(stns, X1617.Entries...Exits > 1e6)
stns_minor = filter(stns, X1617.Entries...Exits < 1e6)

m = qtm(region, bbox = tmaptools::bb(region, ext = 1.5)) +
  tm_shape(stns_major) + tm_dots(size = "X1617.Entries...Exits", col = "red") +
  tm_shape(stns_major) + tm_text(text = "Station.Name") +
  tm_shape(stns_minor) + tm_dots() +
  tm_scale_bar() +
  tm_layout()
# Save result to figures...
dir.create("figures")
tmap_save(m, "figures/region-overview-stations.png")
tmap_save(m, "region-overview-stations.html")

