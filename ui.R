ui <- fluidPage(
  
  titlePanel("Let's Draft | NBA"),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput(
       "selection_teams", 
       "Choose team's you want to represent in the draft", 
       choices = sort(lottery_order$abb),
       multiple = TRUE
      ), 
      
      radioButtons(
       "sim_type",
       "Choose draft order type",
       choices = c(
         #"Simulate lottery", 
         "Use Tankathon order"
       )
      ),
      
      checkboxGroupInput(
       "used_sources", 
       "Select sources you want used in the simulation", 
       choices = sort(sources), 
       selected = sources
      ), 
      
      actionButton(
       "run_sim", 
       "Start"
      )
    ), 
    
    mainPanel(
      
      tabsetPanel(
        tabPanel(
          "On the Board", 
          DTOutput("board_left")
        ), 
        
        tabPanel(
          "Selected Picks", 
          DTOutput("selected_picks")
        )
      )
      
    )
    
  )
)