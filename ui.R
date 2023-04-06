ui <- fluidPage(
  titlePanel("Let's Draft | NBA"),
  sidebarLayout(
    "Test",
    sidebarPanel(
             selectInput(
               "selection_teams", 
               "Choose team's you want to represent in the draft", 
               choices = sort(lottery_order$abb),
               multiple = TRUE
             )
             
    )
  )
)