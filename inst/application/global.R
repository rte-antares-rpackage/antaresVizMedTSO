suppressWarnings({
  suppressMessages({
    suppressPackageStartupMessages({
      require(shiny)
      require(antaresRead)
      require(antaresVizMedTSO)
      require(manipulateWidget)
      require(data.table)
      require(shinydashboard)
      require(shinyWidgets)
      require(DT)
      
      require(colourpicker)
      require(ggplot2)
      require(ggrepel)
      require(ggforce)
      
      require(sp)
      
      require(shinyFiles)
      
    })
  })
})

check_conf_file <- function(x){
  tmp <- gsub("\\", "/", x, fixed = T)
  if(length(x) == 0) x <- ""
  if(!file.exists(x)) x <- ""
  x
}

if(file.exists("default_conf.yml")){
  conf <- try(yaml::read_yaml("default_conf.yml"), silent = TRUE)
  
  study_dir <- check_conf_file(conf$study_dir)
  map_layout <- check_conf_file(conf$map_layout)
  load_map_params <- check_conf_file(conf$load_map_params)
  load_map_colors <- check_conf_file(conf$load_map_colors)
  file_sel_import <- check_conf_file(conf$file_sel_import)
  file_sel_import_medtso_maps <- check_conf_file(conf$file_sel_import_medtso_maps)
  file_sel_medtso_map <- check_conf_file(conf$file_sel_medtso_map)
  file_sel_import_format_output <- check_conf_file(conf$file_sel_import_format_output)
  file_sel_format_output <- check_conf_file(conf$file_sel_format_output)
  file_sel_template_format_output <- check_conf_file(conf$file_sel_template_format_output)
  file_load_prod_stack <- check_conf_file(conf$file_load_prod_stack)
} else {
  map_layout <- ""
  load_map_params <- ""
  load_map_colors <- ""
  study_dir <- ""
  file_sel_import <- ""
  file_sel_import_medtso_maps <- ""
  file_sel_medtso_map <- ""
  file_sel_import_format_output <- ""
  file_sel_format_output <- ""
  file_sel_template_format_output <- ""
  file_load_prod_stack <- ""
}

if(file_load_prod_stack == ""){
  init_file_load_prod_stack <- FALSE
} else {
  init_file_load_prod_stack <- TRUE
}

if(file_sel_template_format_output == "") file_sel_template_format_output <- "www/Annual_OutputFile_Template_R.xlsx"

if(file_sel_format_output == "") file_sel_format_output <- "www/Output_Selection_template.xlsx"

defaut_map_layout <- NULL
if(!is.null(map_layout) && file.exists(map_layout)){
  tmp_ml <- try(readRDS(map_layout), silent = TRUE)
  if("mapLayout" %in% class(tmp_ml)){
    defaut_map_layout <- tmp_ml
  }
}

if(!is.null(load_map_colors) && file.exists(load_map_colors)){
  tmp_col <- tryCatch(readRDS(load_map_colors), error = function(e) NULL)
  if(!is.null(tmp_col)){
    tmp <- as.data.table(rbind(tmp_col, getColorsVars()[lan == "en", colnames(tmp_col), with = FALSE]))
    setColorsVars( unique(tmp, by = "Column"))
  }
}

# choose a directory
# source("src/scripts/directoryInput.R", encoding = "UTF-8")
source("src/scripts/subsetDataTable.R", encoding = "UTF-8")
source("src/scripts/utils_medtso_maps.R", encoding = "UTF-8")
source("src/scripts/utils_format_output.R", encoding = "UTF-8")

# shared inputs
.global_shared_prodStack <- data.frame(
  module = "prodStack", 
  panel = "prodStack", 
  input = c("dateRange", "unit", "mcYear", "mcYearh", "timeSteph5", "legend", "drawPoints", "stepPlot"),
  type = c("dateRangeInput", "selectInput", "selectInput", "selectInput", "selectInput", 
           "checkboxInput", "checkboxInput", "checkboxInput"), stringsAsFactors = FALSE)

.global_shared_plotts <- data.frame(
  module = "plotts", 
  panel = "tsPlot", 
  input = c("dateRange", "mcYear", "mcYearh", "timeSteph5", "legend", "drawPoints", "stepPlot"),
  type = c("dateRangeInput", "selectInput", "selectInput", "selectInput", 
           "checkboxInput", "checkboxInput", "checkboxInput"), stringsAsFactors = FALSE)


.global_shared_plotMap <- data.frame(
  module = "plotMap", 
  panel = "Map", 
  input = c("dateRange", "mcYear", "mcYearh", "timeSteph5"),
  type = c("dateRangeInput", "selectInput", "selectInput", "selectInput"), stringsAsFactors = FALSE)

.global_shared_exchangesStack <- data.frame(
  module = "exchangesStack", 
  panel = "exchangesStack", 
  input = c("dateRange", "unit", "mcYear", "mcYearh", "timeSteph5", "legend", "drawPoints", "stepPlot"),
  type = c("dateRangeInput", "selectInput", "selectInput", "selectInput", "selectInput", 
           "checkboxInput", "checkboxInput", "checkboxInput"), stringsAsFactors = FALSE)

.global_shared_input <- rbind(.global_shared_prodStack, .global_shared_plotts, .global_shared_plotMap, .global_shared_exchangesStack)


.global_build_input_data <- function(data){
  data$input_id <- paste0(data$module, "-shared_", data$input)
  data$last_update <- NA
  data$update_call <- ""
  class(data$last_update) <- c("character")
  data <- data.table(data)
  data
}

#------------
# compare
#-----------

.global_compare_prodstack <- c("mcYear", "main", "unit", "areas", "legend", 
                               "stack", "stepPlot", "drawPoints")

.global_compare_exchangesStack <- c("mcYear", "main", "unit", "area",
                                    "legend", "stepPlot", "drawPoints")

.global_compare_tsPlot <- c("mcYear", "main", "variable", "type", "confInt", "elements", 
                            "aggregate", "legend", "highlight", "stepPlot", "drawPoints", "secondAxis")

.global_compare_plotMap <- c("mcYear", "type", "colAreaVar", "sizeAreaVars", "areaChartType", "showLabels",
                             "popupAreaVars", "labelAreaVar","colLinkVar", "sizeLinkVar", "popupLinkVars")


#----- generate help for antaresRead function
# library(tools)
# add.html.help <- function(package, func, tempsave = paste0(getwd(), "/temp.html")) {
#   pkgRdDB = tools:::fetchRdDB(file.path(find.package(package), "help", package))
#   topics = names(pkgRdDB)
#   rdfunc <- pkgRdDB[[func]]
#   tools::Rd2HTML(pkgRdDB[[func]], out = tempsave)
# }
# add.html.help("antaresRead", "readAntares", "inst/application/www/readAntares.html")
# add.html.help("antaresRead", "removeVirtualAreas", "inst/application/www/removeVirtualAreas.html")
# add.html.help("antaresRead", "writeAntaresH5", "inst/application/www/writeAntaresH5.html")


#-------- MED-Tso maps

# referentiels des positions
ref_medtsomap_data <- readMEDTsoMapInput("data/MedTSO_map_template.xlsx")

sp_object <- readRDS("data/final_sp_map.RDS")
sp_object@data <- as.data.table(sp_object@data)

#------- format output

defaut_template <- system.file("application/www/Output_Selection_template.xlsx", package = "antaresVizMedTSO")
defaut_output_params <- readTemplateFile(defaut_template)

# new alias on map
setAlias("Total generation", "Total generation", c("areas", "NUCLEAR", 
                                                   "COAL", 
                                                   "LIGNITE", 
                                                   "GAS", 
                                                   "OIL", 
                                                   "Others_non-renewable", 
                                                   "Hydro", 
                                                   "WIND", 
                                                   "SOLAR", 
                                                   "MISC. NDG"))

# detect if running in electron (pas trouve mieux...)
is_electron <- dir.exists("nativefier-app")

storage_vars = c("PSP", "PSP_Closed", "BATT", "DSR", "EV", "P2G", "H2")

rm_storage_input <- c("rmva_storageFlexibility", "rmva_PSP_Closed", "rmva_BATT", "rmva_DSR", "rmva_EV", "rmva_P2G", "rmva_H2")
n <- 3
rm_storage_input_import_final <- rm_storage_input
for(i in 2:n){
  rm_storage_input_import_final <- c(rm_storage_input_import_final, paste0(rm_storage_input, "_", i))
}

rm_storage_input_import_format_final <- paste0(rm_storage_input, "_format_output")
for(i in 2:n){
  rm_storage_input_import_format_final <- c(rm_storage_input_import_format_final, paste0(rm_storage_input, "_format_output_", i))
}

rm_storage_input_import_map_final <- paste0(rm_storage_input, "_medtso_maps")
for(i in 2:n){
  rm_storage_input_import_map_final <- c(rm_storage_input_import_map_final, paste0(rm_storage_input, "_medtso_maps_", i))
}

build_storage_list <- function(...){
  l <- list(...)
  if(length(l) == 0) return(NULL)
  ind_keep <- sapply(l, function(x){
    !isTRUE(all.equal(x, NULL)) & !isTRUE(all.equal(x, ""))
  })
  l <- l[ind_keep]
  if(length(l) == 0) return(NULL)
  lapply(l, function(x) tolower(x))
}

build_production_list <- function(...){
  l <- list(...)
  if(length(l) == 0) return(NULL)
  ind_keep <- sapply(l, function(x){
    !isTRUE(all.equal(x, NULL)) & !isTRUE(all.equal(x, ""))
  })
  if(length(ind_keep) > 0){
    l[ind_keep] <- lapply(l[ind_keep], function(x) tolower(x))
  }
  l
}


setProdStackAlias(
  name = "Med-TSO_1",
  variables = alist(
    "Surplus" = - `SPIL. ENRG`,  
    "pumpedStorage" = (PSP + {if(exists("PSP_Closed", inherits = FALSE)){PSP_Closed} else {0}}),
    "Battery" = {if(exists("BATT", inherits = FALSE)){BATT} else {0}},
    "import/export" = -(BALANCE + `ROW BAL.`),
    "Others thermal" = `MISC. DTG` + `MIX. FUEL`,
    "Other renewable" = `MISC. NDG`,
    "wind" = WIND,
    "solar" = SOLAR,
    "nuclear" = NUCLEAR,
    "hydraulic" = `H. ROR` + `H. STOR`,
    "gas" = GAS,
    "LIGNITE" = LIGNITE,
    "coal" = COAL,
    "oil" = OIL
  ),
  colors = c(
    "#dcec5e",#surplus
    "#951b81",#pompage
    "#e5007d",#batterie
    "#a5b4b8",#import
    "#b4822b",#autre thermiques 
    "#166a57",#autres renouvelables
    "#74cfa0",#eolien 
    "#f27406",#solaire
    "#f5b300",#nucleaire
    "#2772b2",#hydraulique
    "#aad6e0",#gaz 
    "#694d30",#lignite
    "#292525",#charbon 
    "#3d607d" #fioul
  ),
  lines = alist(
    "Total load" = LOAD - {if(exists("P2G", inherits = FALSE)){P2G} else {0}} - {if(exists("EV", inherits = FALSE)){EV} else {0}},
    "Power to Gas" = - {if(exists("P2G", inherits = FALSE)){P2G} else {0}},
    "Electric Vehicle" = - {if(exists("EV", inherits = FALSE)){EV} else {0}},
    "generation" = NUCLEAR + LIGNITE + COAL + GAS + OIL + `MIX. FUEL` +
      `MISC. DTG` + WIND + SOLAR + `H. ROR` + `H. STOR` +
      `MISC. NDG` + 
      {if(exists("PSP_POS", inherits = FALSE)){PSP_POS} else {0}} + 
      {if(exists("PSP_Closed_POS", inherits = FALSE)){PSP_Closed_POS} else {0}} + 
      {if(exists("BATT_POS", inherits = FALSE)){BATT_POS} else {0}} - `SPIL. ENRG`),
  lineColors = c(
    "#005542",#Consommation totale
    "#b2e34f",#Power to gaz
    "#e0d61d",#Vehicule électrique
    "#e5007d"),#Production	
  lineWidth = 2
)


setProdStackAlias(
  name = "Med-TSO_2",
  variables = alist(
    "Surplus" = - `SPIL. ENRG`,  
    "pumpedStorage" = (PSP + {if(exists("PSP_Closed", inherits = FALSE)){PSP_Closed} else {0}}),
    "Battery" = {if(exists("BATT", inherits = FALSE)){BATT} else {0}},
    "import/export" = -(BALANCE + `ROW BAL.`),
    "nuclear" = NUCLEAR,
    "gas" = GAS,
    "LIGNITE" = LIGNITE,
    "coal" = COAL,
    "oil" = OIL,
    "Others thermal" = `MISC. DTG` + `MIX. FUEL`,
    "Other renewable" = `MISC. NDG`,
    "wind" = WIND,
    "solar" = SOLAR,
    "hydraulic" = `H. ROR` + `H. STOR`
  ),
  colors = c(
    "#dcec5e",#surplus
    "#951b81",#pompage
    "#e5007d",#batterie
    "#a5b4b8",#import
    "#f5b300",#nucleaire
    "#aad6e0",#gaz 
    "#694d30",#lignite
    "#292525",#charbon 
    "#3d607d",#fioul
    "#b4822b",#autre thermiques 
    "#166a57",#autres renouvelables
    "#74cfa0",#eolien 
    "#f27406",#solaire
    "#2772b2"#hydraulique  
  ),
  lines = alist(
    "Total load" = LOAD - {if(exists("P2G", inherits = FALSE)){P2G} else {0}} - {if(exists("EV", inherits = FALSE)){EV} else {0}},
    "Power to Gas" = - {if(exists("P2G", inherits = FALSE)){P2G} else {0}},
    "Electric Vehicle" = - {if(exists("EV", inherits = FALSE)){EV} else {0}},
    "generation" = NUCLEAR + LIGNITE + COAL + GAS + OIL + `MIX. FUEL` +
      `MISC. DTG` + WIND + SOLAR + `H. ROR` + `H. STOR` +
      `MISC. NDG` + 
      {if(exists("PSP_POS", inherits = FALSE)){PSP_POS} else {0}} + 
      {if(exists("PSP_Closed_POS", inherits = FALSE)){PSP_Closed_POS} else {0}} + 
      {if(exists("BATT_POS", inherits = FALSE)){BATT_POS} else {0}} - `SPIL. ENRG`),
  lineColors = c(
    "#005542",#Consommation totale
    "#b2e34f",#Power to gaz
    "#e0d61d",#Vehicule électrique
    "#e5007d"),#Production	
  lineWidth = 2
)
rmVA_prodVars <- unique(
  c(
    "LOAD", 
    paste0(
      rep(c("PSP", "PSP_Closed", "BATT", "DSR", "EV", "P2G", "H2"), each = 3), 
      c("", "_POS", "_NEG")
    ),
    getAlias("rmVA_production")
  )
)