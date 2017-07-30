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
  keep(~ .$name != "DESCRIPTION") %>%
  map_df(~ list(repo = .[[c("repository", "full_name")]], path = .[["path"]])) %>%
  knitr::kable()
```

|repo                                 |path                                                                                                                |
|:------------------------------------|:-------------------------------------------------------------------------------------------------------------------|
|qball/Lexington                      |description                                                                                                         |
|kevbrn/first_app                     |OLDgit/description                                                                                                  |
|niroj/iStockPainting                 |description                                                                                                         |
|rpombo/railsinstaller_demo           |Git/share/git-core/templates/description                                                                            |
|cjohansen/libdolt                    |test/fixtures/dolt-test-repo.git/description                                                                        |
|larrykvit/quadcopter_flight_software |oldgit/description                                                                                                  |
|suspendmode/glenmore-mvcs            |glenmore-mvcs/description                                                                                           |
|rubyunworks/autoload                 |var/description                                                                                                     |
|raphaelgmelo/remotecontrol           |remotecontrol.git/description                                                                                       |
|HaveF/dev-cookbook                   |.description                                                                                                        |
|imazen/repositext                    |spec/git_test/repo_images/rt-english/dot_git/description                                                            |
|imazen/repositext                    |spec/git_test/repo_images/rt-spanish/dot_git/description                                                            |
|imazen/repositext                    |spec/git_test/repo_images/static/dot_git/description                                                                |
|imazen/repositext                    |spec/git_test/repo_images/static_remote/dot_git/description                                                         |
|project-draco-hr/consulo             |platform_lang-impl_src_com_intellij_patterns_compiler_PatternClassBean.java/[CN]/PatternClassBean/[FE]/description  |
|project-draco-hr/consulo             |platform_lang-api_src_com_intellij_psi_PsiReferenceProviderBean.java/[CN]/PsiReferenceProviderBean/[FE]/description |
```