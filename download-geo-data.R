devtools::install_github("robinlovelace/ukboundaries")
library(ukboundaries)
library(tmap)
tmap_mode("view")
las = lad2018[grepl(pattern = "Luton|Bedford", lad2018$lau118nm), ]
plot(las)
las$lau118nm # 3 local authorities
region = st_union(las)
dir.create("output-data")
write_sf(region, "output-data/region.geojson")
qtm(region) + tm_scale_bar()
