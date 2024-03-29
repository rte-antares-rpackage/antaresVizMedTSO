tabPanel("Production",
         fluidRow(
           column(12,
                  conditionalPanel(condition = "output.have_data",
                                   conditionalPanel(condition = "output.have_data_areas",
                                                    # br(), br(),
                                                    uiOutput("prodStack_ui"), 
                                                    tags$hr(),
                                                    uiOutput("ui_load_prod_stack")
                                   ),
                                   conditionalPanel(condition = "output.have_data_areas === false",
                                                    h3(textOutput("no_areas_1"))
                                   )
                  ),
                  conditionalPanel(condition = "output.have_data === false",
                                   h3(textOutput("no_data_1"))
                  )
           )
         )
)