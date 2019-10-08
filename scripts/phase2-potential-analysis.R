# Aim explore cycling potential to rail stations in Luton

# Note: run after phase2 nearest stations and flow scripts

potential_phase1 = readRDS("../stars-data/data/station_flow_estimates.Rds")
potential_phase1 = na.omit(potential_phase1)
plot(potential_phase1[2:3])
sum(potential_phase1$AllMethods_in) / sum(z$all)
sum(potential_phase1$Train_in) / sum(z$train_tube) * 100
sum(potential_phase1$AllMethods_in) / sum(z$train_tube) * 100
sum(potential_phase1$AllMethods_out) / sum(z$train_tube) * 100
# Malcolm's analysis captures 80% of rail trips
sum(potential_phase1$Baseline_in) / sum(potential_phase1$AllMethods_in) * 100
# only 0.4% assumed to cycle in
sum(potential_phase1$Dutch_in) / sum(potential_phase1$AllMethods_in) * 100
# 12% Got Dutch
sum(potential_phase1$Ebike_in) / sum(potential_phase1$AllMethods_in) * 100
sum(potential_phase1$Ebike_out) / sum(potential_phase1$AllMethods_in) * 100


sum(potential_phase1$Train_in)
sum(potential_phase1$Dutch_in)
