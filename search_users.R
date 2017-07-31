library(purrr)
library(gh)

USERS_DIR <- "users"

estimate_pages <- function(threshold = 100L) {
  res <- gh("/search/users",
            q = glue::glue("repos:>{threshold} language:R"),
            sort = "repositories",
            page = page,
            per_page = 1L)
  message("total_count: ", res$total_count)
  ceiling(res$total_count / 100L)
}

do_search_user <- function(page, threshold = 100L) {
  res <- gh("/search/users",
            q = glue::glue("repos:>{threshold} language:R"),
            sort = "repositories",
            page = page,
            per_page = 100L)
  
  login_names <- map_chr(res$items, "login")
  types <- map_chr(res$items, "type")
  
  Sys.sleep(20)
  
  tibble::tibble(
    login_names,
    types
  )
}

pages <- estimate_pages()
users <- map_df(seq_len(pages), do_search_user)

dir.create(USERS_DIR, showWarnings = FALSE)
readr::write_csv(users, file.path(USERS_DIR, "users_repos100.csv"))
