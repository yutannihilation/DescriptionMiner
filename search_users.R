library(tidyverse)
library(gh)

USERS_DIR <- "users"

# Get Users ---------------------------------------------------------------

estimate_pages <- function(threshold = 100L) {
  res <- gh("/search/users",
            q = glue::glue("repos:>{threshold} language:R -user:cran"),
            sort = "repositories",
            page = 1L,
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


# Get repos ---------------------------------------------------------------

users_file <- file.path(USERS_DIR, "users_repos100_with_counts.csv")
if (!file.exists(users_file)) {
  users_file <- file.path(USERS_DIR, "users_repos100.csv")
}
users <- readr::read_csv(users_file)

users_login_names <- if ("repo_counts" %in% names(users)) {
   users %>%
    filter(is.na(repo_counts)) %>%
    pull(login_names)
} else {
  users$login_names
}

if (length(users_login_names) == 0) stop("Already got repo counts for all users.")

get_repo_count <- function(user) {
  res <- gh::gh("/search/code",
                q = glue::glue("filename:NAMESPACE fork:false export user:{user}"),
                sort = "indexed",
                page = 1,
                per_page = 1)
  Sys.sleep(20)
  res$total_count
}

user_repo_counts <- map(set_names(users_login_names),
                        safely(get_repo_count, otherwise = NA_integer_))

counts <- map_int(user_repo_counts, "result")

users %>%
  mutate(repo_counts = coalesce(repo_counts, counts[login_names])) %>%
  readr::write_csv("users/users_repos100_with_counts.csv")
