library(purrr)

RESULT_DIR <- "results"
RESULT_DESCRIPTION_DIR <- file.path(RESULT_DIR, "DESCRIPTION")
RESULT_NAMESPACE_DIR <- file.path(RESULT_DIR, "NAMESPACE")

users <- read_csv("users/users_repos100.csv")
NAMESPACE_QUERY <- glue::glue("filename:NAMESPACE fork:false export -user:rforge {users_query}")
DESCRIPTION_QUERY <- glue::glue("filename:DESCRIPTION fork:false Package Version -user:rforge {users_query}")
# Functions ----------------------------------------------------------------------------

do_search <- function(page, query, csv_dir) {
  message("requesting page ", page, " ...")
  
  res <- gh::gh("/search/code",
                q = query,
                sort = "indexed",
                page = page,
                per_page = 100)
  
  repo     <- purrr::map_chr(res$items, c("repository", "name"))
  owner    <- purrr::map_chr(res$items, c("repository", "owner", "login"))
  filename <- purrr::map_chr(res$items, "name")
  path     <- purrr::map_chr(res$items, "path")

  result <- tibble::tibble(owner, repo, filename, path)
  
  readr::write_csv(result,
                   path = file.path(csv_dir, sprintf("page%d.csv", page)))
}

do_search_description <- function(page) {
  do_search(page,
            query = DESCRIPTION_QUERY,
            csv_dir = RESULT_DESCRIPTION_DIR)
}

do_search_namespace <- function(page) {
  do_search(page,
            query = NAMESPACE_QUERY,
            csv_dir = RESULT_NAMESPACE_DIR)
}


get_next_page <- function(dir = c(RESULT_DESCRIPTION_DIR, RESULT_NAMESPACE_DIR)) {
  dir <- match.arg(dir)
  csvs <- list.files(path = dir, pattern = "page[0-9]+\\.csv")
  cur_page <- length(csvs)
  
  # confirm the numbers of CSVs are sequential
  if (!setequal(csvs, sprintf("page%d.csv", seq_len(cur_page)))) {
    stop("CSVs are not sequential; something is wrong!")
  }
  
  cur_page + 1L
}

get_rate_limit_for_search <- function() {
  res <- gh::gh("/rate_limit")
  res$resources$search
}

# Create directories ------------------------------------------------------------------

dir.create(RESULT_DESCRIPTION_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(RESULT_NAMESPACE_DIR, showWarnings = FALSE, recursive = TRUE)

rate_limit <- get_rate_limit_for_search()
max_count <- rate_limit$limit %/% 2

page_description <- get_next_page(RESULT_DESCRIPTION_DIR)
for (page in seq(page_description, page_description + max_count)) {
  do_search_description(page)
  Sys.sleep(60)
}

page_namespace <- get_next_page(RESULT_NAMESPACE_DIR)
for (page in seq(page_namespace, page_namespace + max_count)) {
  do_search_namespace(page)
  Sys.sleep(60)
}
