observe({
  ind_keep_list_data <- ind_keep_list_data()
  language <- current_language$language
  isolate({
    if(input$update_module > 0){
      if(is.null(ind_keep_list_data)){
        showModal(modalDialog(
          easyClose = TRUE,
          footer = NULL,
          "No study selected"
        ))
      } else {
        # plotts and prodStack and exchangesStack
        ind_areas <- ind_keep_list_data$ind_areas
        refStudy <- ind_keep_list_data$refStudy
        if(length(ind_areas) > 0){
          # init / re-init module prodStack
          id_prodStack <- paste0("prodStack_", round(runif(1, 1, 100000000)))
          
          # update shared input table
          input_data$data[grepl("^prodStack", input_id), input_id := paste0(id_prodStack, "-shared_", input)]
          
          output[["prodStack_ui"]] <- renderUI({
            if(packageVersion("manipulateWidget") < "0.11"){
              mwModuleUI(id = id_prodStack, height = "800px")
            } else {
              mwModuleUI(id = id_prodStack, height = 800, updateBtn = TRUE)
            }
          })
          
          if(packageVersion("manipulateWidget") < "0.11"){
            .compare <- input$sel_compare_prodstack
            if(input$sel_compare_mcyear){
              .compare <- unique(c(.compare, "mcYear"))
            }
            
            if(length(.compare) > 0){
              list_compare <- vector("list", length(.compare))
              names(list_compare) <- .compare
              # set main with study names
              if(length(ind_areas) != 1){
                list_compare$main <- names(list_data_all$antaresDataList[ind_areas])
              }
              .compare <- list_compare
            } else {
              if(length(ind_areas) > 1){
                .compare <- list(main = names(list_data_all$antaresDataList[ind_areas]))
              } else {
                .compare = NULL
              }
            }
          } else {
            .compare <- NULL
          }
          
          if("areas" %in% names(list_data_all$antaresDataList[[ind_areas[1]]])){
            init_area <- list_data_all$antaresDataList[[ind_areas[1]]]$areas$area[1]
          } else {
            init_area <- list_data_all$antaresDataList[[ind_areas[1]]]$area[1]
          }
          
          prodStack_args <- list( 
            x = list_data_all$antaresDataList[ind_areas], 
            areas = init_area,
            refStudy = refStudy,
            xyCompare = "union",
            h5requestFiltering = list_data_all$params[ind_areas],
            unit = "GWh", 
            interactive = TRUE, 
            .updateBtn = TRUE, 
            language = language,
            .exportBtn = FALSE, 
            .exportType = c("html2canvas"),
            compare = .compare, 
            .runApp = FALSE
          )
          
          if(packageVersion("manipulateWidget") < "0.11"){
            prodStack_args$.updateBtnInit <- TRUE
          }
          
          mod_prodStack <- do.call(antaresVizMedTSO::prodStack, prodStack_args)
          
          if("MWController" %in% class(modules$prodStack)){
            modules$prodStack$clear()
          }
          
          modules$prodStack <- mod_prodStack
          modules$id_prodStack <- id_prodStack
          modules$init_prodStack <- TRUE
          
          # init / re-init module plotts
          id_ts <- paste0("plotts_", round(runif(1, 1, 100000000)))
          
          # update shared input table
          input_data$data[grepl("^plotts", input_id), input_id := paste0(id_ts, "-shared_", input)]
          
          output[["plotts_ui"]] <- renderUI({
            if(packageVersion("manipulateWidget") < "0.11"){
              mwModuleUI(id = id_ts, height = "800px")
            } else {
              mwModuleUI(id = id_ts, height = 800, updateBtn = TRUE)
            }
          })
          
          if(packageVersion("manipulateWidget") < "0.11"){
            .compare <- input$sel_compare_tsPlot
            if(input$sel_compare_mcyear){
              .compare <- unique(c(.compare, "mcYear"))
            }
            
            if(length(.compare) > 0){
              list_compare <- vector("list", length(.compare))
              names(list_compare) <- .compare
              # set main with study names
              if(length(ind_areas) != 1){
                list_compare$main <- names(list_data_all$antaresDataList[ind_areas])
              }
              .compare <- list_compare
            } else {
              if(length(ind_areas) > 1){
                .compare <- list(main = names(list_data_all$antaresDataList[ind_areas]))
              } else {
                .compare = NULL
              }
            }
          } else {
            .compare <- NULL
          }
          
          plotTS_args <- list( 
            x = list_data_all$antaresDataList[ind_areas], 
            refStudy = refStudy, 
            xyCompare = "union",
            h5requestFiltering = list_data_all$params[ind_areas],
            interactive = TRUE, 
            .updateBtn = TRUE, 
            language = language,
            .exportBtn = TRUE, 
            .exportType = c("html2canvas"),
            compare = .compare, 
            .runApp = FALSE
          )
          
          if(packageVersion("manipulateWidget") < "0.11"){
            plotTS_args$.updateBtnInit <- TRUE
          }
          
          mod_plotts <- do.call(antaresVizMedTSO::tsPlot, plotTS_args)
          
          if("MWController" %in% class(modules$plotts)){
            modules$plotts$clear()
          }
          
          modules$plotts <- mod_plotts
          modules$id_plotts <- id_ts
          modules$init_plotts <- TRUE
          
          list_data_controls$n_areas <- length(ind_areas)
          list_data_controls$have_areas <- TRUE
        } else {
          list_data_controls$have_areas <- FALSE
        }
        
        # exchange
        ind_links <- ind_keep_list_data$ind_links
        if(length(ind_links) > 0){
          # init / re-init module exchangesStack
          id_exchangesStack  <- paste0("exchangesStack_", round(runif(1, 1, 100000000)))
          
          # update shared input table
          input_data$data[grepl("^exchangesStack", input_id), input_id := paste0(id_exchangesStack, "-shared_", input)]
          
          output[["exchangesStack_ui"]] <- renderUI({
            if(packageVersion("manipulateWidget") < "0.11"){
              mwModuleUI(id = id_exchangesStack, height = "800px")
            } else {
              mwModuleUI(id = id_exchangesStack, height = 800, updateBtn = TRUE)
            }
          })
          
          if(packageVersion("manipulateWidget") < "0.11"){
            .compare <- input$sel_compare_exchangesStack
            if(input$sel_compare_mcyear){
              .compare <- unique(c(.compare, "mcYear"))
            }
            
            if(length(.compare) > 0){
              list_compare <- vector("list", length(.compare))
              names(list_compare) <- .compare
              # set main with study names
              if(length(ind_links) != 1){
                list_compare$main <- names(list_data_all$antaresDataList[ind_links])
              }
              .compare <- list_compare
            } else {
              if(length(ind_links) > 1){
                .compare <- list(main = names(list_data_all$antaresDataList[ind_links]))
              } else {
                .compare = NULL
              }
            }
          } else {
            .compare <- NULL
          }
          exchangeStack_args <- list( 
            x = list_data_all$antaresDataList[ind_links], 
            refStudy = refStudy,
            xyCompare = "union",
            h5requestFiltering = list_data_all$params[ind_links],
            interactive = TRUE, 
            .updateBtn = TRUE, 
            language = language, 
            .exportBtn = TRUE, 
            .exportType = c("html2canvas"),
            compare = .compare, 
            .runApp = FALSE
          )
          
          if(packageVersion("manipulateWidget") < "0.11"){
            exchangeStack_args$.updateBtnInit <- TRUE
          }
          
          mod_exchangesStack <- do.call(antaresVizMedTSO::exchangesStack, exchangeStack_args)
          
          if("MWController" %in% class(modules$exchangesStack)){
            modules$exchangesStack$clear()
          }
          
          modules$exchangesStack <- mod_exchangesStack
          modules$id_exchangesStack <- id_exchangesStack
          modules$init_exchangesStack <- TRUE
          
          # save data and params
          list_data_controls$n_links <- length(ind_links)
          list_data_controls$have_links <- TRUE
        } else {
          list_data_controls$have_links <- FALSE
        }
        
        if(!list_data_controls$have_areas & !list_data_controls$have_links){
          showModal(modalDialog(
            easyClose = TRUE,
            footer = NULL,
            "No study with at least one area and/or link selected"
          ))
        }
      }
    }
    
    input_data$cpt <- isolate(input_data$cpt) +1
  })
})

# call module when click on tab if needed
observe({
  modules$init_prodStack
  if(input[['nav-id']] == "Production"){
    isolate({
      if("MWController" %in% class(modules$prodStack) & modules$init_prodStack){
        modules$prodStack <- mwModule(id = modules$id_prodStack,  modules$prodStack)
        modules$init_prodStack <- FALSE
      }
    })
  }
})


observe({
  modules$init_plotts
  if(input[['nav-id']] == "<div id=\"label_tab_tsPlot\" class=\"shiny-text-output\"></div>"){
    isolate({
      if("MWController" %in% class(modules$plotts) & modules$init_plotts){
        modules$plotts <- mwModule(id = modules$id_plotts,  modules$plotts)
        modules$init_plotts <- FALSE
      }
    })
  }
})

observe({
  modules$init_exchangesStack
  if(input[['nav-id']] == "<div id=\"label_tab_exchanges\" class=\"shiny-text-output\"></div>"){
    isolate({
      if("MWController" %in% class(modules$exchangesStack) & modules$init_exchangesStack){
        modules$exchangesStack <- mwModule(id = modules$id_exchangesStack,  modules$exchangesStack)
        modules$init_exchangesStack <- FALSE
      }
    })
  }
})


# control : have link in data
output$have_data_links <- reactive({
  list_data_controls$have_links
})
outputOptions(output, "have_data_links", suspendWhenHidden = FALSE)

# control : have areas in data
output$have_data_areas <- reactive({
  list_data_controls$have_areas
})
outputOptions(output, "have_data_areas", suspendWhenHidden = FALSE)

# change page
observe({
  if(input$update_module > 0){
    if(list_data_controls$have_areas & list_data_controls$n_areas >= 1){
      updateNavbarPage(session, inputId = "nav-id", selected = "Production")
    } else if(list_data_controls$have_links & list_data_controls$n_links >= 1){
      updateNavbarPage(session, inputId = "nav-id", selected = "<div id=\"label_tab_exchanges\" class=\"shiny-text-output\"></div>")
    }
  }
})

# prodStack : load new stack definition
output$ui_load_prod_stack <- renderUI({
  fluidRow(
    column(width = 6, offset = 3, 
           div(
             shinyFilesButton("file_load_prod_stack", 
                              label = antaresVizMedTSO:::.getLabelLanguage("Import new production stack configuration (.R)", current_language$language), 
                              title= NULL, 
                              icon = icon("upload"),
                              multiple = FALSE, viewtype = "detail"), align = "center")     
           
    )
  )
})

shinyFileChoose(input, "file_load_prod_stack", 
                roots = volumes, 
                session = session, 
                filetypes = c("R", "r"), 
                defaultRoot = {
                  if(!is.null(file_load_prod_stack) && file_load_prod_stack != "" && paste0(strsplit(file_load_prod_stack, "/")[[1]][1], "/") %in% names(volumes)){
                    paste0(strsplit(file_load_prod_stack, "/")[[1]][1], "/")
                  } else {
                    NULL
                  }
                },
                defaultPath = {
                  if(!is.null(file_load_prod_stack) && file_load_prod_stack != "" && paste0(strsplit(file_load_prod_stack, "/")[[1]][1], "/") %in% names(volumes)){
                    if(file.exists(file_load_prod_stack)){
                      paste0(strsplit(file_load_prod_stack, "/")[[1]][-1], collapse = "/")
                    } else {
                      NULL
                    }
                  } else {
                    NULL
                  }
                }
)

load_prod_stack_rv <- reactiveVal(file_load_prod_stack)

observe({
  file_sel <- shinyFiles::parseFilePaths(volumes, input$file_load_prod_stack)
  if("data.frame" %in% class(file_sel) && nrow(file_sel) == 0) file_sel <- NULL
  isolate({
    current_language <- current_language$language
    if (!is.null(file_sel)){
      # save path in default conf
      conf <- tryCatch(yaml::read_yaml("default_conf.yml"), error = function(e) NULL)
      if(!is.null(conf)){
        conf$file_load_prod_stack <- file_sel$datapath
        tryCatch({
          yaml::write_yaml(conf, file = "default_conf.yml")
        }, error = function(e) NULL)
      }
      load_prod_stack_rv(file_sel$datapath)
    }
  })
})

observe({
  req(load_prod_stack_rv())
  src_path <- load_prod_stack_rv()
  if(file.exists(src_path)){
    check_src <- 
      tryCatch({
        source(src_path, encoding = "UTF-8")
      }, error = function(e){
        showModal(modalDialog(
          title = "Error importing new production stack",
          easyClose = TRUE,
          footer = NULL,
          paste("Please verify your .R script : ", e$message, sep = "\n")
        ))
        NULL
      })
    
    if(!is.null(check_src)){
      
      if(!init_file_load_prod_stack){
        showModal(modalDialog(
          title = "New production stack imported !",
          easyClose = TRUE,
          footer = NULL,
          "No error sourcing .R script"
        ))
      } else {
        init_file_load_prod_stack <<- FALSE
      }

      # udpate prodStack 
      isolate({
        ind_keep_list_data <- ind_keep_list_data()
        language <- current_language$language
        if(!is.null(ind_keep_list_data)){
          ind_areas <- ind_keep_list_data$ind_areas
          refStudy <- ind_keep_list_data$refStudy
          if(length(ind_areas) > 0){
            # init / re-init module prodStack
            id_prodStack <- paste0("prodStack_", round(runif(1, 1, 100000000)))
            
            # update shared input table
            input_data$data[grepl("^prodStack", input_id), input_id := paste0(id_prodStack, "-shared_", input)]
            
            output[["prodStack_ui"]] <- renderUI({
              if(packageVersion("manipulateWidget") < "0.11"){
                mwModuleUI(id = id_prodStack, height = "800px")
              } else {
                mwModuleUI(id = id_prodStack, height = 800, updateBtn = TRUE)
              }
            })
            
            if(packageVersion("manipulateWidget") < "0.11"){
              .compare <- input$sel_compare_prodstack
              if(input$sel_compare_mcyear){
                .compare <- unique(c(.compare, "mcYear"))
              }
              
              if(length(.compare) > 0){
                list_compare <- vector("list", length(.compare))
                names(list_compare) <- .compare
                # set main with study names
                if(length(ind_areas) != 1){
                  list_compare$main <- names(list_data_all$antaresDataList[ind_areas])
                }
                .compare <- list_compare
              } else {
                if(length(ind_areas) > 1){
                  .compare <- list(main = names(list_data_all$antaresDataList[ind_areas]))
                } else {
                  .compare = NULL
                }
              }
            } else {
              .compare <- NULL
            }
            
            if("areas" %in% names(list_data_all$antaresDataList[[ind_areas[1]]])){
              init_area <- list_data_all$antaresDataList[[ind_areas[1]]]$areas$area[1]
            } else {
              init_area <- list_data_all$antaresDataList[[ind_areas[1]]]$area[1]
            }
            
            prodStack_args <- list( 
              x = list_data_all$antaresDataList[ind_areas], 
              areas = init_area,
              refStudy = refStudy,
              xyCompare = "union",
              h5requestFiltering = list_data_all$params[ind_areas],
              unit = "GWh", 
              interactive = TRUE, 
              .updateBtn = TRUE, 
              language = language,
              .exportBtn = FALSE, 
              .exportType = c("html2canvas"),
              compare = .compare, 
              .runApp = FALSE
            )
            
            if(packageVersion("manipulateWidget") < "0.11"){
              prodStack_args$.updateBtnInit <- TRUE
            }
            
            mod_prodStack <- do.call(antaresVizMedTSO::prodStack, prodStack_args)
            
            if("MWController" %in% class(modules$prodStack)){
              modules$prodStack$clear()
            }
            
            modules$prodStack <- mod_prodStack
            modules$id_prodStack <- id_prodStack
            modules$init_prodStack <- TRUE
          }
        }
      })
    } 
  }
})
