# Batch get routes
devtools::install_github("mem48/transportAPI")
library(sf)
library(stplanr)
library(tmap)
tmap_mode("view")
library(transportAPI)
library(dplyr)

# Define Study Area
lsoa = st_read("../cyipt-bigdata/boundaries/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Generalised_Clipped__Boundaries_in_England_and_Wales.shp")
lsoa = st_transform(lsoa,27700)
bounds = st_read("output-data/region.geojson")
bounds = st_transform(bounds,27700)
lsoa.bounds = lsoa[bounds,]
rm(lsoa, bounds)


flow = readr::read_csv("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/LSOA/WM12EW[CT0489]_lsoa/WM12EW[CT0489]_lsoa.csv")
flow = flow[flow$`Area of usual residence` %in% lsoa.bounds$lsoa11cd | flow$`Area of Workplace` %in% lsoa.bounds$lsoa11cd,]
flow$`Area Name` = NULL
flow$`Area of Workplace name` = NULL

lsoa.centroids = st_read("../cyipt-bigdata/centroids/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp")
lsoa.centroids = st_transform(lsoa.centroids, 27700)
lsoa.centroids = lsoa.centroids[,c("lsoa11cd")]

exclude = c("N92000002","OD0000001", "OD0000002", "OD0000004", "S92000003", "W01000011", "W01000332", "W01000386", "W01001340", "W01001862", "W01001939", "OD0000003")
flow = flow[!flow$`Area of usual residence` %in% exclude & !flow$`Area of Workplace` %in% exclude,]

flow = flow[order(-flow$Train_AllSexes_Age16Plus),]
saveRDS(flow, "../stars-data/flows2011.Rds")

#Subset only the routes by train
flow.train = flow[flow$Train_AllSexes_Age16Plus >0,]


flow.points = flow.train[,1:2]
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
    saveRDS(routes.all,"../stars-data/routes_train_tmp.Rds")
    saveRDS(flow.points,"../stars-data/flow_points_tmp.Rds")
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

saveRDS(routes.all,"../stars-data/routes_train.Rds")
