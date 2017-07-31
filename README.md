DescriptionMiner
================

Introduction
------------
Today, there are mountains of packages on GitHub and we naturally want the comprehensive list of these packages. [Gepuro Task Views](http://rpkg.gepuro.net/) is famous for this purpose. This repo is yet another attempt to achieve it.


Basic Idea
----------

An R package has, at least:

1. `DESCRIPTION` file
2. `NAMESPACE` file

So, we can find R package repos by searching `filename:DESCRIPTION` and `filename:NAMESPACE`, and calculating the intersection of the result. (Note that, unfortunately, GitHub Search is case-insensitive, so we have to exclude `description` and `namespace` from the result by ourselves)


Details
-------

### Search

I use [GitHub Code Search API](https://developer.github.com/v3/search/#search-code) via [gh](https://cran.r-project.org/package=gh) package. A simplified version of the code would be like this:

```r
res <- gh::gh("/search/code", q = "filename:DESCRIPTION -org:cran fork:false")

names(res)
#> [1] "total_count"        "incomplete_results" "items"

res$total_count
#> [1] 2208017

res$incomplete_results
#> [1] TRUE

library(purrr)
res$items %>%
  keep(~ .$name == "DESCRIPTION") %>%
  map_df(~ list(repo = .[[c("repository", "full_name")]], path = .[["path"]]))
```

Notable points are:

* Exclude [cran](https://github.com/cran/), a CRAN mirror.
* Exclude forked repository.
* Do not use `language`. The languages detected by GitHub are not always correct since R packages may contain many files other than R.

The results are saved to `results/DESCRIPTION` and `results/NAMESPACE` separately.


### Split Search Query

The hardest part is to overcome this error by narrowing the search result:

```r
#>  Error in gh::gh("/search/code", q = query, page = page) : 
#>   GitHub API error (422): 422 Unprocessable Entity
#>   Only the first 1000 search results are available
```

* 