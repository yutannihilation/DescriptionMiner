library(tidyverse)

RESULT_DIR <- "results"
RESULT_DESCRIPTION_DIR <- file.path(RESULT_DIR, "DESCRIPTION")

# Query Construction -------------------------------------------------------------

# extension

extensions <- c(
  "c", "h",         # C
  "pl", "pm",       # Perl
  "html", "htm",   # HTML
  "cpp", "hpp",     # C++
  "java",           # Java
  "js",             # JavaScript
  "3", "n",         # Roff
  "ts",             # TypeScript
  "xml",            # XML
  "diff", "patch",  # Diff
  "cmd",            # Batchfile
  "rb",             # Ruby
  "php",            # PHP
  "cs",             # C#
  "txt",            # Text
  "json",           # JSON
  "e",              # Efieel
  "dart",           # Dart
  "dot",            # Graphviz
  "ll",             # LLVM
  "lisp",           # Lisp
  "py",             # Python
  "test",           # TCL
  "svn-base",       # SVN
  "rst",            # reStructuredText
  "props",          # Weka?
  "plist",          # ?
  "scala",          # Scala
  "cmake",          # CMake
  "m",              # Objective-C
  "md"              # Markdown
)

extensions_query <- sprintf("-extension:%s", extensions) %>%
  paste(collapse = " ")

users_many_repo <- read_csv("users/users_repos100_with_counts.csv") %>%
  filter(repo_counts > 30) %>%
  arrange(desc(repo_counts)) %>%
  pull(login_names)

users_other <- c(
  "proper337",
  "SvenDowideit",
  "narjisse-tabout",
  "ttrodrig",
  "geaviation",
  "ProQuestionAsker",
  "Saadman",
  "Przemol",
  "natelistrom",
  "mkgiitr",
  "alexey-lysiuk",
  "RahmanTeam",
  "iNZightVIT",
  "piscean388",
  "lawrenceouyang",
  "OatMS",
  "keboola",
  "jmswenson",
  "a-pika",
  "ohmiya",
  "Bakary-baktech",
  "xialu4820723",
  "avnichab",
  "trendct",
  "PeterUlz",
  "mdo98",
  "nojvek",
  "KuiMing",
  "uncsurveysCF",
  "bioexcel",
  "RSGInc",
  "Bertrand0001",
  "noplisu",
  "wangyuexiang",
  "Qbicz",
  "R-Miner",
  "nafiux",
  "josemrc",
  "BackupTheBerlios",
  "slipher1",
  "noahhl",
  "wrbrooks",
  "rmorantte",
  "alexanderm10"
)

users_exclude <- c(
  "cran",                # CRAN mirror
  "Bioconductor-mirror", # Bioconductor mirror
  "rforge"               # RForge mirror
)

users_query <- c(users_many_repo, users_other, users_exclude) %>%
  unique %>%
  sprintf("-user:%s", .) %>%
  paste(collapse = " ")

DESCRIPTION_QUERY_TMPL <- glue::glue("filename:DESCRIPTION fork:false Package Version %s {extensions_query} {users_query}")
query_patterns <- c(
  "path:/ exportPattern import",
  "path:/ exportPattern NOT import",
  "path:/ NOT exportPattern S3method",
  "path:/ NOT exportPattern NOT S3method import",
  "path:/ NOT exportPattern NOT S3method NOT import",
  "-path:/ -path:packrat exportPattern import",
  "-path:/ -path:packrat exportPattern NOT import",
  "-path:/ -path:packrat NOT exportPattern S3method",
  "-path:/ -path:packrat NOT exportPattern NOT S3method import",
  "-path:/ -path:packrat NOT exportPattern NOT S3method NOT import"
)

DESCRIPTION_QUERY_TMPL <- glue::glue("filename:DESCRIPTION fork:false Package Version %s {extensions_query} -user:rforge {users_query}")

# Functions ----------------------------------------------------------------------------

do_search <- function(page, query, sort = "indexed") {
  message("requesting page ", page, " ...")
  
  res <- gh::gh("/search/code",
                q = query,
                sort = sort,
                page = page,
                per_page = 100)
  
  repo     <- purrr::map_chr(res$items, c("repository", "name"))
  owner    <- purrr::map_chr(res$items, c("repository", "owner", "login"))
  filename <- purrr::map_chr(res$items, "name")
  path     <- purrr::map_chr(res$items, "path")
  
  tibble::tibble(owner, repo, filename, path)
}


get_next_page <- function(dir) {
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

dir.create(RESULT_NAMESPACE_DIR, showWarnings = FALSE, recursive = TRUE)

rate_limit <- get_rate_limit_for_search()
max_count <- rate_limit$limit


csv_dir <- file.path(RESULT_NAMESPACE_DIR, sprintf("query%d", 1))
dir.create(csv_dir, showWarnings = FALSE)
page_namespace <- get_next_page(csv_dir)
for (page in seq(page_namespace, page_namespace + max_count - 1)) {
  result <- do_search(page,
                      query = sprintf(NAMESPACE_QUERY_TMPL, query_patterns[1]))
  
  write_csv(result,
            path = file.path(csv_dir, sprintf("page%d.csv", page)))
  Sys.sleep(60)
}
