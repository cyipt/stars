library(sf)
library(dplyr)
library(transportAPI)


# merge missing routes to rest of routes

routes.missing = readRDS("../stars-data/data/routing/routes_train_missing.Rds")
routes.main = readRDS("../stars-data/data/routing/routes_train_final.Rds")

#bind
# routes.main <- routes.main[sapply(routes.main,function(x){class(x)[1]}) == "sf"] # (what is this? Robin)
# routes.main <- suppressWarnings(bind_rows(routes.main))
#rebuild the sf object
routes.main <- as.data.frame(routes.main)
routes.main$geometry <- st_sfc(routes.main$geometry)
routes.main <- st_sf(routes.main)
st_crs(routes.main) <- 4326

routes.missing <- routes.missing[sapply(routes.missing,function(x){class(x)[1]}) == "sf"]
routes.missing <- suppressWarnings(bind_rows(routes.missing))
#rebuild the sf object
routes.missing <- as.data.frame(routes.missing)
routes.missing$geometry <- st_sfc(routes.missing$geometry)
routes.missing <- st_sf(routes.missing)
st_crs(routes.missing) <- 4326


# quick check
names(routes.missing) == names(routes.main)
routes.missing = routes.missing[,names(routes.main)]
names(routes.missing) == names(routes.main)

routes.merge = rbind(routes.main, routes.missing)

#check we have them all
flow = readRDS("../stars-data/data/flow/flows_aggregatedCycleroutes.Rds")
flow = flow[flow$Train_AllSexes_Age16Plus >0,]
flow = flow[,c("Area of usual residence","Area of Workplace","AllMethods_AllSexes_Age16Plus","Train_AllSexes_Age16Plus")]
flow$id = paste0(flow$`Area of usual residence`," ",flow$`Area of Workplace`)
routes.merge$id = paste0(routes.merge$fromid," ",routes.merge$toid)

missing_flows = flow[!(flow$id %in% routes.merge$id),]

#Failing as O and D the same?
missing_flows = missing_flows[missing_flows$`Area of usual residence` != missing_flows$`Area of Workplace`,]
tab = as.data.frame(table(c(missing_flows$`Area of usual residence`,missing_flows$`Area of Workplace`)))


lsoa.centroids = st_read("../cyipt-bigdata/centroids/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp")
lsoa.centroids = st_transform(lsoa.centroids, 27700)
lsoa.centroids = lsoa.centroids[,c("lsoa11cd")]

flow.points = missing_flows[,1:2]
flow.points = as.data.frame(flow.points)
flow.points = flow.points[,1:2]
names(flow.points) = c("fromLSOA","toLSOA")
flow.points = left_join(flow.points, lsoa.centroids, by = c("fromLSOA" = "lsoa11cd"))
flow.points = left_join(flow.points, lsoa.centroids, by = c("toLSOA" = "lsoa11cd"))
names(flow.points) = c("fromLSOA","toLSOA","fromgeometry","togeometry")
flow.points = st_sf(flow.points)
flow.points$fromgeometry <- st_transform(flow.points$fromgeometry, 4326)
flow.points$togeometry <- st_transform(flow.points$togeometry, 4326)

# Failing as unable to match lsoa centroid to road network
# Tweak locations
flow.points$fromgeometry[flow.points$fromLSOA == "E01017451"] = st_point(c(-0.580901, 51.989662))
flow.points$togeometry[flow.points$toLSOA == "E01017451"] = st_point(c(-0.580901, 51.989662))
flow.points$fromgeometry[flow.points$fromLSOA == "E01017442"] = st_point(c(-0.317658, 52.003481))
flow.points$togeometry[flow.points$toLSOA == "E01017442"] = st_point(c(-0.317658, 52.003481))
flow.points$fromgeometry[flow.points$fromLSOA == "E01001516"]



#Find the next week day
date = Sys.Date() + 1
if(weekdays(date) == "Saturday"){
  date = date + 2
}else if(weekdays(date) == "Sunday"){
  date = date + 1
}
date = as.character(date)


# Get data and manage rate limit
# work in batches of 10

flow.points$done <- FALSE
flow.points$id <- 1:nrow(flow.points)
flow.points$OD = paste0(flow.points$fromLSOA," ",flow.points$toLSOA)
routes.all <- list()

# Assume neither option has failed in over an hour
fail.key <- Sys.time() - 3700
fail.fcc <- Sys.time() - 3700

for(i in 1:100000){
  # Periodically save results
  if(i %% 10 == 0){
    saveRDS(routes.all,"./stars-data/data/routing/routes_train_missing2_tmp.Rds")
    saveRDS(flow.points,"../stars-data/flow_points_missing2_tmp.Rds")
  }
  
  # Get the next routes to do
  flow.sub = flow.points[!flow.points$done,]
  if(nrow(flow.sub) == 0){
    message(paste0(Sys.time()," Finished out of flows to do"))
    break
  }else{
    flow.sub = flow.sub[1,]
    flow.id = flow.sub$id
  }
  
  message(paste0(Sys.time()," Attempt ",i," on route ",flow.id))
  #Find the next week day
  date = Sys.Date() + 1
  if(weekdays(date) == "Saturday"){
    date = date + 2
  }else if(weekdays(date) == "Sunday"){
    date = date + 1
  }
  date = as.character(date)
  
  
  #decide what to do
  
  if(fail.key < (Sys.time() - 3600)){
    message(paste0(Sys.time()," routing using key"))
    # Route using key
    routes = journey(from = flow.sub$fromgeometry, 
                     to = flow.sub$togeometry,
                     date = date, 
                     time = "09:00", 
                     type = "by", 
                     apitype = "public")
    
    if("character" %in% class(routes) ){
      #error has occured
      if(grepl("usage limits are exceeded",routes)){
        message(paste0(Sys.time()," Rate limit cap detected for keybased API"))
        fail.key <- Sys.time()
      }else{
        message(paste0(Sys.time()," ERRROR: Other error has occured, skipping"))
        flow.points$done[flow.id] <- TRUE # for now skip routes with errors
      }
    }else{
      routes$fromid = flow.sub$fromLSOA[1]
      routes$toid = flow.sub$toLSOA[1]
      routes.all[[flow.id]] = routes
      flow.points$done[flow.id] <- TRUE
    }
    
  }else if(fail.fcc < (Sys.time() - 3600)){
    message(paste0(Sys.time()," routing using fcc"))
    # route using fcc
    routes = journey(from = flow.sub$fromgeometry, 
                     to = flow.sub$togeometry,
                     date = date,
                     base_url = "http://fcc.transportapi.com/",
                     time = "09:00", 
                     type = "by", 
                     apitype = "public")
    
    if("character" %in% class(routes) ){
      #error has occured
      if(grepl("Authorisation failed",routes)){
        message(paste0(Sys.time()," Rate limit cap detected for FCC API"))
        fail.fcc <- Sys.time()
      }else{
        message(paste0(Sys.time()," ERRROR: Other error has occured"))
        flow.points$done[flow.id] <- TRUE # for now skip routes with errors
      }
    }else{
      routes$fromid = flow.sub$fromLSOA[1]
      routes$toid = flow.sub$toLSOA[1]
      routes.all[[flow.id]] = routes
      flow.points$done[flow.id] <- TRUE
    }
    
  }else{
    # Sleep for an hour
    message(paste0(Sys.time()," sleeping for an hour"))
    Sys.sleep(3600)
  }
  rm(routes,flow.sub,flow.id)
}

routes.all <- routes.all[sapply(routes.all,function(x){class(x)[1]}) == "sf"]
routes.all <- suppressWarnings(bind_rows(routes.all))
#rebuild the sf object
routes.all <- as.data.frame(routes.all)
routes.all$geometry <- st_sfc(routes.all$geometry)
routes.all <- st_sf(routes.all)
st_crs(routes.all) <- 4326
routes.all$id = paste0(routes.all$fromid," ",routes.all$toid)

routes.all = routes.all[,names(routes.merge)]
routes.merge = rbind(routes.merge, routes.all)

saveRDS(routes.merge, "./stars-data/data/routing/routes_train_completed.Rds")

# Select best option for each route

# Filter only the fastes route
routes.fastest = routes.merge
routes.fastest$dur = as.numeric(lubridate::as.duration(lubridate::hms(routes.fastest$route_duration)), "mins")
routes.fastest.summary = as.data.frame(routes.fastest[,c("id","route_option","dur","mode")])
routes.fastest.summary = routes.fastest.summary %>% 
                            group_by(id,route_option) %>% 
                            summarise(duration = sum(dur),
                                      duration_train = sum(dur[mode == "train"]))

#check for routes that are faster but slower on the train
routes.fastest.summary$fast = sapply(1:nrow(routes.fastest.summary),function(x){min(routes.fastest.summary$duration[routes.fastest.summary$id == routes.fastest.summary$id[x]])})
routes.fastest.summary$fast_train = sapply(1:nrow(routes.fastest.summary),function(x){min(routes.fastest.summary$duration_train[routes.fastest.summary$id == routes.fastest.summary$id[x]])})

routes.fastest.summary$fast_check = routes.fastest.summary$fast == routes.fastest.summary$duration
routes.fastest.summary$fast_train_check = routes.fastest.summary$fast_train == routes.fastest.summary$duration_train
routes.fastest.summary$both_check = routes.fastest.summary$fast_check == routes.fastest.summary$fast_train_check
foo = routes.fastest.summary[!(!routes.fastest.summary$fast_check & !routes.fastest.summary$fast_train_check),]

routes.fastest.summary = routes.fastest.summary[routes.fastest.summary$duration == routes.fastest.summary$fast,]
routes.fastest.summary$check = TRUE
routes.fastest.summary = routes.fastest.summary[,c("id","route_option","check")]




routes.fastest = dplyr::left_join(routes.fastest, routes.fastest.summary, by = c("id" = "id","route_option" = "route_option"))
routes.fastest = routes.fastest[!is.na(routes.fastest$check),]
rm(routes.fastest.summary)

# now check for duplicated routes with the same duration
dupe.check = as.data.frame(routes.fastest[,c("id","route_option","route_stage")])
dupe.check$geometry = NULL
dupe.check$check = sapply(1:nrow(dupe.check), function(x){dupe.check$route_option[x] == min(dupe.check$route_option[dupe.check$id == dupe.check$id[x]])})

routes.fastest = routes.fastest[dupe.check$check,]

#routes.fastest$fast = sapply(1:nrow(routes.fastest),function(x){min(routes.fastest$dur[routes.fastest$id == routes.fastest$id[i]])})

#routes.fastest = routes.fastest[routes.fastest$dur == routes.fastest$fast,]
saveRDS(routes.fastest, "./stars-data/data/routing/routes_train_fastest.Rds")
