# Loading libraries ----
library(dplyr)
library(readr)
library(lubridate)
library(apsimx)
library(tools)

# Loading data files ----
production <- read_csv("~/K-State/CosNutSenegal-App/NilsonData/app_files/pearl millet_  simulations_ 2016-2021.csv")
plantingDates <- read_csv("~/K-State/CosNutSenegal-App/NilsonData/app_files/pearl millet planting dates_ 2016-2021.csv")

# General information ----

districts <- c("Diourbel", "Fatick", "Kaffrine", "Kaolack", "Kolda", "Thies")

# Extracting planting dates for each district ----

  ## Converting date from string to date ----

plantingDates$planting_date <- format(plantingDates$planting_date,
                                       format = "%m/%d")

plantingDates$harvest_data <- format(plantingDates$harvest_data,
                                       format = "%m/%d")

  ## Getting min and max dates of each department ----
newPlantingDates <- plantingDates %>%
  group_by(id, department) %>%
  summarise(Minimum = min(planting_date),
            Maximum = max(planting_date))

  ## Getting the district of each department ----
productionDepartmentsByDistrict <- production %>%
  filter(district == districts) %>%
  group_by(planting_date_id ,department, district) %>%
  summarise(grao = mean(grain_yield))

  ## Manual verification ----
write.csv(productionDepartmentsByDistrict, "~/K-State/CosNutSenegal-App/NilsonData/app_files/productionDepartmentsByDistrict.csv", row.names=FALSE)
write.csv(newPlantingDates, "newPlantingDates.csv", row.names=FALSE)

  ## Getting minimum and maximum dates filtered by district ----
newPlantingDates <- read_csv("~/K-State/CosNutSenegal-App/NilsonData/newPlantingDates.csv")

filteredPlantingDates <- newPlantingDates %>%
  group_by(id, district) %>%
  summarise(Minimum = min(Minimum),
            Maximum = max(Maximum))

write.csv(filteredPlantingDates, "~/K-State/CosNutSenegal-App/NilsonData/filteredPlantingDates.csv", row.names=FALSE)

  ## Getting mean date ----
filteredPlantingDates <- read_csv("~/K-State/CosNutSenegal-App/data/filteredPlantingDates.csv")

filteredPlantingDates$Minimum <- as.Date(filteredPlantingDates$Minimum, format = "%m/%d/%Y")
filteredPlantingDates$Maximum <- as.Date(filteredPlantingDates$Maximum, format = "%m/%d/%Y")

plantingDateDays <- filteredPlantingDates %>%
  mutate(numberofDaysMin = yday(Minimum),
         numberofDaysMax = yday(Maximum))

plantingDateDays$Mean <- rowMeans(plantingDateDays[ , c(5,6)], na.rm=TRUE)
plantingDateDays$Mean <- round(plantingDateDays$Mean, digits = 0)

plantingDateDays$Mean <- as.character(plantingDateDays$Mean)

plantingDateFinal <- plantingDateDays %>%
  mutate(PlantingDate = parse_date_time(x = Mean, orders = "j")) %>%
  mutate(district = toupper(district))


write.csv(plantingDateFinal, "~/K-State/CosNutSenegal-App/NilsonData/filteredPlantingDates.csv", row.names=FALSE)

# Processing production table ----

productionFiltered <- production %>%
  filter(district %in% districts) %>%
  select(id, district, year, grain_yield) %>%
  mutate(district = toupper(district))

write.csv(productionFiltered, "~/K-State/CosNutSenegal-App/data/production.csv", row.names=FALSE)

# Precipitation data retrieving ----

  ## Getting Latitude and Longitude from locations -----
latLongTable <- production %>%
  filter(district %in% districts) %>%
  select(loc, latitude, longitude, department, district, year, planting_date_id)

latLongTable <- unique(latLongTable)

latLongTable <- latLongTable %>%
  filter(department != "Guinguineo")

latLongTable <- latLongTable[order(latLongTable$department, decreasing = FALSE), ]

  ## Getting planting and harvesting dates from locations ----
departments <- unique(latLongTable$department)

plantHarv <- plantingDates %>%
  filter(department %in% departments)

plantHarv <- plantHarv[order(plantHarv$department, decreasing = FALSE), ]


  ## Merging the two -----
plantHarv <- select(plantHarv, -c(id, loc, department))

preFinalTable <- cbind(latLongTable, plantHarv)

  ## Opening meta files and generating table ----

files <- list.files(path="~/K-State/CosNutSenegal-App/NilsonData/app_files/weather_files", pattern="*.met", full.names=FALSE, recursive=FALSE)

df <- data.frame(year = integer(),
                 day = integer(), 
                 rain = double(),
                 department = character(),
                 location = integer())

years <- c("2016", "2017", "2018", "2019", "2020", "2021")

for (file in files){
  
  provisoryfile <- read_apsim_met(file, src.dir = "~/K-State/CosNutSenegal-App/NilsonData/app_files/weather_files", verbose = TRUE)
  
  filteredProvisoryFile <- provisoryfile %>%
    filter(year %in% years) %>%
    select(year, day, rain)
  
  fileName <- file_path_sans_ext(file)
  names <- scan(text = fileName, what = "")
  
  repetitions <- nrow(filteredProvisoryFile)

  departmento <- rep(names[1], each = repetitions)
  location <- rep(names[2], each = repetitions)

  d4 <- data.frame(filteredProvisoryFile,
                   departmento,
                   location)
  
  #precipitationDB <- rbind(df, d4)
  precipitationDB <- rbind(precipitationDB, d4)
  
}

precipitationDB <- precipitationDB[order(precipitationDB$departmento, decreasing = FALSE), ]

  ## Getting day of year from planting dates ----
preFinalTable$planting_date <- as.Date(preFinalTable$planting_date, format = "%m/%d/%Y")
preFinalTable$harvest_data <- as.Date(preFinalTable$harvest_data, format = "%m/%d/%Y")

preFinalTable <- preFinalTable %>%
  mutate(Planting = yday(planting_date),
         Harverst = yday(harvest_data))

preFinalTable <- preFinalTable %>%
  select(-c(planting_date, harvest_data))

  ## Doing table with precipitation amount of inside the interval ----
rainDf <- data.frame(Rain = as.numeric())

round <- nrow(preFinalTable)

preFinalTable$department <- gsub(" ", "", preFinalTable$department)

for(x in 1:round){
  interestingRow <- preFinalTable[x,] 
  
  dept <- interestingRow$department
  localizacion <- interestingRow$loc
  ano <- interestingRow$year
  plantio <- interestingRow$Planting
  colheita <- interestingRow$Harverst
  
  testPrepDB <- precipitationDB %>%
    filter(departmento == dept,
           location == localizacion)
  
  
  -if(colheita > 41){
    
    interval <- seq.int(plantio, colheita)
    
    onePrepDB <- testPrepDB %>%
      filter(year == ano,
             day %in% interval)
    
    rainDf[x,] <- sum(onePrepDB$rain)
    
  }else{
    
    interval <- seq.int(plantio, 365)
    interval1 <- seq.int(1, colheita)
    anno <- ano+1
    
    onePrepDB <- testPrepDB %>%
      filter(year == ano,
             day %in% interval)
    
    twoPrepDB <- testPrepDB %>%
      filter(year == anno,
             day %in% interval1)
    
    finalPrepDB <- rbind(onePrepDB, twoPrepDB)
    
    rainDf[x,] <- sum(finalPrepDB$rain)
  }
}

finalWorkableDB <- cbind(preFinalTable, rainDf)

precipitationData <- finalWorkableDB %>%
  group_by(district, year, planting_date_id) %>%
  summarise(Precipitation = mean(Rain))

precipitationData$Precipitation <- round(precipitationData$Precipitation, digits = 0)

write.csv(precipitationData, "~/K-State/CosNutSenegal-App/data/precipitationData.csv", row.names=FALSE)

# Precipitation 32 years data ----

latLongTable <- production %>%
  filter(district %in% districts) %>%
  select(loc, latitude, longitude, department, district, year, planting_date_id)

latLongTable <- unique(latLongTable)

latLongTable <- latLongTable %>%
  filter(department != "Guinguineo")

latLongTable <- latLongTable[order(latLongTable$department, decreasing = FALSE), ]

departments <- unique(latLongTable$department)

plantHarv <- plantingDates %>%
  filter(department %in% departments)

plantHarv <- plantHarv[order(plantHarv$department, decreasing = FALSE), ]

plantHarv$planting_date <- as.Date(plantHarv$planting_date, format = "%m/%d/%Y")
plantHarv$harvest_data <- as.Date(plantHarv$harvest_data, format = "%m/%d/%Y")

plantHarv <- plantHarv %>%
  mutate(plantingDate = yday(planting_date),
         harvestDate = yday(harvest_data))

plantHarv <- plantHarv %>%
  group_by(department, id) %>%
  mutate(plantingDateMean = mean(plantingDate),
         harvestingDateMean = mean(harvestDate))

plantHarv <- plantHarv %>%
  group_by(department, id, loc) %>%
  summarise(plantingDate = mean(plantingDateMean),
            harvestDate = mean(harvestingDateMean))

plantHarv$plantingDate <- round(plantHarv$plantingDate, digits = 0)
plantHarv$harvestDate <- round(plantHarv$harvestDate, digits = 0)

files <- list.files(path="~/K-State/CosNutSenegal-App/NilsonData/app_files/weather_files", pattern="*.met", full.names=FALSE, recursive=FALSE)

df <- data.frame(year = integer(),
                 day = integer(), 
                 rain = double(),
                 department = character(),
                 location = integer())

for (file in files){
  
  provisoryfile <- read_apsim_met(file, src.dir = "~/K-State/CosNutSenegal-App/NilsonData/app_files/weather_files", verbose = TRUE)
  
  filteredProvisoryFile <- provisoryfile %>%
    select(year, day, rain) 
  
  fileName <- file_path_sans_ext(file)
  names <- scan(text = fileName, what = "")
  
  repetitions <- nrow(filteredProvisoryFile)
  
  departmento <- rep(names[1], each = repetitions)
  location <- rep(names[2], each = repetitions)
  
  d4 <- data.frame(filteredProvisoryFile,
                   departmento,
                   location)
  
  #precipitationDB <- rbind(df, d4)
  precipitationDB <- rbind(precipitationDB, d4)
  
}

precipitationDB <- precipitationDB %>%
  filter(year != 2022)

plantHarv <- plantHarv[rep(seq_len(nrow(plantHarv)), each = 32), ]
plantHarv$Year <- NA

rainDf <- data.frame(Rain = as.numeric())

plantHarv$department <- gsub(" ", "", plantHarv$department)

plantHarv$Year <- rep(seq(1990, 2021), times = 270)

round <- nrow(plantHarv)

for(x in 1:round){
  
  interestingRow <- plantHarv[x,] 
  
  dept <- interestingRow$department
  localizacion <- interestingRow$loc
  plantio <- interestingRow$plantingDate
  colheita <- interestingRow$harvestDate
  ano <- interestingRow$Year
  
  testPrepDB <- precipitationDB %>%
    filter(departmento == dept,
           location == localizacion)
    
  interval <- seq.int(plantio, colheita)
    
  onePrepDB <- testPrepDB %>%
      filter(year == ano,
             day %in% interval)
    
  rainDf[x,] <- sum(onePrepDB$rain)
    
}

plantHarv <- cbind(plantHarv, rainDf)

precipitationFullData <- plantHarv %>%
  group_by(department, Year, id) %>%
  summarise(Precipitation = mean(Rain))

precipitationFullData$Precipitation <- round(precipitationFullData$Precipitation, digits = 0)

write.csv(precipitationFullData, "~/K-State/CosNutSenegal-App/data/precipitationFullData.csv", row.names=FALSE)

precipitationFullData <- read_csv("~/K-State/CosNutSenegal-App/data/precipitationFullData.csv")

precipitationFullData <- precipitationFullData %>%
  group_by(department, Year, id) %>%
  summarise(Rain = mean(Precipitation))

write.csv(precipitationFullData, "~/K-State/CosNutSenegal-App/data/precipitationFullData.csv", row.names=FALSE)
