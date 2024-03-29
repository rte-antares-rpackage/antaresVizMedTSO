#----------------
# set / read data
#----------------

shinyDirChoose(input, "directory", 
               roots = volumes, 
               session = session, 
               defaultRoot = {
                 if(!is.null(study_dir) && study_dir != ""){
                   study_path <- strsplit(study_dir, "/")[[1]]
                   study_path <- paste0(study_path[-length(study_path)], collapse = "/")
                   if(study_path %in% volumes){
                     "Antares"
                   } else if (paste0(strsplit(study_dir, "/")[[1]][1], "/") %in% names(volumes)){
                     paste0(strsplit(study_dir, "/")[[1]][1], "/")
                   } else {
                     NULL
                   }
                 } else {
                   NULL
                 }
               })

rv_directory <- reactiveVal(study_dir)

observe({
  if (!is.null(input$directory) && !is.integer(input$directory)) {
    rv_directory(as.character(shinyFiles::parseDirPath(volumes, input$directory)))
  }
})

output$print_directory <- renderPrint({
  rv_directory()
})

observe({
  val <- rv_directory()
  if(!is.null(val) && val != ""){
    if(!isTRUE(all.equal(isolate(rv_directory_medtso_maps()), val))){
      rv_directory_medtso_maps(val)
    }
    if(!isTRUE(all.equal(isolate(rv_directory_format_output()), val))){
      rv_directory_format_output(val)
    }
  }
})
# # observe directory 
# observeEvent(
#   ignoreNULL = TRUE,
#   eventExpr = {
#     input$directory
#   },
#   handlerExpr = {
#     if (input$directory > 0) {
#       # condition prevents handler execution on initial app launch
#       path = choose.dir(default = readDirectoryInput(session, 'directory'))
#       updateDirectoryInput(session, 'directory', value = path)
#     }
#   }
# )

# output$directory_message <- renderText({
#   if(length(input$directory) > 0){
#     if(input$directory == 0){
#       antaresVizMedTSO:::.getLabelLanguage("Please first choose a folder with antares output", current_language$language)
#     } else {
#       antaresVizMedTSO:::.getLabelLanguage("No antares output found in directory", current_language$language)
#     }
#   }
# })


output$directory_message <- renderText({
  if(!is.null(input$directory) || is.integer(input$directory)){
    antaresVizMedTSO:::.getLabelLanguage("Please first choose a folder with antares output", current_language$language)
  } else {
    antaresVizMedTSO:::.getLabelLanguage("No antares output found in directory", current_language$language)
  }
})

# list files in directory
dir_files <- reactive({
  # path <- readDirectoryInput(session, 'directory')
  path <- rv_directory()
  if(!is.null(path)){
    # save path in default conf
    conf <- tryCatch(yaml::read_yaml("default_conf.yml"), error = function(e) NULL)
    if(!is.null(conf)){
      conf$study_dir <- path
      tryCatch({
        yaml::write_yaml(conf, file = "default_conf.yml")
      }, error = function(e) NULL)
    }
    
    files = list.files(path, full.names = T)
    data.frame(name = basename(files), file.info(files))
  } else {
    NULL
  }
})

# have antares study in directory ?
is_antares_results <- reactive({
  dir_files <- dir_files()
  is_h5 <- any(grepl(".h5$", dir_files$name))
  is_study <- all(c("output", "study.antares") %in% dir_files$name)
  list(is_h5 = is_h5, is_study = is_study)
})

output$ctrl_is_antares_study <- reactive({
  is_antares_results()$is_study
})

output$ctrl_is_antares_h5 <- reactive({
  is_antares_results()$is_h5
})

outputOptions(output, "ctrl_is_antares_study", suspendWhenHidden = FALSE)
outputOptions(output, "ctrl_is_antares_h5", suspendWhenHidden = FALSE)

# if have study, update selectInput list
observe({
  is_antares_results <- is_antares_results()
  if(is_antares_results$is_h5 | is_antares_results$is_study){
    isolate({
      if(is_antares_results$is_study){
        # files = list.files(paste0(readDirectoryInput(session, 'directory'), "/output"), full.names = T)
        files = list.files(file.path(rv_directory(), "output"), full.names = T)
      } 
      if(is_antares_results$is_h5){
        # files = list.files(readDirectoryInput(session, 'directory'), pattern = ".h5$", full.names = T)
        files = list.files(file.path(rv_directory()), full.names = T)
      } 
      if(length(files) > 0){
        files <- data.frame(name = basename(files), file.info(files))
        choices <- rownames(files)
        names(choices) <- files$name
      } else {
        choices <- NULL
      }
      updateSelectInput(session, "study_path", "", choices = choices)
    })
  }
})

observe({
  val <- input$study_path
  if(!is.null(val) && val != ""){
    if(!isTRUE(all.equal(isolate(input$study_path_medtso_maps), val))){
      updateSelectInput(session, "study_path_medtso_maps", selected =  val)
    }
    if(!isTRUE(all.equal(isolate(input$study_path_format_output), val))){
      updateSelectInput(session, "study_path_format_output", selected =  val)
    }
  }
})


# init opts after validation
opts <- reactive({
  if(input$init_sim > 0){
    opts <- 
      tryCatch({
        setSimulationPath(isolate(input$study_path))
      }, error = function(e){
        showModal(modalDialog(
          title = "Error setting file",
          easyClose = TRUE,
          footer = NULL,
          paste("Directory/file is not an Antares study : ", e$message, sep = "\n")
        ))
        NULL
      })
    if(!is.null(opts)){
      if(is.null(opts$h5)){
        opts$h5 <- FALSE
      }
      # bad h5 control
      if(opts$h5){
        if(length(setdiff(names(opts), c("h5", "h5path"))) == 0){
          showModal(modalDialog(
            easyClose = TRUE,
            footer = NULL,
            "Invalid h5 file : not an Antares study."
          ))
          opts <- NULL
        }
      }
    }
    opts
  } else {
    NULL
  }
})

output$current_opts_h5 <- reactive({
  opts()$h5
})

outputOptions(output, "current_opts_h5", suspendWhenHidden = FALSE)

current_study_path <- reactive({
  if(input$init_sim > 0){
    rev(unlist(strsplit(isolate(input$study_path), "/")))[1]
  }
})


# control : have not null opts ?
output$have_study <- reactive({
  !is.null(opts())
})

outputOptions(output, "have_study", suspendWhenHidden = FALSE)

#--------------------------------------
# update readAntares / opts parameters
#--------------------------------------
observe({
  opts <- opts()
  current_language <- current_language$language
  if(!is.null(opts)){
    isolate({
      # areas
      areas <- c("all", opts$areaList)
      if(isTRUE(all.equal(c("all"), areas))) areas <- c("", "all")
      updateSelectInput(session, "read_areas", paste0(antaresVizMedTSO:::.getLabelLanguage("Areas", current_language), " : "), 
                        choices = areas, selected = areas[1])
      
      # links
      links <- c("all", opts$linkList)
      if(isTRUE(all.equal(c("all"), links))) links <- c("", "all")
      updateSelectInput(session, "read_links", paste0(antaresVizMedTSO:::.getLabelLanguage("Links", current_language), " : "), 
                        choices = links, selected = links[1])
      
      # clusters
      clusters <- c("all", opts$areasWithClusters)
      if(isTRUE(all.equal(c("all"), clusters))) clusters <- c("", "all")
      updateSelectInput(session, "read_clusters", paste0(antaresVizMedTSO:::.getLabelLanguage("Clusters", current_language), " : "), 
                        choices = clusters, selected = clusters[1])
      
      # clustersRes
      clustersRes <- c("all", opts$areasWithResClusters)
      if(isTRUE(all.equal(c("all"), clustersRes))) clustersRes <- c("", "all")
      updateSelectInput(session, "read_clusters_res", paste0(antaresVizMedTSO:::.getLabelLanguage("ClustersRes", current_language), " : "), 
                        choices = clustersRes, selected = clustersRes[1])
      
      # districts
      districts <- c("all", opts$districtList)
      if(isTRUE(all.equal(c("all"), districts))) districts <- c("", "all")
      updateSelectInput(session, "read_districts", paste0(antaresVizMedTSO:::.getLabelLanguage("Districts", current_language), " : "), 
                        choices = districts, selected = districts[1])
      
      # mcYears
      mcy <- c(opts$mcYears)
      updateSelectInput(session, "read_mcYears", paste0(antaresVizMedTSO:::.getLabelLanguage("mcYears", current_language), " : "), 
                        choices = mcy, selected = mcy[1])
      
      # select
      slt <- unique(do.call("c", opts$variables))
      updateSelectInput(session, "read_select", paste0(antaresVizMedTSO:::.getLabelLanguage("Select", current_language), " : "), 
                        choices = slt, selected = NULL)
      
      # removeVirtualAreas
      updateCheckboxInput(session, "rmva_ctrl", antaresVizMedTSO:::.getLabelLanguage("enabled", current_language), FALSE)
      updateCheckboxInput(session, "rmva_ctrl_2", value = FALSE)
      updateCheckboxInput(session, "rmva_ctrl_3", value = FALSE)
      
      for(ii in rm_storage_input_import_final){
        updateSelectInput(session, ii, choices = opts$areaList, selected = NULL)
      }
      
      updateSelectInput(session, "rmva_production", paste0(antaresVizMedTSO:::.getLabelLanguage("production", current_language), " : "),
                        choices = opts$areaList, selected = NULL)
      updateSelectInput(session, "rmva_production_2", paste0(antaresVizMedTSO:::.getLabelLanguage("production", current_language), " : "),
                        choices = opts$areaList, selected = NULL)
      updateSelectInput(session, "rmva_production_3", paste0(antaresVizMedTSO:::.getLabelLanguage("production", current_language), " : "),
                        choices = opts$areaList, selected = NULL)
      
      updateCheckboxInput(session, "rmva_reassignCosts", antaresVizMedTSO:::.getLabelLanguage("reassignCosts", current_language), FALSE)
      updateCheckboxInput(session, "rmva_newCols", antaresVizMedTSO:::.getLabelLanguage("newCols", current_language), FALSE)
      
      updateCheckboxInput(session, "rmva_reassignCosts_2", antaresVizMedTSO:::.getLabelLanguage("reassignCosts", current_language), FALSE)
      updateCheckboxInput(session, "rmva_newCols_2", antaresVizMedTSO:::.getLabelLanguage("newCols", current_language), FALSE)
      
      updateCheckboxInput(session, "rmva_reassignCosts_3", antaresVizMedTSO:::.getLabelLanguage("reassignCosts", current_language), FALSE)
      updateCheckboxInput(session, "rmva_newCols_3", antaresVizMedTSO:::.getLabelLanguage("newCols", current_language), FALSE)
      
      updateSelectInput(session, "rmva_storageFlexibility_h5", choices = opts$areaList, selected = NULL)
      updateSelectInput(session, "rmva_production_h5", paste0(antaresVizMedTSO:::.getLabelLanguage("production", current_language), " : "), 
                        choices = opts$areaList, selected = NULL)
      
      # reset checkBox 
      updateCheckboxInput(session, "read_misc", antaresVizMedTSO:::.getLabelLanguage("misc", current_language), FALSE)
      updateCheckboxInput(session, "read_reserve", antaresVizMedTSO:::.getLabelLanguage("reserve", current_language), FALSE)
      
      updateCheckboxInput(session, "read_thermalAvailabilities", 
                          antaresVizMedTSO:::.getLabelLanguage("thermalAvailabilities", current_language), FALSE)
      updateCheckboxInput(session, "read_linkCapacity", 
                          antaresVizMedTSO:::.getLabelLanguage("linkCapacity", current_language), FALSE)
      
      
      updateCheckboxInput(session, "read_hydroStorage", 
                          antaresVizMedTSO:::.getLabelLanguage("hydroStorage", current_language), FALSE)
      updateCheckboxInput(session, "read_mustRun", 
                          antaresVizMedTSO:::.getLabelLanguage("mustRun", current_language), FALSE)
      
      updateCheckboxInput(session, "read_hydroStorageMaxPower", 
                          antaresVizMedTSO:::.getLabelLanguage("hydroStorageMaxPower", current_language), FALSE)
      updateCheckboxInput(session, "read_thermalModulation", 
                          antaresVizMedTSO:::.getLabelLanguage("thermalModulation", current_language), FALSE)
      
      updateSelectInput(session, "read_timeStep", 
                        paste0(antaresVizMedTSO:::.getLabelLanguage("timeStep", current_language), " :"), 
                        choices = c("hourly", "daily", "weekly", "monthly", "annual"), selected = "hourly")
      
      if(!opts$parameters$general$`year-by-year`){
        choices <- c("synthetic")
        names(choices) <- sapply(choices, function(x){
          antaresVizMedTSO:::.getLabelLanguage(x, current_language)
        })
        updateRadioButtons(session, "read_type_mcYears", paste0(antaresVizMedTSO:::.getLabelLanguage("mcYears selection", current_language), " : "),
                           choices, selected = choices[1], inline = TRUE)
      } else {
        sel <- isolate({input$read_type_mcYears})
        if(opts$synthesis){
          choices <- c("synthetic", "all", "custom")
        } else {
          choices <- c("all", "custom")
          if(!sel %in% choices) sel <- "all"
        }
        names(choices) <- sapply(choices, function(x){
          antaresVizMedTSO:::.getLabelLanguage(x, current_language)
        })
        updateRadioButtons(session, "read_type_mcYears", paste0(antaresVizMedTSO:::.getLabelLanguage("mcYears selection", current_language), " : "),
                           choices, selected = choices[1], inline = TRUE)
      }
    })
  }
})

output$ui_sel_file <- renderUI({
  current_language <- current_language$language
  input$init_sim # clear if change simulation
  fluidRow(
    column(4, 
           # div(fileInput("file_sel", antaresVizMedTSO:::.getLabelLanguage("Import a selection file (.xlsx)", current_language),
           #               accept = c("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")), align = "center")
           
           div(
             shinyFilesButton("file_sel", 
                              label = antaresVizMedTSO:::.getLabelLanguage("Import a selection file (.xlsx)", current_language), 
                              title= NULL, 
                              icon = icon("upload"),
                              multiple = FALSE, viewtype = "detail"),
             align = "center", style = "margin-top:20px")
    ), 
    column(4, 
           div( br(),
                tags$a(href = "readAntares_selection.xlsx", 
                       antaresVizMedTSO:::.getLabelLanguage("Download selection file template", current_language), 
                       class="btn btn-default", download = "readAntares_selection.xlsx"),
                align = "center"
           )
    ), 
    column(4, 
           div( br(),
                downloadButton("get_sel_file",
                               antaresVizMedTSO:::.getLabelLanguage("Generate current selection file", current_language), 
                               class = NULL),
                align = "center"
           )
    )
  )
})
observe({
  RL <- input$read_links
  current_language <- current_language$language
  isolate({
    if(!is.null(RL)) {
      if(length(RL) == 0) {
        updateCheckboxInput(session, "read_linkCapacity", antaresVizMedTSO:::.getLabelLanguage("linkCapacity", current_language), FALSE)
      }
    } else {
      updateCheckboxInput(session, "read_linkCapacity", antaresVizMedTSO:::.getLabelLanguage("linkCapacity", current_language), FALSE)
    }
  })
  
})

observe({
  RC <- input$read_clusters
  opts <- opts()
  current_language <- current_language$language
  isolate({
    if(!is.null(RC)) {
      if(length(RC) == 0) {
        updateCheckboxInput(session, "read_thermalAvailabilities", 
                            antaresVizMedTSO:::.getLabelLanguage("thermalAvailabilities", current_language), FALSE)
        updateCheckboxInput(session, "read_thermalModulation", 
                            antaresVizMedTSO:::.getLabelLanguage("thermalModulation", current_language), FALSE)
      }
    } else {
      updateCheckboxInput(session, "read_thermalAvailabilities", 
                          antaresVizMedTSO:::.getLabelLanguage("thermalAvailabilities", current_language), FALSE)
      updateCheckboxInput(session, "read_thermalModulation", 
                          antaresVizMedTSO:::.getLabelLanguage("thermalModulation", current_language), FALSE)
    }
  })
  
})

observe({
  current_language <- current_language$language
  opts <- isolate(opts())
  if(!is.null(current_language) & !is.null(opts)) {
    isolate({
      if(!opts$parameters$general$`year-by-year`){
        sel <- isolate({input$read_type_mcYears})
        choices <- c("synthetic")
        names(choices) <- sapply(choices, function(x){
          antaresVizMedTSO:::.getLabelLanguage(x, current_language)
        })
        updateRadioButtons(session, "read_type_mcYears", paste0(antaresVizMedTSO:::.getLabelLanguage("mcYears selection", current_language), " : "),
                           choices, selected = sel, inline = TRUE)
        updateCheckboxInput(session, "read_hydroStorage", antaresVizMedTSO:::.getLabelLanguage("hydroStorage", current_language), FALSE)
      } else {
        sel <- isolate({input$read_type_mcYears})
        if(opts$synthesis){
          choices <- c("synthetic", "all", "custom")
        } else {
          choices <- c("all", "custom")
          if(!sel %in% choices) sel <- "all"
        }
        names(choices) <- sapply(choices, function(x){
          antaresVizMedTSO:::.getLabelLanguage(x, current_language)
        })
        updateRadioButtons(session, "read_type_mcYears", paste0(antaresVizMedTSO:::.getLabelLanguage("mcYears selection", current_language), " : "),
                           choices, selected = sel, inline = TRUE)
      }
    })
  }
})

shinyFileChoose(input, "file_sel", 
                roots = volumes, 
                session = session, 
                filetypes = c("XLS", "xls", "xlsx", "XLSX"), 
                defaultRoot = {
                  if(!is.null(file_sel_import) && file_sel_import != "" && paste0(strsplit(file_sel_import, "/")[[1]][1], "/") %in% names(volumes)){
                    paste0(strsplit(file_sel_import, "/")[[1]][1], "/")
                  } else {
                    NULL
                  }
                },
                defaultPath = {
                  if(!is.null(file_sel_import) && file_sel_import != "" && paste0(strsplit(file_sel_import, "/")[[1]][1], "/") %in% names(volumes)){
                    if(file.exists(file_sel_import)){
                      paste0(strsplit(file_sel_import, "/")[[1]][-1], collapse = "/")
                    } else {
                      NULL
                    }
                  } else {
                    NULL
                  }
                })

# sélection à partir d'un fichier -----
observe({
  # file_sel <- input$file_sel
  file_sel <- shinyFiles::parseFilePaths(volumes, input$file_sel)
  if("data.frame" %in% class(file_sel) && nrow(file_sel) == 0) file_sel <- NULL
  isolate({
    current_language <- current_language$language
    if (!is.null(file_sel)){
      
      # save path in default conf
      conf <- tryCatch(yaml::read_yaml("default_conf.yml"), error = function(e) NULL)
      if(!is.null(conf)){
        conf$file_sel_import <- file_sel$datapath
        tryCatch({
          yaml::write_yaml(conf, file = "default_conf.yml")
        }, error = function(e) NULL)
      }
      
      withCallingHandlers({
        list_warning <- list() 
        list_sel <- tryCatch({ 
          antaresVizMedTSO::readStudyShinySelection(file_sel$datapath)},
          error = function(e){
            showModal(modalDialog(
              title = antaresVizMedTSO:::.getLabelLanguage("Error reading selection file", current_language),
              easyClose = TRUE,
              footer = NULL,
              e$message
            ))
            NULL
          })}, 
        warning = function(w){
          list_warning[[length(list_warning) + 1]] <<- w$message
        })
      
      if(length(list_warning) > 0 & !is.null(list_sel)){
        showModal(modalDialog(
          title = "Warning reading selection file",
          easyClose = TRUE,
          footer = NULL,
          HTML(paste0(unique(list_warning), collapse  = "<br><br>"))
        ))
      }
      
      if(!is.null(list_sel)){
        # areas
        updateSelectInput(session, "read_areas", selected = list_sel$areas)
        
        # links
        updateSelectInput(session, "read_links", selected = list_sel$links)
        
        # clusters
        updateSelectInput(session, "read_clusters", selected = list_sel[["clusters"]])
        
        # clustersRes
        updateSelectInput(session, "read_clusters_res", selected = list_sel[["clustersRes"]])
        
        # districts
        updateSelectInput(session, "read_districts", selected = list_sel$districts)
        
        updateCheckboxInput(session, "read_misc", value = list_sel$misc)
        updateCheckboxInput(session, "read_reserve", value = list_sel$reserve)
        updateCheckboxInput(session, "read_thermalAvailabilities", value = list_sel$thermalAvailability)
        updateCheckboxInput(session, "read_linkCapacity", value = list_sel$linkCapacity)
        updateCheckboxInput(session, "read_hydroStorage", value = list_sel$hydroStorage)
        updateCheckboxInput(session, "read_mustRun", value = list_sel$mustRun)
        updateCheckboxInput(session, "read_hydroStorageMaxPower", value = list_sel$hydroStorageMaxPower)
        updateCheckboxInput(session, "read_thermalModulation", value = list_sel$thermalModulation)
        
        updateSelectInput(session, "read_timeStep", selected = list_sel$timeStep)
        
        updateSelectInput(session, "read_select", selected = list_sel$select)
        
        mcy <- list_sel$mcYears
        if(!is.null(mcy)){
          updateRadioButtons(session, "read_type_mcYears", selected = "custom")
          updateSelectInput(session, "read_mcYears", selected = as.character(mcy))
        } else {
          updateRadioButtons(session, "read_type_mcYears", selected = "synthetic")
          updateSelectInput(session, "read_mcYears", selected = NULL)
        }
        
        # removeVirtualsAreas
        updateCheckboxInput(session, "rmva_ctrl", value = list_sel$removeVirtualAreas)
        updateCheckboxInput(session, "rmva_ctrl_2", value = list_sel$removeVirtualAreas_2)
        updateCheckboxInput(session, "rmva_ctrl_3", value = list_sel$removeVirtualAreas_3)
        
        updateCheckboxInput(session, "rmva_reassignCosts", value = list_sel$reassignCost)
        updateCheckboxInput(session, "rmva_reassignCosts_2", value = list_sel$reassignCost_2)
        updateCheckboxInput(session, "rmva_reassignCosts_3", value = list_sel$reassignCost_3)
        
        updateCheckboxInput(session, "rmva_newCols", value = list_sel$newCols)
        updateCheckboxInput(session, "rmva_newCols_2", value = list_sel$newCols_2)
        updateCheckboxInput(session, "rmva_newCols_3", value = list_sel$newCols_3)
        
        updateSelectInput(session, "rmva_production", selected = list_sel$production)
        updateSelectInput(session, "rmva_production_2", selected = list_sel$production_2)
        updateSelectInput(session, "rmva_production_3", selected = list_sel$production_3)
        
        updateSelectInput(session, "rmva_storageFlexibility", selected = list_sel$`storageFlexibility (PSP)`)
        updateSelectInput(session, "rmva_PSP_Closed", selected = list_sel$`Hydro Storage (PSP_Closed)`)
        updateSelectInput(session, "rmva_BATT", selected = list_sel$`Battery Storage (BATT)`)
        updateSelectInput(session, "rmva_DSR", selected = list_sel$`Demand Side (DSR)`)
        updateSelectInput(session, "rmva_EV", selected = list_sel$`Electric Vehicle (EV)`)
        updateSelectInput(session, "rmva_P2G", selected = list_sel$`Power-to-gas (P2G)`)
        updateSelectInput(session, "rmva_H2", selected = list_sel$`Hydrogen (H2)`)
        
        updateSelectInput(session, "rmva_storageFlexibility_2", selected = list_sel$`storageFlexibility (PSP)_2`)
        updateSelectInput(session, "rmva_PSP_Closed_2", selected = list_sel$`Hydro Storage (PSP_Closed)_2`)
        updateSelectInput(session, "rmva_BATT_2", selected = list_sel$`Battery Storage (BATT)_2`)
        updateSelectInput(session, "rmva_DSR_2", selected = list_sel$`Demand Side (DSR)_2`)
        updateSelectInput(session, "rmva_EV_2", selected = list_sel$`Electric Vehicle (EV)_2`)
        updateSelectInput(session, "rmva_P2G_2", selected = list_sel$`Power-to-gas (P2G)_2`)
        updateSelectInput(session, "rmva_H2_2", selected = list_sel$`Hydrogen (H2)_2`)
        
        updateSelectInput(session, "rmva_storageFlexibility_3", selected = list_sel$`storageFlexibility (PSP)_3`)
        updateSelectInput(session, "rmva_PSP_Closed_3", selected = list_sel$`Hydro Storage (PSP_Closed)_3`)
        updateSelectInput(session, "rmva_BATT_3", selected = list_sel$`Battery Storage (BATT)_3`)
        updateSelectInput(session, "rmva_DSR_3", selected = list_sel$`Demand Side (DSR)_3`)
        updateSelectInput(session, "rmva_EV_3", selected = list_sel$`Electric Vehicle (EV)_3`)
        updateSelectInput(session, "rmva_P2G_3", selected = list_sel$`Power-to-gas (P2G)_3`)
        updateSelectInput(session, "rmva_H2_3", selected = list_sel$`Hydrogen (H2)_3`)
        
      }
    }
  })
  
  output$get_sel_file <- downloadHandler(
    filename = function() {
      paste('readAntares_selection_', format(Sys.time(), format = "%Y%d%m_%H%M%S"), '.xlsx', sep='')
    },
    content = function(con) {
      
      mcYears = input$read_mcYears
      if(input$read_type_mcYears %in% "all"){
        mcYears = opts()$mcYears
      }
      if(input$read_type_mcYears %in% "synthetic"){
        mcYears = "synthetic"
      }
      params <- list(areas = input$read_areas, links = input$read_links, 
                     clusters = input$read_clusters, districts = input$read_districts, 
                     clustersRes = input$read_clusters_res, 
                     misc = input$read_misc, thermalAvailability = input$read_thermalAvailabilities, 
                     hydroStorage = input$read_hydroStorage, hydroStorageMaxPower = input$read_hydroStorageMaxPower, 
                     reserve = input$read_reserve, linkCapacity = input$read_linkCapacity, mustRun = input$read_mustRun, 
                     thermalModulation = input$read_thermalModulation, 
                     timeStep = input$read_timeStep, select = input$read_select, mcYears = mcYears, 
                     
                     removeVirtualAreas = input$rmva_ctrl,
                     "storageFlexibility (PSP)" = input$rmva_storageFlexibility, 
                     "Hydro Storage (PSP_Closed)" = input$rmva_PSP_Closed, 
                     "Battery Storage (BATT)"  = input$rmva_BATT,
                     "Demand Side (DSR)" = input$rmva_DSR, 
                     "Electric Vehicle (EV)" = input$rmva_EV,
                     "Power-to-gas (P2G)" = input$rmva_P2G, 
                     "Hydrogen (H2)" = input$rmva_H2,
                     production = input$rmva_production, 
                     reassignCost =  input$rmva_reassignCosts, 
                     newCols = input$rmva_newCols,
                     
                     removeVirtualAreas_2 = input$rmva_ctrl_2,
                     "storageFlexibility (PSP)_2" = input$rmva_storageFlexibility_2, 
                     "Hydro Storage (PSP_Closed)_2" = input$rmva_PSP_Closed_2, 
                     "Battery Storage (BATT)_2"  = input$rmva_BATT_2,
                     "Demand Side (DSR)_2" = input$rmva_DSR_2, 
                     "Electric Vehicle (EV)_2" = input$rmva_EV_2,
                     "Power-to-gas (P2G)_2" = input$rmva_P2G_2, 
                     "Hydrogen (H2)_2" = input$rmva_H2_2,
                     production_2 = input$rmva_production_2, 
                     reassignCost_2 =  input$rmva_reassignCosts_2, 
                     newCols_2 = input$rmva_newCols_2,
                     
                     removeVirtualAreas_3 = input$rmva_ctrl_3,
                     "storageFlexibility (PSP)_3" = input$rmva_storageFlexibility_3, 
                     "Hydro Storage (PSP_Closed)_3" = input$rmva_PSP_Closed_3, 
                     "Battery Storage (BATT)_3"  = input$rmva_BATT_3,
                     "Demand Side (DSR)_3" = input$rmva_DSR_3, 
                     "Electric Vehicle (EV)_3" = input$rmva_EV_3,
                     "Power-to-gas (P2G)_3" = input$rmva_P2G_3, 
                     "Hydrogen (H2)_3" = input$rmva_H2_3,
                     production_3 = input$rmva_production_3, 
                     reassignCost_3 =  input$rmva_reassignCosts_3, 
                     newCols_3 = input$rmva_newCols_3)
      
      writeStudyShinySelection(params, con)
      
      if(is_electron){
        showModal(modalDialog(
          antaresVizMedTSO:::.getLabelLanguage("File automatically downloaded in default folder", current_language),
          easyClose = TRUE,
          footer = NULL
        ))
      }
    }
  )
  
})