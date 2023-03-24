# Libraries load ---- 
library(dplyr)
library(readxl)
library(stringr)
library(ggplot2)
library(scales)

# Data for testing -----
# dataFCards <- read.csv("data/Alternative_Scenarios_Card.csv", sep=",", dec=".")
# units <- read.csv("data/Units.csv", sep = ",", dec = ".")
# labels <- read.csv("~/K-State/CosNutSenegal-App/data/filteredPlantingDates.csv", sep = ",", dec = ".")
#precipitation <- read.csv("~/K-State/CosNutSenegal-App/data/precipitationData.csv", sep = ",", dec = ".")

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

# 2.0 Inputs Filtering ----

  ## 2.1 Select Input Filtering ----
label_filter <- function(data, district){
  
  distrito <- toString(district)
  
  dataFiltered <- data %>%
    filter(district == distrito)
  
  array <- c(dataFiltered$id)
  names(array) <- c(dataFiltered$Label)
  
  return(array)
  
}

# 3.0 Card Filtering ----

  ## 3.1 Alternative Management Based ----
card_filtering <- function(dataBase, district, pd, pp, n, acronym, year){
  
  district <- toString(district)
  
  pp <- as.integer(pp)
  identification = paste0("pd", pd, "pp", pp, "n", n)
  
  dataBase <- dataBase %>%
    dplyr::filter(id == identification,
                  District == district)
  
  variable = as.name(str_glue(acronym, ".Alt.", year))
  
  value = dataBase[[variable]]
  
  return(value)
  
}

  ## 3.2 Weather Based -----
card_filtering_weather <- function(dataBase, district, pp, n, acronym, precipitationDB, precipitationValue){
  
  distrito <- toString(district)
  
  pp <- as.integer(pp)
  
  precipitationDB <- precipitationDB %>%
    filter(district == distrito,
           Precipitation == precipitationValue)
  
  ano <- precipitationDB$year
  pd <- precipitationDB$planting_date_id
  
  yearDB <- data.frame(Ano = c(2016, 2017, 2018, 2019, 2020),
                       choice = c(1, 2, 3, 4, 5))
  
  yearDB <- yearDB %>%
    filter(Ano == ano)
  
  identification = paste0("pd", pd, "pp", pp, "n", n)
  
  dataBase <- dataBase %>%
    dplyr::filter(id == identification,
                  District == distrito)
  
  escolha <- yearDB$choice
  
  variable = as.name(str_glue(acronym, ".Alt.", escolha))
  
  value = dataBase[[variable]]
  
  return(value)
  
}

# 4.0 Graphs ----

  ## 4.1 Alternative Management Based ----
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
  variable <- toString(unity$Value)
  
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
    labs(y = str_glue(variable, "(", unidade, ")"),
         x = "Years")+
    scale_y_continuous(labels = comma)+
    theme_bw()
  
  return(boxPlot)
  
}

  ## 4.2 Weather Based ----
graph_filtering_WB <- function(district, pp, n, acronym, precipitationDB, precipitationValue, unitsTable){
  
  path <- paste("data/Data_for_Kansas_", district, ".xlsx", sep = "")
  
  distrito <- toString(district)
  
  precipitationDB <- precipitationDB %>%
    filter(district == distrito,
           Precipitation == precipitationValue)
  
  ano <- precipitationDB$year
  pd <- precipitationDB$planting_date_id
  
  yearDB <- data.frame(Ano = c(2016, 2017, 2018, 2019, 2020),
                       choice = c(1, 2, 3, 4, 5))
  
  yearDB <- yearDB %>%
    filter(Ano == ano)
  
  escolha <- yearDB$choice
  
  sheet = paste0("Alt ", pd, " ", pp, " ", n, "kg")
  column1 = as.name(str_glue(acronym, " Alt ", escolha))
  
  dataBase <- read_excel(path=path, sheet = sheet)
  
  d1 <- dataBase %>%
    select(data = column1)
  
  multipliers <- c("GCal", "GIron", "GVitA")
  
  if(any(acronym %in% multipliers)){
    
    d1$data <- d1$data*1000
    
  }
  
  else if(acronym == "NCFI"){
    d1$data <- d1$data/(607.77)
  }
  if(acronym == "GVitA"){
    aprox <- 3
  }else{
    aprox <- 0
  }

  titulo <- toString(acronym)
  unity <- unitsTable %>%
    filter(Variable == titulo)
  
  unidade <- toString(unity$Unit)
  variable <- toString(unity$Value)
  
  cdf_1 <- ecdf(d1$data)
  value <- d1$data[which(cdf_1(d1$data) == 0.50)]
  value1 <- d1$data[which(cdf_1(d1$data) == 0.90)]
  
  distribution_curve <- ggplot(d1, aes(x=data))+
    stat_ecdf()+
    geom_segment(x = 0,
                 xend = value,
                 y = 0.5,
                 yend = 0.5,
                 color = "#1c5f7e") + 
    geom_segment(x = value,
                 xend = value,
                 y = 0,
                 yend = 0.5,
                 color = "#1c5f7e")+
    geom_text(x = value1,
              y = 0.25,
              label = paste("50% of distribution is", str_glue(round(value, digits = aprox), " ", unidade), sep = "\n"),
              color = "#1c5f7e")+
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
    labs(y = "Distribution",
         x = str_glue(variable, "(", unidade, ")"))+
    scale_y_continuous(labels = comma)+
    theme_bw()
  
  return(distribution_curve)
  
}
# precipitationDB <- precipitation %>%
#   filter(district == "KOLDA")
# 
# quartile <- quantile(precipitationDB$Precipitation, probs = c(0, 0.25, 0.5, 0.75, 1))
# quartile[1]

  ## 4.3 Rain Density ----
rain_density <- function(district, precipitationDB, line){
  
  distrito <- toString(district)
  
  precipitationDB <- precipitationDB %>%
    filter(district == distrito)
  
  quartile <- quantile(precipitationDB$Precipitation, probs = c(0, 0.25, 0.5, 0.75, 1))
  
  density_curve <- ggplot(precipitationDB, aes(x=Precipitation))+
    geom_density()+
    geom_vline(xintercept = quartile[2], size = 1,
               linetype = "dashed", color = "#a31212")+
    geom_vline(xintercept = quartile[3], size = 1,
               linetype = "dashed", color = "#f1ff57")+
    geom_vline(xintercept = quartile[4], size = 1,
               linetype = "dashed", color = "#0e6e15")+
    geom_segment(x = line,
                 xend = line,
                 y = 0,
                 yend = 0.5,
                 color = "#166e95")+
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
    labs(y = "Density",
         x = "Precipitation (mm)")+
    scale_y_continuous(labels = comma)+
    theme_bw()
  
  return(density_curve)
  
}