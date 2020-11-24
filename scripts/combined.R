# Aim: estimate cycling potential at the route network level for multiple trip purposes

r_stations = readRDS("../stars-data/data/routing/phaseII-routes-nearest-station.Rds")
names(r_stations)
sum(sf::st_length(r_stations))
r_stations_ls = sf::st_cast(r_stations, to = "LINESTRING")
sum(sf::st_length(r_stations_ls)) # the same

rnet_stations = stplanr::overline(r_stations_ls, "go_dutch")