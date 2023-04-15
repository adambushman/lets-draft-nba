server <- function(input, output, session) {
  
  # Updated data
  rankings_update <-
    draft_rankings %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    )
  
  
  observeEvent(input$run_sim, {
    removeUI(
      selector = ".form-group .shiny-input-container"
    )
    
    shinyalert(
      title = "<Team X> is on the clock!",
      text = "Select a player from the 'On the Board' tab and click the 'Draft' button",
      size = "s", 
      closeOnEsc = TRUE,
      closeOnClickOutside = FALSE,
      html = FALSE,
      type = "",
      showConfirmButton = TRUE,
      showCancelButton = FALSE,
      confirmButtonText = "OK",
      confirmButtonCol = "#1D428A",
      timer = 0,
      imageUrl = "https://www.sportsmediawatch.com/wp-content/uploads/2018/06/nbadraftlogo.png",
      imageWidth = 350,
      imageHeight = 175,
      animation = TRUE
    )
  })
  
  output$board_left <- renderDT({
      datatable(
        get_available(draft_rankings, input$used_sources) %>% select(Player, med_rank), 
        rownames = FALSE,
        selection = 'single',
        options = list(
          dom = 'ft',
          pageLength = -1,
          initComplete = JS(
           "function(settings, json) {",
           "$(this.api().table().header()).css({'background-color': '#c8102e', 'color': '#FFFFFF'});",
           "}")
          ), 
        colnames = c("Player", "Median Rank")
      )
    })
  
  output$selected_picks <- renderDT({
    datatable(
      selected_picks, 
      rownames = FALSE,
      selection = "none",
      options = list(
        dom = 'ft',
        pageLength = -1,
        initComplete = JS(
          "function(settings, json) {",
          "$(this.api().table().header()).css({'background-color': '#c8102e', 'color': '#FFFFFF'});",
          "}")
      ), 
      colnames = c("Pick", "Team", "Player")
    )
  })
  
}