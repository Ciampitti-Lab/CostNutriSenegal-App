# Libraries load ---- 
library(dplyr)
library(tidyverse)

# Card Filtering ----
card_filtering <- function(dataBase, district, baseline, pd, pp, n, acronym, scenario){
  
  if(baseline == TRUE){
    identification = "baseline"
  }
  else{
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
graph_filtering <- function(dataBase, district, baseline, pd, pp, n, acronym, scenario){
  
  
  
}
