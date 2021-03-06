library("RMySQL")
library("plotly")
library("dplyr")
library("RecordLinkage")

# Connection to MySQL
ElephantiasisAnalysis <- dbConnect(MySQL(), user='root', password='hello', dbname='ElephantiasisAnalysis', host='localhost')

# Table of contacts of patients
patient_contact <- dbGetQuery(ElephantiasisAnalysis, "select * from contact;")

# Table of limb data
limb_data <- dbGetQuery(ElephantiasisAnalysis, "select * from limb_data_revised;")

# Table of volume change
limb_volume_change <- dbGetQuery(ElephantiasisAnalysis, "select * from limb_vol_change;")

# List to store correctly spelled cities
actual_cities <- c()

count <- 0
similarity <- 0
correct_city <- ""
k <- 1

patient_contact2 <- patient_contact

patient_contact2 <- patient_contact2[complete.cases(patient_contact2[, "state"]), ]

patient_contact2 <- patient_contact2[patient_contact2$state %in% names(table(patient_contact2$state))[table(patient_contact2$state) >= 10],]

unique_states <- unique(patient_contact2$state)

names(patient_contact2)[1] = "patient_limb_id"
limb_data_revised <- merge(limb_data, patient_contact2, by = "patient_limb_id")
limb_data_revised <- merge(limb_data_revised, limb_volume_change, by = c("patient_limb_id", "followup_code"))
limb_data_revised <- limb_data_revised[, c("patient_limb_id", "affected_nonaffected_limb", "followup_code", "state", "vol_change")]

# Average volume change per district
avg <- list()
ctr <- 1
colors <- c("red", "blue", "yellow", "purple", "green", "orange", "black")

num_affected <- data.frame("District" = "None", "Number_Affected" = 0)
num_affected <- num_affected[-c(1), ]

for(i in unique_states){
  set <- subset(limb_data_revised, state == i)
  add_row <- data.frame("State" = i, "Number_Affected" = length(unique(set$patient_limb_id)))
  num_affected <- rbind(num_affected, add_row)
  
  avg[[i]] <- data.frame("followup_no" = c(1, 2, 3, 4, 5, 6), "avg_change" = 0, "count" = 0)
  
  for(j in 1:nrow(set)){
    avg[[i]]$avg_change[set$followup_code[j]] <- avg[[i]]$avg_change[set$followup_code[j]] + set$vol_change[j]
    avg[[i]]$count[set$followup_code[j]] <- avg[[i]]$count[set$followup_code[j]] + 1
  }
  
  for(j in 1:6){
    avg[[i]]$avg_change[j] <- avg[[i]]$avg_change[j]/avg[[i]]$count[j]
  }
  
  avg[[i]]$avg_change[1] <- 0
  
}

states <- c("KL", "KA", "MH", "AP", "TN")

num_affected <- num_affected[order(-num_affected$Number_Affected), ]

for(i in c(1:5)){
  plot(x = avg[[num_affected$State[i]]]$followup_no, y = avg[[num_affected$State[i]]]$avg_change, type = "o", main = "State Wise Change in Volume vs Followups", xlab = "Followup Code", ylab = "Volume Change", col = colors[ctr], ylim = c(-1.0, 2.5), lwd = 1)
  par(new = TRUE)
  ctr <- ctr + 1
}

legend("topright", legend = states, num_affected$State[1:5], col = colors, lwd = 2, cex = 0.75)

barplot(num_affected$Number_Affected[1:5], names.arg = states, main="State Wise Distribution of Patients", xlab="States", ylab="No. of Patients")

# Close the connection with MySQL
list <- dbListConnections(MySQL())
for(con in list) {
  dbDisconnect(con)
}

