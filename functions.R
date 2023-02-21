# Libraries load ---- 
library(dplyr)
library(readxl)

dataFCards <- read.csv("data/Alternative_Scenarios_Card.csv", sep=",", dec=".")

# Card Filtering ----
card_filtering <- function(dataBase, district, baseline, pd, pp, n, acronym, scenario){
  
  district <- toString(district)
  
  if(baseline == TRUE){
    identification = "baseline"
  }
  else{
    pp <- as.integer(pp)
    identification = paste0("pd", pd, "pp", pp, "n", n)
  }
  
  dataBase <- dataBase %>%
    dplyr::filter(id == identification,
                  District == district)
  
  variable = as.name(str_glue(acronym, ".Alt.", scenario))
  
  value = dataBase[[variable]]
  
  return(value)
  
}

# Graph Filtering ----
graph_filtering <- function(district, baseline, pd, pp, n, acronym){
  
  path <- paste("data/Data_for_Kansas_", district, ".xlsx", sep = "")
  
  if(baseline == TRUE){
    sheet = "Baseline"
    column1 = as.name(str_glue(acronym, " Base ", "1"))
    column2 = as.name(str_glue(acronym, " Base ", "5"))
  }
  else{
    sheet = paste0("Alt ", pd, " ", pp, " ", n, "kg")
    column1 = as.name(str_glue(acronym, " Alt ", "1"))
    column2 = as.name(str_glue(acronym, " Alt ", "5"))
  }
  
  dataBase <- read_excel(path=path, sheet = sheet)

  values <- dataBase %>%
    select(column1:column2)
  
  d1 <- data.frame(data=unlist(values, use.names = FALSE))
  
  Scenarios <- rep(c("Alt 1", "Alt 2", "Alt 3", "Alt 4", "Alt 5"),each=500)
  d2 <- cbind(d1, Scenarios)
  
  return(d2)
  
}

dataBase <- graph_filtering(district = "THIES",
                            baseline = FALSE,
                            pd = 1,
                            pp = 3.3,
                            n = 20,
                            acronym = "KCal")