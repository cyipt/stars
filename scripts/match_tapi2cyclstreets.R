# for each route get the cycling part
library(sf)
library(dplyr)

routes = readRDS("../stars-data/routes_train_final.Rds")
routes <- routes[sapply(routes,function(x){class(x)[1]}) == "sf"]
suppressWarnings(routes <- bind_rows(routes))
#rebuild the sf object
rownames(routes) = 1:nrow(rownames)
routes <- as.data.frame(routes)
routes$geometry <- st_sfc(routes$geometry)
routes <- st_sf(routes)
st_crs(routes) <- 4326
head(routes)
routes = routes[!is.na(routes$mode),]
routes = routes[,c("route_duration","route_departure_time", "route_departure_date", "route_arrival_time","route_arrival_date","request_time",
                   "mode","line_name","duration","departure_time","arrival_time","route_option","route_stage",
                   "fromid","toid")]

#just one option per route
routes = routes[routes$route_option == 1,]
routes.cycle = readRDS("../stars-data/routes_cycle_grouped.Rds")
routes.cycle = st_transform(routes.cycle, 27700)
stations = readRDS("../stars-data/routes_stations_matched.Rds")
routes2stations = readRDS("../stars-data/routes2stationIDs.Rds")

#make lookup between stop names and routes
stations = as.data.frame(stations)
stations$geometry = NULL
names(stations) = c("stop_id","entry_stop")
routes2stations = left_join(routes2stations, stations, by = c("entry_stop_id" = "stop_id"))
names(stations) = c("stop_id","exit_stop")
routes2stations = left_join(routes2stations, stations, by = c("exit_stop_id" = "stop_id"))

# get flow data
flow = readRDS("../stars-data/flows2011.Rds")
cols2keep = names(flow)
cols2keep = cols2keep[grepl("AllSexes_Age16Plus",cols2keep)]
cols2keep = c("Area of usual residence","Area of Workplace",cols2keep)
flow = flow[,cols2keep]
flow$route_id = paste0(flow$`Area of usual residence`," ",flow$`Area of Workplace`)
names(flow) = c("from","to","AllMethods","WorkAtHome",
                "Underground","Train","Bus","Taxi",
                "Motorcycle",  "CarOrVan","Passenger","Bicycle"  ,  
                "OnFoot","OtherMethod", "route_id")


routes$route_id = paste0(routes$fromid," ",routes$toid)
# some missing routes to do

routes.cycle$cycle_id = 1:nrow(routes.cycle)

flow = left_join(flow, routes2stations, by = c("route_id") )
flow$entry_stop_id = NULL
flow$exit_stop_id = NULL
flow = left_join(flow, routes.cycle, by = c("from" = "from", "entry_stop" = "to") )
flow = left_join(flow, routes.cycle, by = c("to" = "from", "exit_stop" = "to") )
names(flow) = c("from","to","AllMethods",  "WorkAtHome",  "Underground", "Train","Bus","Taxi","Motorcycle",  "CarOrVan",
"Passenger","Bicycle","OnFoot","OtherMethod", "route_id","entry_stop",  "exit_stop","distances_entry", "time_entry","busynance_entry",
 "geometry_entry", "cycle_id_entry" , "distances_exit", "time_exit","busynance_exit", "geometry_exit", "cycle_id_exit" )

saveRDS(flow,"../stars-data/flows_withCycleroutes.Rds")

#Group toghter flows that have idential geometries
#flow.grouped = st_union(flow$geometry_entry[1:10000], flow$geometry_exit[1:10000], by_feature = TRUE)

group_flows = function(i){
  geometry_entry = flow$geometry_entry[i]
  geometry_exit = flow$geometry_exit[i]
  df = data.frame(id = i)
  # checks
  if(st_is_empty(geometry_entry)){ 
    if(st_is_empty(geometry_exit)){
      df$geometry = geometry_exit
    }else{
      df$geometry = geometry_exit
    }
  }else{
    if(st_is_empty(geometry_exit)){
      df$geometry = geometry_entry
    }else{
      geometry_untion = st_union(geometry_entry,geometry_exit)
      df$geometry = geometry_untion
    }
  }
  return(df)
}

flow.grouped = lapply(1:nrow(flow), group_flows)


flow.grouped2 = bind_rows(flow.grouped)

#rebuild the sf object
rownames(flow.grouped2) = 1:nrow(flow.grouped2)
flow.grouped2 <- as.data.frame(flow.grouped2)
flow.grouped2$geometry <- st_sfc(flow.grouped2$geometry)
flow.grouped2 <- st_sf(flow.grouped2)
st_crs(flow.grouped2) <- 27700

flow.grouped = flow
flow.grouped$geometry_union = flow.grouped2$geometry
flow.grouped = flow.grouped[,c("from","to","AllMethods","Train",
                               "distances_entry", "time_entry","busynance_entry", "cycle_id_entry",  "distances_exit",  "time_exit" ,     
                               "busynance_exit","cycle_id_exit","geometry_union")]

flow.grouped = st_sf(flow.grouped)
flow.grouped.unique = flow.grouped[,c("cycle_id_entry","cycle_id_exit")]
flow.grouped.unique = unique(flow.grouped.unique)

flow.grouped = as.data.frame(flow.grouped)
flow.grouped = flow.grouped %>%
                group_by(cycle_id_entry,cycle_id_exit) %>%
                  summarise(AllMethods = sum(AllMethods),
                            Train = sum(Train),
                            time = sum(c(time_entry,time_exit), na.rm = T ),
                            distance = sum(c(distances_entry,distances_exit), na.rm = T ),
                            busyance = sum(c(busynance_entry,busynance_exit), na.rm = T )
                            
                            )

flow.grouped = left_join(flow.grouped, flow.grouped.unique, by = c("cycle_id_entry","cycle_id_exit"))
flow.grouped = st_sf(flow.grouped)


saveRDS(flow.grouped,"../stars-data/flows_aggregatedCycleroutes.Rds")

flow.grouped_lines = flow.grouped[st_geometry_type(flow.grouped) == "MULTILINESTRING",]
flow.grouped_other = flow.grouped[st_geometry_type(flow.grouped) != "MULTILINESTRING",]


qtm(flow.grouped_lines, lines.lwd = 3, lines.col = "Train")

