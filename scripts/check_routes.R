library(sf)
library(dplyr)
library(tmap)
tmap_mode("view")

routes = readRDS("../stars-data/routes_train_final.Rds")
routes <- routes[sapply(routes,function(x){class(x)[1]}) == "sf"]
suppressWarnings(routes <- bind_rows(routes))
#rebuild the sf object
routes <- as.data.frame(routes)
routes$geometry <- st_sfc(routes$geometry)
routes <- st_sf(routes)
st_crs(routes) <- 4326
head(routes)
routes = routes[!is.na(routes$mode),]
routes = routes[,c("route_duration","route_departure_time", "route_departure_date", "route_arrival_time","route_arrival_date","request_time",
                  "mode","line_name","duration","departure_time","arrival_time","route_option","route_stage",
                  "fromid","toid")]

stations =  st_read("output-data/stations_all.geojson")
bounds = st_read("output-data/region.geojson")

qtm(bounds) +
qtm(routes[7000:7427,], lines.col = "mode", lines.lwd = 3) +
  qtm(stations)


# subset to a single option for each route
routes.single = routes[routes$route_option == 1,]

# for each route  idetify the station entry point
route_ids = unique(paste0(routes.single$fromid," ",routes.single$toid))


get_station = function(i, entry = TRUE){
  rt = route_ids[i]
  rt = strsplit(rt," ")[[1]]
  frm = rt[1]
  to = rt[2]
  rts = routes.single[routes.single$fromid == frm,]
  rts = rts[rts$toid == to,]
  #qtm(rts, lines.col = "mode", lines.lwd = 3)
  rts = rts[rts$mode == "train",]
  if(nrow(rts) > 0){
    # not get first point of the line
    geom = rts$geometry[1]
    geom = as.matrix(geom[[1]])
    if(entry){
      geom = geom[1,]
    }else{
      geom = geom[nrow(geom),]
    }
    #geom = st_point(geom)
    return(geom)
  }else if(nrow(rts) == 0){
    #not travelling by train
    return(NA)
  }else{
    message(paste0("arrgh",i))
    stop()
  }
  
}

#Get Entry Stopos
stops_entrys = lapply(1:length(route_ids), get_station, entry = TRUE)
stops_entrys_na = is.na(stops_entrys)
stops_entrys = stops_entrys[!stops_entrys_na]
stops_entrys_ids = route_ids[!stops_entrys_na]
stops_entrys = do.call("rbind",stops_entrys)
stops_entrys = as.data.frame(stops_entrys)
names(stops_entrys) = c("lng","lat")
stops_entrys$id = stops_entrys_ids
stops_entrys = st_as_sf(stops_entrys, coords= c("lng","lat"))
st_crs(stops_entrys) = 4326
rm(stops_entrys_na)

#get exit stops
stops_exits = lapply(1:length(route_ids), get_station, entry = FALSE)
stops_exits_na = is.na(stops_exits)
stops_exits = stops_exits[!stops_exits_na]
stops_exits_ids = route_ids[!stops_exits_na]
stops_exits = do.call("rbind",stops_exits)
stops_exits = as.data.frame(stops_exits)
names(stops_exits) = c("lng","lat")
stops_exits$id = stops_exits_ids
stops_exits = st_as_sf(stops_exits, coords= c("lng","lat"))
st_crs(stops_exits) = 4326
rm(stops_exits_na)

# Find unique entry and edits

stops_entrys_unique = stops_entrys[!duplicated(stops_entrys$geometry),]
stops_exits_unique = stops_exits[!duplicated(stops_exits$geometry),]
stops_unique = rbind(stops_entrys_unique,stops_exits_unique)
stops_unique = stops_unique[!duplicated(stops_unique$geometry),]
rm(stops_entrys_unique, stops_exits_unique)
stops_unique$stop_id = 1:nrow(stops_unique)

stops_entrys$entry_stop_id = stops_unique$stop_id[match(stops_entrys$geometry, stops_unique$geometry)]
stops_exits$exit_stop_id = stops_unique$stop_id[match(stops_exits$geometry, stops_unique$geometry)]

stops_all = data.frame(route_id = route_ids)
stops_all = dplyr::left_join(stops_all, stops_entrys, by = c("route_id" = "id"))
stops_all = dplyr::left_join(stops_all, stops_exits, by = c("route_id" = "id"))
stops_all$geometry.x = NULL
stops_all$geometry.y = NULL

stops_unique$id = NULL
saveRDS(stops_all,"../stars-data/routes2stationIDs.Rds")
saveRDS(stops_unique,"../stars-data/routes_stations.Rds")

#match the stations from transportAPI with those used for cyclestreets
stations =  st_read("output-data/stations_all.geojson")

stations = st_transform(stations, 27700)
stops_unique = st_transform(stops_unique, 27700)

distances = st_distance(stops_unique, stations)
class(distances) <- "numeric"
nrow(distances)
ncol(distances)
rownames(distances) = stops_unique$stop_id
colnames(distances) = stations$name

# for each unique stop match to a station
closest_station = list()
for(i in 1:nrow(distances)){
  dist = distances[i,]
  mini = min(dist)
  if(mini > 500){
    nm = "None"
  }else{
    nm = names(dist)[dist == min(dist)]
  }
  closest_station[[i]] = nm
}
closest_station = unlist(closest_station)

stops_unique$closest_station = closest_station

tm_shape(stops_unique) +
  tm_symbols(size = 0.001, col = "closest_station")

saveRDS(stops_unique,"../stars-data/routes_stations_matched.Rds")
#qtm(stops_entrys)
