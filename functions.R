# Libraries load ---- 
library(dplyr)
library(readxl)
library(stringr)

dataFCards <- read.csv("data/Alternative_Scenarios_Card.csv", sep=",", dec=".")

# 1.0 Map Rendering ----
map_rendering <- function(districtDB, district){
  
  districtSelected <- districtDB %>%
    dplyr::filter(DISTRICT == district)
  
  map <- leaflet() %>%
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

# Card Filtering ----
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

# Graph Filtering ----
graph_filtering <- function(district, precipitation, pd, pp, n, acronym, unitsTable){
  
  path <- paste("data/Data_for_Kansas_", district, ".xlsx", sep = "")
  
  if(precipitation == TRUE){
    
    sheet = "precipitation"
    column1 = as.name(str_glue(acronym, " Base ", "1"))
    column2 = as.name(str_glue(acronym, " Base ", "5"))
    
  }
  else{
    
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
    
    Years <- rep(c("2016", "2017", "2018", "2019", "2020"),each=500)
    d2 <- cbind(d1, Years)
    
    titulo <- toString(acronym)
    unity <- unitsTable %>%
      filter(Variable == titulo)
    
    unidade <- toString(unity$Unit)
    
    boxPlot <- ggplot(d2, aes(x=Years, y=data, color=Years))+
      geom_boxplot(fill = "#1c5f7e",
                   notch=TRUE)+
      theme(
        panel.background = element_rect(fill = "#1c5f7e",
                                        colour = "#1c5f7e",
                                        size = 0.2, linetype = "solid"),
        plot.background = element_rect(fill = "#1c5f7e"),
        
        axis.title.y = element_text(size = 10,
                                    colour = "white"),
        axis.title.x = element_text(size = 10,
                                    colour = "white"),
        axis.text.y = element_text(size = 8,
                                   face = "bold",
                                   colour = "white"),
        axis.text.x = element_text(size = 8,
                                   face = "bold",
                                   colour = "white"),
        
        legend.background = element_rect(fill = "#1c5f7e"),
        legend.text = element_text(size = 10,
                                   colour = "white"),
        legend.title = element_text(colour = "white")
        
      )+
      labs(y = unidade,
           x = "Years")
    
  }
  
  return(boxPlot)
  
}

# test2 <- graph_filtering(district = "THIES",
#                             precipitation = FALSE,
#                             pd = 1,
#                             pp = 3.3,
#                             n = 20,
#                             acronym = "GIron")