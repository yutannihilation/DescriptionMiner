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

So, we can find R package repos by searching `filename:DESCRIPTION` or `filename:NAMESPACE`. After some attempts, I feel `filename:NAMESPACE` is rather easier.


Details
-------

I use [GitHub Code Search API](https://developer.github.com/v3/search/#search-code) via [gh](https://cran.r-project.org/package=gh) package. A simplified version of the code would be like this:

```r
res <- gh::gh("/search/code", q = "filename:NAMESPACE -org:cran fork:false")

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

### Search by filename

The basic search query should be this one:

```
filename:NAMESPACE
```

But, this will results a lot of noices. There are so so many namespace files that are not what we want. 

Let's add one keyword. An `NAMESPACE` file in an R package has `export` at least. (I'm not fully confident with this assumption, though...)

```
filename:NAMESPACE export
```

### Exclude other languages by file extension

Yet, there are many other namespaces like `namespace.c` and `namespace.html`. These should be also excluded.

```r
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
  # For DESCRIPTION
  "rst",            # reStructuredText
  "props",          # Weka?
  "plist",          # ?
  "scala",          # Scala
  "cmake",          # CMake
  "m"               # Objective-C
)
```

The constructed query piece will be like this:

```r
extensions_query <- sprintf("-extension:%s", extensions) %>%
   paste(collapse = " ")
extensions_query
#> [1] "-extension:c -extension:h -extension:pl -extension:pm -extension:html -extension:htm ..."
```

### Exclude users that have many repos

First, we have to exclude these known mirrors:

* cran (CRAN mirror)
* Bioconductor-mirror (Bioconductor mirror)
* rforge (RForge mirror)

Besides, the users that have many repos can be excluded once, as later we can query for the user:

```
filename:NAMESPACE export user:user1 -extension:...
```

So now the query should look like:

```
filename:NAMESPACE export -org:cran -user:rforge ... -extension:...
```

### Exclude some keywords

`D1tr` seems from [ESS](https://github.com/emacs-ess/ESS-mirror/blob/trunk/etc/pkg1/NAMESPACE). Exclude it.

```
filename:NAMESPACE export NOT D1tr -org:cran -user:rforge ... -extension:...
```

### Split Requests

OK, let's try the constructed query.

```r
NAMESPACE_QUERY <- glue::glue("filename:NAMESPACE fork:false export {extensions_query} -user:rforge {users_query}")
res <- gh::gh("/search/code",
              q = NAMESPACE_QUERY,
              page = 1,
              per_page = 1)

res$total_count
#> [1] 14913
```

Alas, `total_count` is far more than the limit of GitHub search API, 1000!

We can access to the 1000 results from the head and the bottom by sorting `indexed` and `indexed-asc`.
This means, if the number of results is within 2000, we can access to the whole `NAMESPACE`s.

So, let's split the request into narrowed ones.

### `path:/` or `-path:/`

`NAMESPACE` file is often located at the top of repo. `path:/` will filter this.

In other cases, `NAMESPACE` file may be a one included in vendered package by packrat. So it'd be better to exclude `packrat` directory as well by `-path:packrat`.

```
filename:NAMESPACE export NOT D1tr path:/ -org:cran -user:rforge ... -extension:...
filename:NAMESPACE export NOT D1tr -path:/ -path:packrat -org:cran -user:rforge ... -extension:...
```

### Other keywords

`NAMESPACE` file may contain some keywords like:

* `exportPattern`
* `S3method`
* `import`

So split further by adding `NOT` to the keyword like:

```
filename:NAMESPACE export NOT D1tr exportPattern path:/ -org:cran -user:rforge ... -extension:...
filename:NAMESPACE export NOT D1tr NOT exportPattern path:/ -org:cran -user:rforge ... -extension:...
...
```
