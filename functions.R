# Libraries load ---- 
library(dplyr)
library(readxl)
library(stringr)
library(ggplot2)
library(scales)

# Data for testing -----
dataFCards <- read.csv("data/Alternative_Scenarios_Card.csv", sep=",", dec=".")
units <- read.csv("data/Units.csv", sep = ",", dec = ".")
labels <- read.csv("~/K-State/CosNutSenegal-App/data/filteredPlantingDates.csv", sep = ",", dec = ".")

# 1.0 Map Rendering ----
map_rendering <- function(districtDB, district){
  
  districtSelected <- districtDB %>%
    dplyr::filter(DISTRICT == district)
  
  map <- leaflet(options = leafletOptions(zoomControl = FALSE,
                                          minZoom = 6, maxZoom = 6,
                                          dragging = FALSE)) %>%
    addTiles() %>%
    addPolygons( data = districtDB,
                 weight = 1,
                 smoothFactor = 0.2,
                 fillOpacity = 0.2,
                 color = "black",
                 highlight = highlightOptions(
                   weight = 5,
                   color = "#666666",
                   fillOpacity = 0.25,
                   bringToFront = TRUE
                 ),
                 label = districtDB$DISTRICT
    ) %>%
    addPolygons( data = districtSelected,
                 weight = 1,
                 smoothFactor = 1,
                 fillOpacity = 1,
                 color = "#1c5f7e",
                 highlight = highlightOptions(
                   weight = 5,
                   color = "#666666",
                   fillOpacity = 0.5,
                   bringToFront = TRUE
                 )
    )
  
  return(map)
  
}

# 2.0 Label Filtering ----
label_filter <- function(data, district){
  
  distrito <- toString(district)
  
  dataFiltered <- data %>%
    filter(district == distrito)
  
  array <- c(dataFiltered$id)
  names(array) <- c(dataFiltered$Label)
  
  return(array)
  
}

# distrito <- toString("KAOLACK")
# 
# dataFiltered <- labels %>%
#   filter(district == distrito)
# 
# array <- c(dataFiltered$id)
# names(array) <- c(dataFiltered$Label)
# 
# array

# 3.0 Card Filtering ----
card_filtering <- function(dataBase, district, precipitation, pd, pp, n, acronym, year){
  
  district <- toString(district)
  
  if(precipitation == TRUE){
    identification = "precipitation"
    ## Add something after precipitation table arrive
  }
  else{
    pp <- as.integer(pp)
    identification = paste0("pd", pd, "pp", pp, "n", n)
  }
  
  dataBase <- dataBase %>%
    dplyr::filter(id == identification,
                  District == district)
  
  variable = as.name(str_glue(acronym, ".Alt.", year))
  
  value = dataBase[[variable]]
  
  return(value)
  
}

# test1 <- card_filtering(dataBase = dataFCards,
#                         district = "THIES",
#                         precipitation = FALSE,
#                         pd = 1,
#                         pp = 3.3,
#                         n = 20,
#                         acronym = "GIron",
#                         year = )

# 4.0 Graph Filtering ----
graph_filtering <- function(district, pd, pp, n, acronym, unitsTable){
  
  path <- paste("data/Data_for_Kansas_", district, ".xlsx", sep = "")
  production <- read.csv("data/production.csv", sep=",", dec=".")
  
  if(acronym == "production"){
    
    pp <- as.integer(pp)
    identification = paste0("pd", pd, "pp", pp, "n", n)
    
    districto <- toString(district)
    
    d2 <- production %>%
      dplyr::filter(id == identification,
                    district == districto) %>%
      select(year, grain_yield) %>%
      rename("Years" = "year",
             "data" = "grain_yield")
    
    d2$Years <- as.character(d2$Years)
    
  }
  
  else if(acronym != "production"){
    
    sheet = paste0("Alt ", pd, " ", pp, " ", n, "kg")
    column1 = as.name(str_glue(acronym, " Alt ", "1"))
    column2 = as.name(str_glue(acronym, " Alt ", "5"))
    
    dataBase <- read_excel(path=path, sheet = sheet)

    values <- dataBase %>%
      select(column1:column2)
    
    d1 <- data.frame(data=unlist(values, use.names = FALSE))
    
    multipliers <- c("GCal", "GIron", "GVitA")
    
    if(any(acronym %in% multipliers)){
      
      d1$data <- d1$data*1000
      
    }
    
    else if(acronym == "NCFI"){
      d1$data <- d1$data/(607.77)
    }
    
    
    Years <- rep(c("2016", "2017", "2018", "2019", "2020"),each=500)
    d2 <- cbind(d1, Years)
    
  }
  
  titulo <- toString(acronym)
    unity <- unitsTable %>%
      filter(Variable == titulo)
    
  unidade <- toString(unity$Unit)
  
  boxPlot <- ggplot(d2, aes(x=Years, y=data, color=Years))+
    geom_boxplot(fill = "white",
                 notch=FALSE)+
    theme(
      panel.background = element_rect(fill = "#e3ecef",
                                      colour = "#e3ecef",
                                      size = 0.2, linetype = "solid"),
      plot.background = element_rect(fill = "white"),
      
      axis.title.y = element_text(size = 10,
                                  colour = "black"),
      axis.title.x = element_text(size = 10,
                                  colour = "black"),
      axis.text.y = element_text(size = 8,
                                 face = "bold",
                                 colour = "black"),
      axis.text.x = element_text(size = 8,
                                 face = "bold",
                                 colour = "black"),
      
      legend.background = element_rect(fill = "white"),
      legend.text = element_text(size = 10,
                                 colour = "black"),
      legend.title = element_text(colour = "black")
      
    )+
    labs(y = unidade,
         x = "Years")+
    scale_y_continuous(labels = comma)+
    theme_bw()
  
  return(boxPlot)
  
}

# test2 <- graph_filtering(district = "KAFFRINE",
#                          pd = 1,
#                          pp = 3.3,
#                          n = 20,
#                          acronym = "production",
#                          unitsTable = units)
# test2
