# aim: analyse train travel to stations based on nearest station in/around Luton

z = pct::get_pct_zones("bedfordshire")
s = sf::st_read("output-data/stations_all.geojson")

names(s)

z_nearest_points = sf::st_nearest_feature(z, s)
z_nearest_station = sf::st_join(z, s, op = sf::st_nearest_feature)

plot(z_nearest_station["name"])
