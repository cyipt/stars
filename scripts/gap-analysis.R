# Aim: find gaps in the network

remotes::install_github("itsleeds/osmextract")

osm_luton = osmextract::oe_get(sf::st_centroid(region_luton))

q_basic = "select * from 'lines' where highway in ('cycleway')"
q_basic = "select * from 'lines' where cycleway is not 'no'"

cycleway_luton = osmextract::oe_get(sf::st_centroid(region_luton), query = q_basic)
table(cycleway_luton$cycleway)
mapview::mapview(cycleway_luton)

q_basic = "select * from 'lines' where highway = 'cycleway'" # works
q_basic = "select * from 'lines' where maxspeed = '20 mph'" # works
osm_cycle_infra = osmextract::oe_get(sf::st_centroid(region_luton), query = q_basic, extra_tags = "maxspeed") # requires extra tags

osm_cycle_infra = osmextract::oe_get(sf::st_centroid(region_luton), extra_tags = "cycleway") 
table(osm_cycle_infra$cycleway, osm_cycle_infra$highway) # it's important!

library(osmextract)

keys = data.frame(k = oe_get_keys(osm_luton))
keys_sidewalk = keys %>% filter(stringr::str_detect(k, "sidew|cycl")) %>% pull(k)

et = c(
  "cycleway",
  "maxspeed",
  "ref",
  keys_sidewalk
)

q = "select * from 'lines' where (sidewalk_left_bicycle='yes') or 
 (cycleway_left='shared_lane') or
 (cycleway_left='shared_busway') or 
 (cycleway_right='shared_busway') or 
 (cycleway='shared_busway') or 
 (cycleway='opposite_lane') or 
 (highway='bridleway' and bicycle='no') or 
 (bicycle='use_sidepath') or 
 (cycleway='opposite' and oneway_bicycle='no') or 
 (sidewalk_right_bicycle='yes') or 
 (cycleway_right='shared_lane') or 
 (cycleway_left='track') or 
 (cycleway_right='track') or 
 (highway='path' and bicycle='yes') or 
 (highway='path' and (bicycle='designated' or bicycle='official')) or 
 (highway='pedestrian' and (bicycle='yes' or bicycle='official')) or 
 (highway='footway' and (bicycle='yes' or bicycle='official')) or 
 (highway='cycleway') or 
 (cycleway in ('lane', 'opposite_lane', 'shared_busway', 'track', 'opposite_track')) or 
 (cycleway_left in ('lane', 'shared_busway')) or 
 (cycleway_right in ('lane', 'shared_busway')) or 
 (cycleway_both='lane') 
 "
# no cyclestreet or motor_vehicle cols
osm_cycle_infra = osmextract::oe_get(sf::st_centroid(region_luton), query = q, extra_tags = et) # requires extra tags
osm_cycle_infra = osmextract::oe_get("west yorkshire", query = q, extra_tags = et) # requires extra tags
table(osm_cycle_infra$sidewalk_left_bicycle)
table(osm_cycle_infra$cycleway_left)
table(osm_cycle_infra$cycleway_right)
table(osm_cycle_infra$highway)

mapview::mapview(osm_cycle_infra)
library(mapdeck)
mapdeck() %>% 
  mapdeck::add_line(osm_cycle_infra %>% sample_n(100))

q = "(
 (sidewalk:left:bicycle=yes) or 
 (cycleway:left=shared_lane) or 
 (cyclestreet=yes) or 
 (cycleway:left=shared_busway) or 
 (cycleway:right=shared_busway) or 
 (cycleway=shared_busway) or 
 (cycleway=opposite_lane) or 
 (highway=bridleway and bicycle=no) or 
 (highway=track and bicycle=designated and motor_vehicle=no) or 
 (bicycle=use_sidepath) or 
 (cycleway=opposite and oneway:bicycle=no) or 
 (sidewalk:right:bicycle=yes) or 
 (cycleway:right=shared_lane) or 
 (cycleway:left=track) or 
 (cycleway:right=track) or 
 (highway=track and bicycle=designated and motor_vehicle=no) or 
 (highway=path and bicycle=yes) or 
 (highway=path and (bicycle=designated or bicycle=official)) or 
 (highway=service and (bicycle=designated or motor_vehicle=no)) or 
 (highway=pedestrian and (bicycle=yes or bicycle=official)) or 
 (highway=footway and (bicycle=yes or bicycle=official)) or 
 (highway=cycleway) or 
 (cycleway in (lane, opposite_lane, shared_busway, track, opposite_track)) or 
 (cycleway:left in (lane, shared_busway)) or 
 (cycleway:right in (lane, shared_busway)) or 
 (cycleway:both=lane) or 
 (bicycle_road=yes and (motor_vehicle=no or bicycle=designated)) or 
 (cyclestreet=yes)
) "