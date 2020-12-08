# Aim: find gaps in the network

remotes::install_github("itsleeds/osmextract")

osm_luton = osmextract::oe_get(sf::st_centroid(region_luton))
osm_luton_test = osm_luton %>% 
  filter(name == "New Airport Way")

mapview::mapview(osm_luton_test)
q_basic = "select * from 'lines' where highway in ('cycleway')"
q_basic = "select * from 'lines' where cycleway is not 'no'"
q_basic = "select * from 'lines' where cycleway='lane'"

# failing, not sure why 
cycleway_luton = osmextract::oe_get(sf::st_centroid(region_luton), query = q_basic, extra_tags = "cycleway")
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
keys_bike = keys %>% filter(stringr::str_detect(k, "bike")) %>% pull(k)

et = c(
  "cycleway",
  "maxspeed",
  "ref",
  keys_sidewalk
)

# See http://k1z.blog.uni-heidelberg.de/2020/10/02/how-to-become-ohsome-part-8-complex-analysis-with-the-magical-filter-parameter/
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
# osm_cycle_infra = osmextract::oe_get("west yorkshire", query = q, extra_tags = et) # requires extra tags
table(osm_cycle_infra$sidewalk_left_bicycle)
table(osm_cycle_infra$cycleway)
table(osm_cycle_infra$cycleway_left)
table(osm_cycle_infra$cycleway_right)
table(osm_cycle_infra$highway)

mapview::mapview(osm_cycle_infra)
library(mapdeck)
mapdeck() %>% 
  mapdeck::add_line(osm_cycle_infra %>% sample_n(100))

qb = "select * from 'lines' where cycleway is not null"# nothing!
qb = "select * from 'lines' where cycleway_left='lane'"# works!
qb = "select * from 'lines' where 
(cycleway='lane') or 
(cycleway_left='lane') or 
(cycleway_right='lane') or 
(cycleway_both='lane') 
"# works!
osm_cycle_lanes = osmextract::oe_get(sf::st_centroid(region_luton), query = qb, extra_tags = et) # requires extra tags


mapview::mapview(osm_cycle_lanes)
# get single relation - cycleway
library(osmdata)
ctrd = opq("leeds") %>% 
  add_osm_feature(key = "name", value = "Chapeltown Road") %>% 
  osmdata_sf()
mapview::mapview(ctrd$osm_lines)
