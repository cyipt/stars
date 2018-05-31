# get Stations
library(osmdata)
library(sf)

#Get Region
bounds = st_read("output-data/region.geojson")
bounds_buff = st_transform(bounds, 27700)
bounds_buff = st_buffer(bounds_buff, 5000)
bounds_buff = st_transform(bounds_buff, 4326)

#Download data
q = opq(st_bbox(bounds_buff)) %>%
  add_osm_feature(key = "railway", value = "station")
res = osmdata_sf(q = q)



#extract lines and points data
points <- res$osm_points
points <- points[!is.na(points$name),]
points = points[,"name"]
pols = res$osm_polygons
pols = st_centroid(pols)
pols = pols[,"name"]
points = rbind(points,pols)
points = points[!duplicated(points$name),]
rownames(points) = 1:nrow(points)
points = st_transform(points, 27700)

points = points[!points$name %in% c("Caldecotte Minature Railway","Miniature Train","Stonehenge Works","Page's Park"),]

#qtm(bounds) +
  qtm(points)

points = st_transform(points, 4326)

#Save out region boundary for reference
st_write(points,"output-data/stations_all.geojson", delete_dsn=TRUE)
