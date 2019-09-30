# for each route get the cycling part
library(sf)
library(dplyr)
library(tmap)
library(RANN)
tmap_mode("view")


routes = readRDS("../stars-data/data/routing/routes_train_fastest.Rds")
routes = routes[,c("id","route_duration","route_departure_time", "route_departure_date", 
                   "route_arrival_time","route_arrival_date","mode","from_point_name",
                   "to_point_name","destination","departure_time","arrival_time",
                   "route_option","route_stage")]

routes.cycle = readRDS("../stars-data/data/routing/routes_cycle_grouped2.Rds")
routes.cycle = st_transform(routes.cycle, 27700)
routes.cycle$from = as.character(routes.cycle$from)
routes.cycle$to = as.character(routes.cycle$to)
#stations = readRDS("../stars-data/routes_stations_matched.Rds")
stations = st_read("output-data/stations_all.geojson")
stations = st_transform(stations, 27700)
stations$idx = 1:nrow(stations)
#routes2stations = readRDS("../stars-data/routes2stationIDs.Rds")

# Find train start and end points
# Rout routes have mulitple legs on the train so simplify to single lines in the DF

routes.train = routes[routes$mode == "train",]
routes.train = routes.train[,c("id","from_point_name","to_point_name","route_option","geometry")]
duplicate.check = routes.train$id[duplicated(routes.train$id)]
routes.train.single =  routes.train[!routes.train$id %in% duplicate.check,]
routes.train.multi =  routes.train[routes.train$id %in% duplicate.check,]
routes.train.multi = routes.train.multi %>%
  group_by(id, route_option) %>%
  summarise(from_point_name = from_point_name[1],
            to_point_name = to_point_name[length(to_point_name)])
routes.train.multi = routes.train.multi[,c("id","from_point_name","to_point_name","route_option","geometry")]
routes.train = rbind(routes.train.single,routes.train.multi)

routes.train$from_lsoa = substr(routes.train$id,1,9)
routes.train$to_lsoa = substr(routes.train$id,11,19)
rm(routes.train.multi, routes.train.single)

# get flow data
flow = readRDS("../stars-data/data/routing/flows2011.Rds")
cols2keep = names(flow)
cols2keep = cols2keep[grepl("AllSexes_Age16Plus",cols2keep)]
cols2keep = c("Area of usual residence","Area of Workplace",cols2keep)
flow = flow[,cols2keep]
flow$route_id = paste0(flow$`Area of usual residence`," ",flow$`Area of Workplace`)
names(flow) = c("from","to","AllMethods","WorkAtHome",
                "Underground","Train","Bus","Taxi",
                "Motorcycle",  "CarOrVan","Passenger","Bicycle"  ,  
                "OnFoot","OtherMethod", "route_id")

routes.cycle = as.data.frame(routes.cycle)
routes.train = as.data.frame(routes.train)
routes.train = left_join(routes.train,
                          data.frame(lsoa = routes.cycle$from, station = routes.cycle$to, cycle1_length = routes.cycle$length, cycle1_av_incline = routes.cycle$av_incline, cycle_geom_1 = routes.cycle$geometry, stringsAsFactors = F),
                          by = c("from_lsoa" = "lsoa", "from_point_name" = "station"))
names(routes.train) = c("id","from_point_name","to_point_name","route_option","geom_train","from_lsoa","to_lsoa","cycle1_length","cycle1_av_incline","geom_cycle1")
routes.train = left_join(routes.train,
                         data.frame(lsoa = routes.cycle$from, station = routes.cycle$to, cycle2_length = routes.cycle$length, cycle2_av_incline = routes.cycle$av_incline, cycle_geom_2 = routes.cycle$geometry, stringsAsFactors = F),
                         by = c("to_lsoa" = "lsoa", "to_point_name" = "station"))
names(routes.train) = c("id","from_point_name","to_point_name","route_option","geom_train","from_lsoa","to_lsoa","cycle1_length","cycle1_av_incline","geom_cycle1","cycle2_length","cycle2_av_incline", "geom_cycle2")

routes.train$check = ifelse(lengths(routes.train$geom_cycle1) > 0 | lengths(routes.train$geom_cycle2) > 0,TRUE,FALSE)

routes.final = left_join(routes.train, flow, by = c("id" = "route_id"))

saveRDS(routes.final,"../stars-data/routes_combined.Rds")
summary(routes.train$check) # some route missing where star/end outside the zone and/or go to a station outside the zone

# Summarise the Routes and add up the flows

routes.to    = routes.final[lengths(routes.final$geom_cycle1) != 0 & lengths(routes.final$geom_cycle2) == 0,]
routes.from  = routes.final[lengths(routes.final$geom_cycle1) == 0 & lengths(routes.final$geom_cycle2) != 0,]
routes.both  = routes.final[lengths(routes.final$geom_cycle1) != 0 & lengths(routes.final$geom_cycle2) != 0,]

routes.to   =   routes.to[,c("id","from_lsoa","from_point_name","AllMethods","Train","CarOrVan","Bicycle")]
routes.from = routes.from[,c("id","to_point_name","to_lsoa","AllMethods","Train","CarOrVan","Bicycle")]
routes.both.to = routes.both[,c("id","from_lsoa","from_point_name","AllMethods","Train","CarOrVan","Bicycle")]
routes.both.from = routes.both[,c("id","to_point_name","to_lsoa","AllMethods","Train","CarOrVan","Bicycle")]

routes.to = rbind(routes.to, routes.both.to)
routes.from = rbind(routes.from, routes.both.from)


routes.to.summary = routes.to %>%
  group_by(from_lsoa,from_point_name) %>%
  summarise(AllMethods = sum(AllMethods),
            Train = sum(Train),
            CarOrVan = sum(CarOrVan),
            Bicycle = sum(Bicycle)
            )

routes.from.summary = routes.from %>%
  group_by(to_lsoa,to_point_name) %>%
  summarise(AllMethods = sum(AllMethods),
            Train = sum(Train),
            CarOrVan = sum(CarOrVan),
            Bicycle = sum(Bicycle)
  )

routes.combined = rbind(routes.to.summary,routes.from.summary)
routes.combined.summary = routes.combined %>%
  group_by(from_lsoa,from_point_name) %>%
  summarise(AllMethods = sum(AllMethods),
            Train = sum(Train),
            CarOrVan = sum(CarOrVan),
            Bicycle = sum(Bicycle)
  )

routes.combined.summary = left_join(routes.combined.summary, routes.cycle, by = c("from_lsoa" = "from", "from_point_name" = "to"))
routes.combined.summary = st_sf(routes.combined.summary)
routes.combined.summary = routes.combined.summary[!is.na(routes.combined.summary$from_lsoa),]

qtm(routes.combined.summary, lines.col = "Train")
saveRDS(routes.combined.summary,"../stars-data/cycle_to_station_routes.Rds")

# ### Checks
# unique(routes.train$from_lsoa)[!unique(routes.train$from_lsoa) %in% routes.cycle$from]
# 
# 
# 
# 
# 
# # line2point = function(x,type){
# #   sub = routes.train$geometry[[x]]
# #   if(type == "start"){
# #     row = 1
# #   }else if(type == "end"){
# #     row = nrow(sub)
# #   }else{
# #     message("No Type")
# #     stop()
# #   }
# #   
# #   sub1 = sub[row,1]
# #   sub2 = sub[row,2]
# #   
# #   geom = st_point(c(sub1,sub2))
# #   return(geom)
# # }
# 
# 
# # routes.train$fromgeometry = lapply(1:nrow(routes.train),line2point, type = "start")
# # routes.train$fromgeometry = st_sfc(routes.train$fromgeometry)
# # routes.train$togeometry = lapply(1:nrow(routes.train),line2point, type = "end")
# # routes.train$togeometry = st_sfc(routes.train$togeometry)
# #routes.train$fromgeotext = st_as_text(routes.train$fromgeometry)
# #routes.train$togeotext = st_as_text(routes.train$togeometry)
# 
# 
# #FIn the unique start and end points of train jounreys
# # sometimes stations have more than one entry point
# 
# route.points = c(routes.train$fromgeometry, routes.train$togeometry)
# route.points = unique(route.points)
# route.points = st_sf(data.frame(id = 1:length(route.points), geometry = st_sfc(route.points)))
# st_crs(route.points) = 4326
# route.points = st_transform(route.points, 27700)
# route.points$geotext = st_as_text(route.points$geometry)
# route.pointsgeom = as.data.frame(st_coordinates(route.points))
# route.points$X = route.pointsgeom$X
# route.points$Y = route.pointsgeom$Y
# route.points = as.data.frame(route.points)
# route.points = route.points[,c("id","geotext","X","Y")]
# rm(route.pointsgeom)
# 
# #names(route.points) = c("entry_stop","geotext")
# #routes.train = left_join(routes.train, as.data.frame(route.points), by = c("fromgeotext" = "geotext"))
# #names(route.points) = c("exit_stop","geotext")
# #routes.train = left_join(routes.train, as.data.frame(route.points), by = c("togeotext" = "geotext"))
# 
# 
# # names(route.points) = c("stop_id","geotext")
# # route.points$geotext = st_as_sfc(route.points$geotext)
# # route.points = st_sf(route.points)
# # 
# # 
# # st_crs(route.points) = 27700
# 
# # match points to station
# stationsgeometry = as.data.frame(st_coordinates(stations))
# stations$X = stationsgeometry$X
# stations$Y = stationsgeometry$Y
# rm(stationsgeometry)
# 
# #stations.sub = as.data.frame(stations[,c("X","Y")])
# #stations.sub$geometry = NULL
# #route.points.sub = route.points[,c("X","Y")]
# #route.points.sub$geotext = NULL
# 
# 
# near = nn2(data.frame(X = stations$X, Y = stations$Y), data.frame(X = route.points$X, Y = route.points$Y), k = 1)
# near.idx = near$nn.idx[,1]
# near.dist = near$nn.dists[,1]
# rm(near, near.dist, near.idx)
# 
# route.points$idx = near.idx
# route.points$dis = round(near.dist,1)
# 
# route.points$idx[route.points$dis > 500] = NA # If over 500m away then a bad match so exclude
# 
# #make lookup between stop names and routes
# route.points = left_join(route.points, data.frame(idx = stations$idx, name = stations$name), by = c("idx"))
# df.tmp = data.frame(idx = route.points$idx, name = route.points$name)
# df.tmp = df.tmp[!is.na(df.tmp$idx),]
# routes.cycle = left_join(routes.cycle, df.tmp, by = c("to" = "name"))
# rm(df.tmp)
# 
# routes.train$from_lsoa = substr(routes.train$id,1,9)
# routes.train$to_lsoa = substr(routes.train$id,11,19)
# 
# routes.train2 = left_join(routes.train, 
#                          data.frame(from_lsoa = routes.cycle$from, to_station = routes.cycle$to, route_cycle_from = routes.cycle$geometry),
#                          by = c("from_lsoa" = "from_lsoa", "from_point_name" = "to_station"))
# 
# 
# # stations.sub = as.data.frame(stations[,c("idx","name")])
# # stations.sub$geometry = NULL
# # names(stations.sub) = c("stop_id","entry_stop")
# 
# 
# 
# 
# 
# 
# 
# stop()
# 
# # qtm(foo[foo$idx == 1,]) +
# #   qtm(stations[1,], dots.col = "red")
# 
# 
# qtm(route.points[,]) +
#   qtm(stations, dots.col = "red")
# 
# #make lookup between stop names and routes
# # stations = as.data.frame(stations)
# # stations$geometry = NULL
# # names(stations) = c("stop_id","entry_stop")
# # routes2stations = left_join(routes2stations, stations, by = c("entry_stop_id" = "stop_id"))
# # names(stations) = c("stop_id","exit_stop")
# # routes2stations = left_join(routes2stations, stations, by = c("exit_stop_id" = "stop_id"))
# 
# 
# # some missing routes to do
# 
# routes.cycle$cycle_id = 1:nrow(routes.cycle)
# 
# flow = left_join(flow, routes2stations, by = c("route_id") )
# flow$entry_stop_id = NULL
# flow$exit_stop_id = NULL
# flow = left_join(flow, routes.cycle, by = c("from" = "from", "entry_stop" = "to") )
# flow = left_join(flow, routes.cycle, by = c("to" = "from", "exit_stop" = "to") )
# names(flow) = c("from","to","AllMethods",  "WorkAtHome",  "Underground", "Train","Bus","Taxi","Motorcycle",  "CarOrVan",
# "Passenger","Bicycle","OnFoot","OtherMethod", "route_id","entry_stop",  "exit_stop","distances_entry", "time_entry","busynance_entry",
#  "geometry_entry", "cycle_id_entry" , "distances_exit", "time_exit","busynance_exit", "geometry_exit", "cycle_id_exit" )
# 
# saveRDS(flow,"../stars-data/flows_withCycleroutes.Rds")
# 
# #Group toghter flows that have idential geometries
# #flow.grouped = st_union(flow$geometry_entry[1:10000], flow$geometry_exit[1:10000], by_feature = TRUE)
# 
# group_flows = function(i){
#   geometry_entry = flow$geometry_entry[i]
#   geometry_exit = flow$geometry_exit[i]
#   df = data.frame(id = i)
#   # checks
#   if(st_is_empty(geometry_entry)){ 
#     if(st_is_empty(geometry_exit)){
#       df$geometry = geometry_exit
#     }else{
#       df$geometry = geometry_exit
#     }
#   }else{
#     if(st_is_empty(geometry_exit)){
#       df$geometry = geometry_entry
#     }else{
#       geometry_untion = st_union(geometry_entry,geometry_exit)
#       df$geometry = geometry_untion
#     }
#   }
#   return(df)
# }
# 
# flow.grouped = lapply(1:nrow(flow), group_flows)
# 
# 
# flow.grouped2 = bind_rows(flow.grouped)
# 
# #rebuild the sf object
# rownames(flow.grouped2) = 1:nrow(flow.grouped2)
# flow.grouped2 <- as.data.frame(flow.grouped2)
# flow.grouped2$geometry <- st_sfc(flow.grouped2$geometry)
# flow.grouped2 <- st_sf(flow.grouped2)
# st_crs(flow.grouped2) <- 27700
# 
# flow.grouped = flow
# flow.grouped$geometry_union = flow.grouped2$geometry
# flow.grouped = flow.grouped[,c("from","to","AllMethods","Train",
#                                "distances_entry", "time_entry","busynance_entry", "cycle_id_entry",  "distances_exit",  "time_exit" ,     
#                                "busynance_exit","cycle_id_exit","geometry_union")]
# 
# flow.grouped = st_sf(flow.grouped)
# flow.grouped.unique = flow.grouped[,c("cycle_id_entry","cycle_id_exit")]
# flow.grouped.unique = unique(flow.grouped.unique)
# 
# flow.grouped = as.data.frame(flow.grouped)
# flow.grouped = flow.grouped %>%
#                 group_by(cycle_id_entry,cycle_id_exit) %>%
#                   summarise(AllMethods = sum(AllMethods),
#                             Train = sum(Train),
#                             time = sum(c(time_entry,time_exit), na.rm = T ),
#                             distance = sum(c(distances_entry,distances_exit), na.rm = T ),
#                             busyance = sum(c(busynance_entry,busynance_exit), na.rm = T )
#                             
#                             )
# 
# flow.grouped = left_join(flow.grouped, flow.grouped.unique, by = c("cycle_id_entry","cycle_id_exit"))
# flow.grouped = st_sf(flow.grouped)
# 
# 
# saveRDS(flow.grouped,"../stars-data/flows_aggregatedCycleroutes.Rds")
# 
# flow.grouped_lines = flow.grouped[st_geometry_type(flow.grouped) == "MULTILINESTRING",]
# flow.grouped_other = flow.grouped[st_geometry_type(flow.grouped) != "MULTILINESTRING",]
# 
# #qtm(flow.grouped_other)
# 
# qtm(flow.grouped_lines, lines.lwd = 3, lines.col = "Train")

