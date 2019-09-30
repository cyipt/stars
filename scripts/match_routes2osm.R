library(sf)
library(dplyr)
library(parallel)
source("../stars/scripts/functions.R")


# functions
find.pct.lines <- function(i){
  #message(i)
  pct_sub <- pct.all[i,]
  pct_id <- pct_sub$ID[1]
  grid_ids <- grid_pct2grid[[i]]
  osm_ids <- unique(unlist(grid_grid2osm[grid_ids]))
  osm_sub <- osm[osm_ids,]
  res <- roadsOnLine(roads = osm_sub, line2check =  pct_sub$geometry, tolerance = 4)
  return(res)
}

#get pct row numbers for a given osm row number
getpctids <- function(y){
  return(seq_along(pct2osm)[sapply(seq_along(pct2osm),function(x){y %in% pct2osm[[x]]})])
}

#get pct values for a given osm row number
getpctvalues <- function(i){
  pct.sub <- pct.all[osm2pct[[i]],]
  count <- data.frame(id = i,
                      All = sum(pct.sub$all, na.rm = T),
                      Baseline = sum(pct.sub$baseline, na.rm = T),
                      Dutch = sum(pct.sub$dutch, na.rm = T),
                      Ebikes = sum(pct.sub$ebike, na.rm = T))
  return(count)
}

#FUnction to Splitlines
splitlines <- function(a){
  line_sub <- osm[a,]
  buff_sub <- buff[inter[[a]],]
  if(nrow(buff_sub) == 0){
    line_cut <- line_sub
  }else{
    buff_sub <- st_union(buff_sub)
    line_cut <- st_difference(line_sub, buff_sub)
  }
  line_cut<- st_cast(line_cut, "LINESTRING") #needed for new bind_rows() call
  return(line_cut)
}



# match the routes to osm
osm = readRDS("../stars-data/data/osm/osm-lines.Rds")
osm = st_transform(osm, 27700)
osm = osm[,c("osm_id","name", "cycleway","cycleway.both","cycleway.est_width",
             "cycleway.left","cycleway.oneside","cycleway.oneside.width","cycleway.right",
             "junction","lanes","lanes.backward","lanes.forward",
             "lanes.left","lanes.psv","lanes.psv.backward","maxspeed")]

points <- readRDS(paste0("../stars-data/data/osm/osm-junction-points.Rds"))

#Loop To Split Lines
buff <- st_buffer(points,0.01, nQuadSegs = 2)
inter <- st_intersects(osm,buff)
cut_list <- lapply(1:nrow(osm), splitlines)

cut <- bind_rows(cut_list) #much faster than rbind but mangle the sf format, all geometies must be same type
rm(cut_list)

#rebuild the sf object
cut <- as.data.frame(cut)
cut$geometry <- st_sfc(cut$geometry)
cut <- st_sf(cut)
st_crs(cut) <- 27700

# check for dupliates
cut <- cut[!duplicated(cut$geometry),]

#Split MULTILINESTRING into LINESTRING

#Add ID
cut$id <- 1:nrow(cut)
row.names(cut) <- cut$id

#Save Out Data
saveRDS(cut, paste0("../stars-data/data/osm/osm-lines-split.Rds"))
osm = cut
rm(cut, points, buff, inter)

pct.all = readRDS("../stars-data/data/routing/routes_scenarios.Rds")
# Switch to single cycle geometry
pct.all$geom_train = NULL
pct.all1 = pct.all
pct.all2 = pct.all
pct.all1$geometry = pct.all1$geom_cycle1
pct.all2$geometry = pct.all2$geom_cycle2
pct.all1 = pct.all1[,c("id","Train","cycle1_baseline_slc", "cycle1_dutch_slc","cycle1_ebike_slc","geometry")]
pct.all2 = pct.all2[,c("id","Train","cycle2_baseline_slc", "cycle2_dutch_slc","cycle2_ebike_slc","geometry")]
names(pct.all1) = c("id","Train","baseline", "dutch","ebike","geometry")
names(pct.all2) = c("id","Train","baseline", "dutch","ebike","geometry")
pct.all = bind_rows(list(pct.all1,pct.all2))
rm(pct.all1, pct.all2)
pct.all = pct.all[lengths(pct.all$geometry) >0,]

# Lost of duplication so group up
pct.all$id2 = as.numeric(factor(as.character(pct.all$geometry))) # Made a unique ID for each duplicated geometry
pct.all = pct.all %>%
                group_by(id2) %>%
                summarise(all = sum(Train, na.rm = T),
                          baseline = sum(baseline, na.rm = T),
                          dutch = sum(dutch, na.rm = T),
                          ebike = sum(ebike, na.rm = T),
                          nroutes = n(),
                          geometry = geometry[1])


#pct.all$geometry = pct.all$geometry_union
#pct.all$geometry_union = NULL
pct.all$ID = 1:nrow(pct.all)
pct.all = st_sf(pct.all, crs = 27700)
#pct.all.group = st_transform(pct.all.group, 27700)



#Performacne Tweak, Preallocate object to a grid to reduce processing time
grid <- st_make_grid(osm, n = c(500,500), what = "polygons")
grid_pct2grid <- st_intersects(pct.all, grid) # Which grids is each pct line in?
grid_grid2osm <- st_intersects(grid, osm)# for each grid which osm lines cross it

ncores = 7

# Make a PCT to OSM Lookup Table
##########################################################
#Parallel
m = 1
n = nrow(pct.all)
start <- Sys.time()
fun <- function(cl){
  parLapply(cl, m:n,find.pct.lines)
}
cl <- makeCluster(ncores) #make clusert and set number of cores
clusterExport(cl=cl, varlist=c("grid_pct2grid", "pct.all","grid_grid2osm","osm"))
clusterExport(cl=cl, c('find.pct.lines') )
clusterEvalQ(cl, {library(sf); source("../stars/scripts/functions.R")})
pct2osm <- fun(cl)
stopCluster(cl)

end <- Sys.time()
message(paste0("Did ",n," lines in ",round(difftime(end,start,units = "secs"),2)," seconds, in parallel mode at ",Sys.time()))
##########################################################

saveRDS(pct2osm,paste0("../stars-data/data/osm/pct2osm.Rds"))

# Convert A PCT to OSM lookup to an OSM to PCT lookup
# We do this in a backwards way becuase we need the PCT to OSM one later
##########################################################
#Parallel
m = 1
n = nrow(osm)
start <- Sys.time()
fun <- function(cl){
  parLapply(cl, m:n,getpctids)
}
cl <- makeCluster(ncores) #make clusert and set number of cores
clusterExport(cl=cl, varlist=c("pct2osm"))
clusterExport(cl=cl, c('getpctids') )
osm2pct <- fun(cl)
stopCluster(cl)

end <- Sys.time()
message(paste0("Got ",n," lines of PCT ids in ",round(difftime(end,start,units = "secs"),2)," seconds, in parallel mode at ",Sys.time()))
##########################################################

saveRDS(osm2pct,paste0("../stars-data/data/osm/osm2pct.Rds"))

#Now for each osm line get the pct values
##########################################################
#Parallel
m = 1
n = nrow(osm)
start <- Sys.time()
fun <- function(cl){
  parLapply(cl, m:n,getpctvalues)
}
cl <- makeCluster(ncores) #make clusert and set number of cores
clusterExport(cl=cl, varlist=c("osm2pct","pct.all"))
clusterExport(cl=cl, c('getpctvalues') )

pct_vals <- fun(cl)
stopCluster(cl)
end <- Sys.time()
message(paste0("Got ",n," lines of PCT values in ",round(difftime(end,start,units = "secs"),2)," seconds, in parallel mode at ",Sys.time()))
##########################################################
pct_vals <- bind_rows(pct_vals)

osm <- left_join(osm, pct_vals, by = c("id" = "id"))
rm(cl,end,n,m)
saveRDS(osm,"../stars-data/data/osm/osm-lines-values.Rds")

osm.withval = osm[osm$All > 0,]
osm.withval = st_transform(osm.withval, 4326)
st_write(osm.withval,"../stars-data/data/osm/osm-lines-values-latlng.geojson", delete_dsn = T)


#tmap_style()


