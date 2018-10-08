# Map routes
library(sf)
library(tmap)
tmap_mode("view")

osm = st_read("../stars-data/data/osm/osm-lines-values-latlng.geojson")
pal = c('#cdcdcd','#fefe94','#d6fe7f','#7efefd','#96d6fd','#95adfd','#7f7ffe','#fe7fe1')
osm = st_transform(osm, 27700) # Tmap not plotting 4326????

tm_shape(osm[osm$Ebikes > 0,]) +
  tm_lines("Ebikes", 
           lwd = 2,
           palette = pal,
           style = "fixed", 
           breaks = c(0,10,50,100,250,500,1000,2000,5000) )


#qtm(osm, lines.lwd = 3, lines.col = "Train", palette= pal, style = "fixed", breaks = c(10,50,100,250,500,1000,2000))

# [2000, '#fe7fe1'],
# [1000, '#7f7ffe'],
# [500, '#95adfd'],
# [250, '#96d6fd'],
# [100, '#7efefd'],
# [50, '#d6fe7f'],
# [10, '#fefe94'],
# [0, '#cdcdcd']