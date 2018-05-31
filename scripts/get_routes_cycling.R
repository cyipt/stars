# routes cycling
library(sf)
library(stplanr)
library(tmap)
tmap_mode("view")
library(cyclestreets)
library(dplyr)

lsoa.centroids = st_read("../cyipt-bigdata/centroids/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp")
lsoa.centroids = st_transform(lsoa.centroids, 27700)
lsoa.centroids = lsoa.centroids[,c("lsoa11cd")]

bounds = st_read("output-data/region.geojson")
bounds = st_transform(bounds,27700)
lsoa.centroids = lsoa.centroids[bounds,]

lsoa.centroids = st_transform(lsoa.centroids,4326)

stations =  st_read("output-data/stations_all.geojson")

point2coords <- function(x){
  lng = x[[1]][1]
  lat = x[[2]][1]
  res = c(lng,lat)
  return(res)
}

stations$coords <- lapply(stations$geometry, point2coords)
lsoa.centroids$coords <- lapply(lsoa.centroids$geometry, point2coords)
stations <- as.data.frame(stations[,c(1,3)])
lsoa.centroids <- as.data.frame(lsoa.centroids[,c(1,3)])

routes.all <- list()
k = 0
for(i in 1:nrow(stations)){
  station.sub = stations[i,]
  for(j in 1:nrow(lsoa.centroids)){
    k = k + 1
    lsoa.sub = lsoa.centroids[j,]
    message(paste0(Sys.time()," Routing from ",lsoa.sub$lsoa11cd, " to " ,station.sub$name, " station" ))
    
    route = journey(from = lsoa.sub$coords[[1]], to = station.sub$coords[[1]],
                    plan = "fastest",
                    base_url = "https://www.cyclestreets.net")
    
    route$from = lsoa.sub$lsoa11cd
    route$to = station.sub$name
    
    routes.all[[k]] = route
    
  }
}

routes <- routes.all[!is.na(routes.all)]
suppressWarnings(routes <- bind_rows(routes))
#rebuild the sf object
routes <- as.data.frame(routes)
routes$geometry <- st_sfc(routes$geometry)
routes <- st_sf(routes)
st_crs(routes) <- 4326

summary(st_is_valid(routes))

routes.group <- group_by(routes, from ,to ) %>%
                  summarise(distances = sum(distances),
                            time = sum(time),
                            busynance = sum(busynance))


saveRDS(routes,"../stars-data/routes_cycle_raw.Rds")
saveRDS(routes.group,"../stars-data/routes_cycle_grouped.Rds")


