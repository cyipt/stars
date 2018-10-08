# Get missing routes
devtools::install_github("mem48/transportAPI")
library(sf)
library(stplanr)
library(tmap)
tmap_mode("view")
library(transportAPI)
library(dplyr)

flow = readRDS("../stars-data/flows2011.Rds")
flow = flow[flow$Train_AllSexes_Age16Plus >0,]
flow = flow[,c("Area of usual residence","Area of Workplace","AllMethods_AllSexes_Age16Plus","Train_AllSexes_Age16Plus")]
flow$id = paste0(flow$`Area of usual residence`," ",flow$`Area of Workplace`)

routes = readRDS("../stars-data/routes_train_final.Rds")
routes <- routes[sapply(routes,function(x){class(x)[1]}) == "sf"]
suppressWarnings(routes <- bind_rows(routes))
#rebuild the sf object
routes <- as.data.frame(routes)
routes$geometry <- st_sfc(routes$geometry)
routes <- st_sf(routes)
st_crs(routes) <- 4326

routes$id = paste0(routes$fromid," ",routes$toid)

missing_flows = flow[!(flow$id %in% routes$id),]

lsoa.centroids = st_read("../cyipt-bigdata/centroids/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp")
lsoa.centroids = st_transform(lsoa.centroids, 27700)
lsoa.centroids = lsoa.centroids[,c("lsoa11cd")]


flow.points = missing_flows[,1:2]
flow.points = as.data.frame(flow.points)
flow.points = flow.points[,1:2]
names(flow.points) = c("fromLSOA","toLSOA")
head(flow.points)
flow.points = left_join(flow.points, lsoa.centroids, by = c("fromLSOA" = "lsoa11cd"))
flow.points = left_join(flow.points, lsoa.centroids, by = c("toLSOA" = "lsoa11cd"))
head(flow.points)
names(flow.points) = c("fromLSOA","toLSOA","fromgeometry","togeometry")
flow.points = st_sf(flow.points)
flow.points$fromgeometry <- st_transform(flow.points$fromgeometry, 4326)
flow.points$togeometry <- st_transform(flow.points$togeometry, 4326)
head(flow.points)


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
    saveRDS(routes.all,"../stars-data/routes_train_missing_tmp.Rds")
    saveRDS(flow.points,"../stars-data/flow_points_missing_tmp.Rds")
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

saveRDS(routes.all,"../stars-data/routes_train_missing.Rds")

