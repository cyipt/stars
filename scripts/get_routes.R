# Batch get routes
devtools::install_github("mem48/transportAPI")
library(sf)
library(stplanr)
library(mapview)

# Define Study Area
lsoa = st_read("../cyipt-bigdata/boundaries/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Generalised_Clipped__Boundaries_in_England_and_Wales.shp")
lsoa = st_transform(lsoa,27700)
bounds = st_read("output-data/region.geojson")
bounds = st_transform(bounds,27700)
lsoa.bounds = lsoa[bounds,]

flow = readr::read_csv("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/LSOA/WM12EW[CT0489]_lsoa/WM12EW[CT0489]_lsoa.csv")
flow = flow[flow$`Area of usual residence` %in% lsoa.bounds$lsoa11cd | flow$`Area of Workplace` %in% lsoa.bounds$lsoa11cd,]
flow$`Area Name` = NULL
flow$`Area of Workplace name` = NULL
flow = onewayid(flow, attrib = 3:ncol(flow))


lsoa.centroids = st_read("../cyipt-bigdata/centroids/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp")
lsoa.centroids = st_transform(lsoa.centroids, 27700)
lsoa.centroids = lsoa.centroids[,c("lsoa11cd")]

flow.lines = od2line(flow, zones = lsoa.centroids)
flow.lines = flow.lines[order(-flow.lines$AllMethods_AllSexes_Age16Plus),]

mapview(lsoa.bounds, col.regions = "grey") +
  mapview(flow.lines[1:10000,])

library(transportAPI)
journey()