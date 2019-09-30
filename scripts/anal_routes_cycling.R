# Analysie CYcling Routes
library(sf)
library(tmap)
tmap_mode("view")

routes.group = readRDS("../stars-data/data/routing/routes_cycle_grouped2.Rds")

#get the routes to the nearest station
routes.group$mindis = sapply(routes.group$from, function(x){min(routes.group$distances[routes.group$from == x])})
routes.near = routes.group[routes.group$distances == routes.group$mindis,]
qtm(routes.near)
