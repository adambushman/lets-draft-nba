server <- function(input, output, session) {
  
  # Updated data
  rankings_update <-
    draft_rankings %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    )
  
  player_board <- reactive({
    get_available(draft_rankings, input$used_sources) %>%
     select(Player, med_rank)
  })
  
  
  observeEvent(input$run_sim, {
    # Save input
    selection_teams = input$selection_teams
    used_sources = input$selection_teams
    
    # Adjust the UI
    removeUI(
      selector = "form:has(> .form-group)"
    )
    
    insertUI(
      selector = ".col-sm-4",
      where = "afterBegin",
      ui = sidebarPanel(
        tags$p(tags$strong("Select a player from below and click `Draft`")), 
        actionButton(
          "selection",
          "Draft Player"
        )
      )
    )
    
    use_gotop()
    
    # Execute the simulation
    
    prop_board = get_prob_board(draft_rankings, used_sources)
    draft_board = lottery_order
    
    for(i in 1:nrow(lottery_order)) {
      
      # Update available prospects
      
      unavailable <- draft_board$prospect[!is.na(draft_board$prospect)]
      
      left_over <- 
        max_rankings %>% 
        filter(m_pick <= i & !(Player %in% unavailable))
      
      # Make selection
      
      if(draft_order[i] %in% selection_teams) {
        # Pause for user entry
        
        shinyalert(
          title = glue("{draft_order[i]} is on the clock!"),
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
          timer = 500,
          imageUrl = "https://www.sportsmediawatch.com/wp-content/uploads/2018/06/nbadraftlogo.png",
          imageWidth = 350,
          imageHeight = 175,
          animation = TRUE
        )
        
        # selection = readline("Make your selection. Enter a number corresponding to the player above:")
        # 
        # board$prospect[length(unavailable)+1] = available$Player[as.integer(selection)]
      } 
      else if(nrow(left_over) > 0) {
        draft_board$prospect[length(unavailable)+1] = left_over$Player[1]
      }
      else {
        draft_board$prospect[length(unavailable)+1] = make_selection(i, unavailable, prop_board)
      }
      
      # Adjust output tables
      
      selected_picks = draft_board %>% rename(Pick = order, Team = team, Prospect = prospect)
      player_board <-
        get_available(
          draft_rankings, used_sources, draft_board$prospect
        ) %>% 
        select(Player, med_rank)
      
    }
  })
  
  output$board_left <- renderDT({
      datatable(
        player_board(), 
        # get_available(draft_rankings, input$used_sources) %>% 
        #   select(Player, med_rank), 
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