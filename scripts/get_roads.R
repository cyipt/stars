# Downloa OSM Map of area
# modified from cyipt code

library(osmdata)
library(sf)

#Get Region
bounds = st_read("output-data/region.geojson")

#Download data
q = opq(st_bbox(bounds)) %>%
  add_osm_feature(key = "highway")
res = osmdata_sf(q = q)

#extract lines and points data
lines <- res$osm_lines
lines.loops <- res$osm_polygons
points <- res$osm_points
rm(res,q)

#Remove Factors
lines$osm_id <- as.numeric(as.character(lines$osm_id))
lines.loops$osm_id <- as.numeric(as.character(lines.loops$osm_id))
points$osm_id <- as.numeric(as.character(points$osm_id))

#remove the invalid polygons
lines.loops <- lines.loops[!is.na(lines.loops$highway),]
lines.loops <- lines.loops[is.na(lines.loops$area),]

#Channge Polygons to Lines
lines.loops <- st_cast(lines.loops, "LINESTRING")

# remove invalid geometry
lines <- lines[st_is_valid(lines) %in% TRUE,] # %in% TRUE handles NA that occure with empty geometries
lines.loops <- lines.loops[st_is_valid(lines.loops) %in% TRUE,]
points <- points[st_is_valid(points) %in% TRUE,]

#Bind togther
lines <- rbind(lines,lines.loops)
rm(lines.loops)

#CHange to British National Grid
lines <- st_transform(lines, 27700)
points <- st_transform(points, 27700)
bounds <- st_transform(bounds, 27700)


#Save out region boundary for reference
saveRDS(bounds,paste0("../stars-data/data/osm/bounds.Rds"))

#Download osm used a square bounding box, now trim to the exact boundry
#note that lines that that cross the boundary are still included

lines <- lines[bounds,]
points <- points[bounds,]

#now cut the lines to the boundary
lines <- st_intersection(bounds,lines)

#Save the lines
saveRDS(lines, paste0("../stars-data/data/osm/osm-lines.Rds"))

#Find Junctions, OSM Points are both nodes that make up lines/polygons, and objects e.g. shops
#remove points that are not nodes on the line
#node points have no tags
col.names <- names(points)[!names(points) %in% c("osm_id","highway", "crossing", "crossing_ref","geometry")] #Get column names other than osm_id, and highway which is just for junction types, and crossing info which can be junction between cycle way and road
points.sub <- points
points <- points[,c("osm_id","highway")]
points.sub <- as.data.frame(points.sub)
points.sub$geometry <- NULL
points.sub <- points.sub[,col.names]
rowsum <- as.integer(rowSums(!is.na(points.sub)))
rm(points.sub, col.names)
points <- points[rowsum == 0,] #Remove points with any tags

#now check highway tag to remove things like traffic lights
points <- points[is.na(points$highway) | points$highway %in% c("mini_roundabout","motorway_junction"), ]
points <- points[,c("osm_id","geometry")]

#Look for points that intersect lines
inter <- st_intersects(points,lines)
len <- lengths(inter)
points <- points[len >= 2,] #Only keep points that intersec at least 2 lines i.e. a junction

#Remove any duplicated points
points <- points[!duplicated(points$geometry),]


#Save results
saveRDS(points, paste0("../stars-data/data/osm/osm-junction-points.Rds"))