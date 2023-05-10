library('shiny')
library('tidyverse')
library('rvest')
library('stringr')
library('DT')
library('shinyalert')
library('glue')
library('gotop')

###
# Clean up names
###

clean_teams <- function(team, type) {
  len = str_length(team)
  trailing = str_sub(team, len-2, len)
  
  if(str_detect(str_sub(trailing, 2), "GS")) {
    trailing = str_sub(glue("{trailing}W"), 2)
  } 
  else if(str_detect(str_sub(trailing, 2), "SA")) {
    trailing = str_sub(glue("{trailing}S"), 2)
  }
  else if(str_detect(str_sub(trailing, 2), "NO")) {
    trailing = str_sub(glue("{trailing}P"), 2)
  }
  else if(str_detect(str_sub(trailing, 2), "NY")) {
    trailing = str_sub(glue("{trailing}K"), 2)
  }
  
  return(trailing)
}

###
# Get Order
###

get_order <- function() {
  
  # Scraping the order from Tankathon
  
  url = 'https://www.tankathon.com/'
  
  page_tabl <-
    read_html(url) %>%
    html_element('.draft-board-table-container table') %>%
    html_table()
  
  # Cleaning output
  
  colnames(page_tabl) <- page_tabl[1,]
  
  cleaned_order <-
    page_tabl[2:nrow(page_tabl),] %>%
    janitor::clean_names() %>%
    filter(pick != "" & pick != "END OF LOTTERY") %>%
    mutate(
      abb = purrr::map_chr(team, clean_teams, type = 'abb'), 
      order = pick
    ) %>%
    select(order, abb)
}


###
# Generate Sources
###

get_sources <- function(my_data) {
  my_data %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    ) %>%
    select(Source) %>%
    distinct() %>%
    unlist(use.names = FALSE)
}


###
# Generate Available, Sorted Picks
###

get_available <- function(rankings, sources, unavailable = NULL) {
  
  max_rank <- 
    rankings %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    ) %>% 
    filter(Source %in% sources) %>% 
    # filter(
    #   if(!is.null(unavailable)) {
    #     !(Player %in% unavailable)
    #   }
    # ) %>%
    group_by(Player) %>%
    summarise(
      n_rank = n(), 
      rows = nrow(rankings), 
      maxx = max(Rank), 
      med_rank = median(Rank)
    ) %>% 
    ungroup() %>%
    rowwise() %>%
    mutate(
      m_pick = case_when(
        n_rank < 2 ~ rows, 
        TRUE ~ min(c(maxx, rows))
      )
    ) %>%
    arrange(med_rank)
  
  return(max_rank)
  
}


###
# Generate Draft Board
###

get_prob_board <- function(rankings, sources) {
  
  real_rank <-
    rankings %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    ) %>% 
    filter(Source %in% sources) %>%
    group_by(Rank, Player) %>%
    summarise(Freq = n()) %>%
    ungroup() %>%
    filter(!is.na(Player))
  
  full_rank <-
    real_rank %>%
    group_by(Player) %>%
    reframe(
      Rank = seq(min(Rank), max(Rank)), 
      Default = 0.5
    ) %>%
    arrange(Rank) %>%
    select(Rank, Player, Default)
  
  
  prob_board <- 
    left_join(
      full_rank, 
      real_rank,
      by = c("Rank", "Player")
    ) %>%
    mutate(
      F_Freq = coalesce(Default, 0) + coalesce(Freq, 0)
    ) %>%
    group_by(Rank) %>%
    mutate(
      R_Freq = F_Freq / sum(F_Freq)
    ) %>%
    group_by(Rank) %>%
    summarise(
      prospects = list(Player), 
      probabilities = list(R_Freq), 
      min_rank = list(min(Rank))
    ) %>%
    ungroup()
  
  return(prob_board)
  
}


###
# Get Max Rank
###

get_max_rank <- function(rankings) {
  rankings %>%
    pivot_longer(
      cols = -Rank, 
      names_to = "Source", 
      values_to = "Player"
    ) %>%
    mutate(
      Update = str_sub(Source, str_locate(Source, "\\|")[,1] + 2, str_length(Source)), 
      Source = str_sub(Source, 1, str_locate(Source, "\\|")[,1] - 2)
    ) %>% 
    group_by(Player) %>%
    summarise(
      n_rank = n(), 
      rows = nrow(rankings), 
      maxx = max(Rank)
    ) %>% 
    ungroup() %>%
    rowwise() %>%
    mutate(
      m_pick = case_when(
        n_rank < 2 ~ rows, 
        TRUE ~ min(c(maxx, rows))
      )
    ) %>%
    arrange(m_pick)
}


###
# Make Selection
###

make_selection <- function(pick, unavailable, prob_board) {
  # Get available prospects & probs for pick
  to_remove = match(unavailable, prob_board$prospects[pick][[1]])
  to_remove = to_remove[!is.na(to_remove)]
  if(length(to_remove) == 0) {
    to_remove = c()
  }
  
  extra_prob = sum(prob_board$probabilities[pick][[1]][to_remove])
  if(length(to_remove) != 0) {
    prosps = prob_board$prospects[pick][[1]][-to_remove]
    probs = prob_board$probabilities[pick][[1]][-to_remove]
  } 
  else {
    prosps = prob_board$prospects[pick][[1]]
    probs = prob_board$probabilities[pick][[1]]
  }
  
  if(length(prosps) != 0) {
    probs = probs + (extra_prob / length(probs))
    
    # Make the selection
    selection = sample(prosps, 1, prob = probs)
    
    return(selection)
  }
  else {
    return("EMPTY")
  }
}


#############################
# Data Prep
#############################

lottery_order <- get_order() %>% mutate(prospect = as.character(NA))

draft_rankings <- read_csv(
    url('https://raw.githubusercontent.com/adambushman/basketball-data/master/draft/2023_Industry_Boards.csv')
  )

max_rankings <- get_max_rank(draft_rankings)

selected_picks <-
  data.frame(matrix(nrow = 0, ncol = 3)) %>%
  rename(Pick = X1, Team = X2, Prospect = X3)

sources <- get_sources(draft_rankings)