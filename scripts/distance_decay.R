# Distacne Decay Curveys
library(sf)
routes = readRDS("../stars-data/routes_combined.Rds")

# calualte values
routes$cycle1_dist = as.numeric(st_length(routes$geom_cycle1[])) / 1000 # check this is right
routes$cycle1_distsq = routes$cycle1_dist ^ 2
routes$cycle1_distsqrt = sqrt(routes$cycle1_dist)
routes$cycle1_ned_avslope_per = routes$cycle1_av_incline #* 100 # Check this is right

routes$cycle2_dist = as.numeric(st_length(routes$geom_cycle2[])) / 1000 # check this is right
routes$cycle2_distsq = routes$cycle2_dist ^ 2
routes$cycle2_distsqrt = sqrt(routes$cycle2_dist)
routes$cycle2_ned_avslope_per = routes$cycle2_av_incline #* 100 # Check this is right

# Collapse Train and Tube
# A few commuter are listed as using the underground but no line reaches study area, and for our purposed they are the same.
routes$Train = routes$Train + routes$Underground
routes$Underground = NULL


# Make PCT Predictions for Cycle 1



routes$cycle1_pred_base <- -3.894 + (-0.5872 * routes$cycle1_dist) + (1.832 * routes$cycle1_distsqrt) + (0.007956 * routes$cycle1_distsq) +
(-0.2872 * routes$cycle1_ned_avslope_per) + (0.01784 * routes$cycle1_dist* routes$cycle1_ned_avslope_per) +
(-0.09770 * routes$cycle1_distsqrt * routes$cycle1_ned_avslope_per)

routes$cycle1_bdutch <-  2.499+(-0.07384 * routes$cycle1_dist)                 #Dutch travel survey

routes$cycle1_bebike <- (0.05710 * routes$cycle1_dist) + (-0.0001087 * routes$cycle1_distsq)
routes$cycle1_bebike <- routes$cycle1_bebike + (-0.67 * -0.2872 * routes$cycle1_ned_avslope_per)  #Swiss travel survey

routes$cycle1_pred_dutch <- routes$cycle1_pred_base + routes$cycle1_bdutch
routes$cycle1_pred_ebike <- routes$cycle1_pred_dutch + routes$cycle1_bebike

for (x in c('base','dutch','ebike')) {
  routes[[paste0('cycle1_pred_',x)]] <- exp( routes[[paste0('cycle1_pred_',x)]] ) / (1 +  exp( routes[[paste0('cycle1_pred_',x)]] ) )
}

# Apply Scenarios

# Dutch and EBikes
routes$cycle1_dutch_slc  <- routes$cycle1_pred_dutch * routes$Train
routes$cycle1_ebike_slc  <- routes$cycle1_pred_ebike * routes$Train

routes$cycle1_dutch_slc[routes$cycle1_dutch_slc >  routes$Train  & !is.na(routes$cycle1_dutch_slc) ]  <-    routes$Train  #max. is 100%
routes$cycle1_ebike_slc[routes$cycle1_ebike_slc >  routes$Train  & !is.na(routes$cycle1_ebike_slc) ]    <-  routes$Train

#Baseline
routes$cycle1_baseline_slc  <- routes$cycle1_pred_base * routes$Train


#check NAS in this line
routes$cycle1_dutch_slc = ifelse(routes$cycle1_dutch_slc <  routes$Bicycle,routes$Bicycle,routes$cycle1_dutch_slc)
routes$cycle1_ebike_slc = ifelse(routes$cycle1_ebike_slc <  routes$Bicycle,routes$Bicycle,routes$cycle1_ebike_slc)



# Make PCT Predictions for Cycle 2

routes$cycle2_pred_base <- -3.894 + (-0.5872 * routes$cycle2_dist) + (1.832 * routes$cycle2_distsqrt) + (0.007956 * routes$cycle2_distsq) +
  (-0.2872 * routes$cycle2_ned_avslope_per) + (0.01784 * routes$cycle2_dist* routes$cycle2_ned_avslope_per) +
  (-0.09770 * routes$cycle2_distsqrt * routes$cycle2_ned_avslope_per)

routes$cycle2_bdutch <-  2.499+(-0.07384 * routes$cycle2_dist)                 #Dutch travel survey

routes$cycle2_bebike <- (0.05710 * routes$cycle2_dist) + (-0.0001087 * routes$cycle2_distsq)
routes$cycle2_bebike <- routes$cycle2_bebike + (-0.67 * -0.2872 * routes$cycle2_ned_avslope_per)  #Swiss travel survey

routes$cycle2_pred_dutch <- routes$cycle2_pred_base + routes$cycle2_bdutch
routes$cycle2_pred_ebike <- routes$cycle2_pred_dutch + routes$cycle2_bebike

for (x in c('base','dutch','ebike')) {
  routes[[paste0('cycle2_pred_',x)]] <- exp( routes[[paste0('cycle2_pred_',x)]] ) / (1 +  exp( routes[[paste0('cycle2_pred_',x)]] ) )
}

# Apply Scenarios

# Dutch and EBikes
routes$cycle2_dutch_slc  <- routes$cycle2_pred_dutch * routes$Train
routes$cycle2_ebike_slc  <- routes$cycle2_pred_ebike * routes$Train

routes$cycle2_dutch_slc[routes$cycle2_dutch_slc >  routes$Train  & !is.na(routes$cycle2_dutch_slc) ]  <-    routes$Train  #max. is 100%
routes$cycle2_ebike_slc[routes$cycle2_ebike_slc >  routes$Train  & !is.na(routes$cycle2_ebike_slc) ]    <-  routes$Train

#check NAS in this line
routes$cycle2_dutch_slc = ifelse(routes$cycle2_dutch_slc <  routes$Bicycle,routes$Bicycle,routes$cycle2_dutch_slc)
routes$cycle2_ebike_slc = ifelse(routes$cycle2_ebike_slc <  routes$Bicycle,routes$Bicycle,routes$cycle2_ebike_slc)

#Baseline
routes$cycle2_baseline_slc  <- routes$cycle2_pred_base * routes$Train

# Round preditons to whole numbers
routes$cycle1_baseline_slc = round(routes$cycle1_baseline_slc,0)
routes$cycle1_dutch_slc = round(routes$cycle1_dutch_slc,0)
routes$cycle1_ebike_slc = round(routes$cycle1_ebike_slc,0)
routes$cycle2_baseline_slc = round(routes$cycle2_baseline_slc,0)
routes$cycle2_dutch_slc = round(routes$cycle2_dutch_slc,0)
routes$cycle2_ebike_slc = round(routes$cycle2_ebike_slc,0)

# Condence Modes
routes$Motorvehicle = routes$Taxi + routes$CarOrVan + routes$Motorcycle + routes$Passenger
routes$OtherMode = routes$WorkAtHome + routes$Bus + routes$OnFoot + routes$OtherMethod


routes = routes[,c("id","from_lsoa","to_lsoa","from_point_name","to_point_name",
                   "AllMethods","Train","Bicycle",
                   "cycle1_baseline_slc","cycle1_dutch_slc","cycle1_ebike_slc",
                   "cycle2_baseline_slc","cycle2_dutch_slc","cycle2_ebike_slc",
                   "geom_train","geom_cycle1","geom_cycle2")]

saveRDS(routes,"../stars-data/routes_scenarios.Rds")
