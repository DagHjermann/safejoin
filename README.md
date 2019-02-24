
<!-- README.md is generated from README.Rmd. Please edit that file -->
safejoin
--------

The package *safejoin* features wrappers around *dplyr*'s functions to join safely using various checks

Install *safejoin* with:

``` r
# install.packages(devtools)
devtools::install_github("moodymudskipper/safejoin")
```

Joining operations often come with tests, one might want to check that:

1.  No columns are repeated in both data.frames apart from `by` columns
2.  `by` columns are given explicitly
3.  Join columns form a unique key on both or either tables
4.  All rows of both or either tables will be matched
5.  All combinations of values of join columns are present on both or either sides
6.  Factor columns used for the join have the same levels

Here is what *dplyr* does in these cases:

1.  Suffix silently the columns and keep both
2.  Display a message
3.  Nothing
4.  Nothing
5.  Nothing
6.  Display a warning

This package provides the possibility for any of these cases to ignore, inform, warn or abort.

These checks are handled by a single string parameter, i.e. a sequence of characters where uppercase letters trigger failures, lower case letters trigger warnings, and letters prefixed with `~` trigger messages, the codes are as follow:

-   `"c"` to check *c*onflicts of *c*olumns
-   `"b"` like *"by"* checks if `by` parameter was given explicitly
-   `"u"` like *unique* to check that the join colums from an unique key on `x`
-   `"v"` to check that the join colums from an unique key on `y`
-   `"m"` like *match* to check that all rows of `x` have a *match*
-   `"n"` to check that all rows of `y` have a *match*
-   `"e"` like *expand* to check that all combinations of joining columns are present in `x`
-   `"f"` to check that all combinations of joining columns are present in `y`
-   `"l"` like *levels* to check that matching is consistent with levels of factor columns

For example, `check = "MN"` will ensure that all rows of both tables are matched.

The package features functions `safe_left_join`, `safe_right_join`, `safe_inner_join`, `safe_full_join`, `safe_nest_join`, `safe_semi_join`, `safe_anti_join`, and `eat`.

The additional function, `eat` is designed to be an improved left join in the cases where one is growing a data frame. In addition to the features above :

-   It leverages the select helpers from *dplyr* to select columns from `y`
-   It features a sophisticated system to deal with column conflicts
-   It can prefix new columns or rename them in a flexible way
-   It can summarize `y` on the fly along joining columns for more concise and readable code

safe\_left\_join
----------------

*safejoin* offers the same features for all `safe_*_join` functions so we'll only review `safe_left_join` here, we also limit ourselves to checks of the form `~*`

We'll use *dplyr*'s data sets `band_members` and `band_instruments` along with extended versions.

``` r
library(safejoin)
library(dplyr,quietly = TRUE,warn.conflicts = FALSE)
#> Warning: package 'dplyr' was built under R version 3.5.2
band_members_extended <- band_members %>%
  mutate(cooks = factor(c("pasta","pizza","spaghetti"),
                        levels = c("pasta","pizza","spaghetti"))) %>%
  add_row(name = "John",band = "The Who", cooks = "pizza")

band_instruments_extended <- band_instruments %>%
  mutate(cooks = factor(c("pizza","pasta","pizza")))

band_members
#> # A tibble: 3 x 2
#>   name  band   
#>   <chr> <chr>  
#> 1 Mick  Stones 
#> 2 John  Beatles
#> 3 Paul  Beatles
band_instruments
#> # A tibble: 3 x 2
#>   name  plays 
#>   <chr> <chr> 
#> 1 John  guitar
#> 2 Paul  bass  
#> 3 Keith guitar
band_members_extended
#> # A tibble: 4 x 3
#>   name  band    cooks    
#>   <chr> <chr>   <fct>    
#> 1 Mick  Stones  pasta    
#> 2 John  Beatles pizza    
#> 3 Paul  Beatles spaghetti
#> 4 John  The Who pizza
band_instruments_extended
#> # A tibble: 3 x 3
#>   name  plays  cooks
#>   <chr> <chr>  <fct>
#> 1 John  guitar pizza
#> 2 Paul  bass   pasta
#> 3 Keith guitar pizza
```

Not applying any check :

``` r
safe_left_join(band_members,
               band_instruments,
               check ="")
#> # A tibble: 3 x 3
#>   name  band    plays 
#>   <chr> <chr>   <chr> 
#> 1 Mick  Stones  <NA>  
#> 2 John  Beatles guitar
#> 3 Paul  Beatles bass
```

Displaying "Joining, by..." like in default *dplyr* behavior:

``` r
safe_left_join(band_members,
               band_instruments,
               check ="~b")
#> Joining, by = "name"
#> # A tibble: 3 x 3
#>   name  band    plays 
#>   <chr> <chr>   <chr> 
#> 1 Mick  Stones  <NA>  
#> 2 John  Beatles guitar
#> 3 Paul  Beatles bass
```

Check column conflict when joining extended datasets by name:

``` r
try(safe_left_join(band_members_extended,
                   band_instruments_extended,
                   by = "name",
                   check = "~c"))
#> Conflict of auxiliary columns: cooks
#> # A tibble: 4 x 5
#>   name  band    cooks.x   plays  cooks.y
#>   <chr> <chr>   <fct>     <chr>  <fct>  
#> 1 Mick  Stones  pasta     <NA>   <NA>   
#> 2 John  Beatles pizza     guitar pizza  
#> 3 Paul  Beatles spaghetti bass   pasta  
#> 4 John  The Who pizza     guitar pizza
```

Check if `x` has unmatched combinations:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by = c("name","cooks"),
               check = "~m")
#> x has unmatched sets of joining values: 
#> %s # A tibble: 2 x 2
#>   name  cooks    
#>   <chr> <chr>    
#> 1 Mick  pasta    
#> 2 Paul  spaghetti
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if `y` has unmatched combinations:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by = c("name","cooks"),
               check = "~n")
#> y has unmatched sets of joining values: 
#> %s # A tibble: 2 x 2
#>   name  cooks
#>   <chr> <chr>
#> 1 Paul  pasta
#> 2 Keith pizza
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if `x` has absent combinations:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by=c("name","cooks"),
               check ="~e")
#> Some combinations of joining values are absent from x: 
#> %s # A tibble: 6 x 2
#>   name  cooks    
#>   <chr> <chr>    
#> 1 John  pasta    
#> 2 Paul  pasta    
#> 3 Mick  pizza    
#> 4 Paul  pizza    
#> 5 Mick  spaghetti
#> 6 John  spaghetti
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if `y` has absent combinations:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by=c("name","cooks"),
               check ="~f")
#> Some combinations of joining values are absent from y: 
#> %s # A tibble: 3 x 2
#>   name  cooks
#>   <chr> <chr>
#> 1 Paul  pizza
#> 2 John  pasta
#> 3 Keith pasta
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if `x` is unique on joining columns:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by=c("name","cooks"),
               check ="~u")
#> x is not unique on name and cooks
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if `y` is unique on joining columns (it is):

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by=c("name","cooks"),
               check ="~v")
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

Check if levels are compatible betweeb joining columns:

``` r
safe_left_join(band_members_extended,
               band_instruments_extended,
               by=c("name","cooks"),
               check ="~l")
#> The pair cooks/cooks don't have the same levels:
#> not in x: 
#> not in y: spaghetti
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

eat
---

All the checks above are still relevant for `eat`. Let's go through the additional features.

Same as `safe_left_join` :

``` r
band_members_extended %>% eat(band_instruments_extended)
#> Joining, by = c("name", "cooks")
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
band_members_extended %>% eat(band_instruments_extended, by="name", check ="")
#> # A tibble: 4 x 5
#>   name  band    cooks.x   plays  cooks.y
#>   <chr> <chr>   <fct>     <chr>  <fct>  
#> 1 Mick  Stones  pasta     <NA>   <NA>   
#> 2 John  Beatles pizza     guitar pizza  
#> 3 Paul  Beatles spaghetti bass   pasta  
#> 4 John  The Who pizza     guitar pizza
```

Rename eaten columns :

``` r
band_members_extended %>% eat(band_instruments_extended, prefix = "NEW")
#> Joining, by = c("name", "cooks")
#> # A tibble: 4 x 4
#>   name  band    cooks     NEW_plays
#>   <chr> <chr>   <chr>     <chr>    
#> 1 Mick  Stones  pasta     <NA>     
#> 2 John  Beatles pizza     guitar   
#> 3 Paul  Beatles spaghetti <NA>     
#> 4 John  The Who pizza     guitar
```

Eat `plays` column only:

``` r
band_members_extended %>% eat(band_instruments_extended, plays, by="name")
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <fct>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti bass  
#> 4 John  The Who pizza     guitar
band_members_extended %>% eat(band_instruments_extended, starts_with("p"), by="name")
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <fct>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti bass  
#> 4 John  The Who pizza     guitar
```

Here we used the `...` argument, `eat` can check if the dot argument was used by using the character `"d"` in the check string:

``` r
band_members_extended %>% eat(band_instruments_extended, check ="~d")
#> Column names not provided, all columns from y will be eaten :
#> plays
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <chr>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti <NA>  
#> 4 John  The Who pizza     guitar
```

In case of confict choose either the column from `x` or from `y`:

``` r
band_members_extended %>% eat(band_instruments_extended, by="name", conflict = ~.x)
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <fct>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti bass  
#> 4 John  The Who pizza     guitar
band_members_extended %>% eat(band_instruments_extended, by="name", conflict = ~.y)
#> # A tibble: 4 x 4
#>   name  band    cooks plays 
#>   <chr> <chr>   <fct> <chr> 
#> 1 Mick  Stones  <NA>  <NA>  
#> 2 John  Beatles pizza guitar
#> 3 Paul  Beatles pasta bass  
#> 4 John  The Who pizza guitar
```

Our apply any transformation :

``` r
band_members_extended %>% eat(band_instruments_extended, by ="name", conflict = coalesce)
#> # A tibble: 4 x 4
#>   name  band    cooks     plays 
#>   <chr> <chr>   <fct>     <chr> 
#> 1 Mick  Stones  pasta     <NA>  
#> 2 John  Beatles pizza     guitar
#> 3 Paul  Beatles spaghetti bass  
#> 4 John  The Who pizza     guitar
band_members_extended %>% eat(band_instruments_extended, by ="name", conflict = ~coalesce(.y,.x))
#> # A tibble: 4 x 4
#>   name  band    cooks plays 
#>   <chr> <chr>   <fct> <chr> 
#> 1 Mick  Stones  pasta <NA>  
#> 2 John  Beatles pizza guitar
#> 3 Paul  Beatles pasta bass  
#> 4 John  The Who pizza guitar
band_members_extended %>% eat(band_instruments_extended, by ="name", conflict = paste)
#> # A tibble: 4 x 4
#>   name  band    cooks           plays 
#>   <chr> <chr>   <chr>           <chr> 
#> 1 Mick  Stones  pasta NA        <NA>  
#> 2 John  Beatles pizza pizza     guitar
#> 3 Paul  Beatles spaghetti pasta bass  
#> 4 John  The Who pizza pizza     guitar
```

Some common use cases for numerics would be `` confict = `+` ``, `confict = pmin`, , `confict = pmax`, `confict = ~(.x+.y)/2`.

In cases of matching to many (i.e. the join columns don't form a unique key for `y`), we can use the parameter `fun` to aggregate them on the fly:

``` r
band_instruments_extended %>% eat(band_members_extended)
#> Joining, by = c("name", "cooks")
#> # A tibble: 4 x 4
#>   name  plays  cooks band   
#>   <chr> <chr>  <chr> <chr>  
#> 1 John  guitar pizza Beatles
#> 2 John  guitar pizza The Who
#> 3 Paul  bass   pasta <NA>   
#> 4 Keith guitar pizza <NA>
band_instruments_extended %>% eat(band_members_extended, fun = ~paste(.,collapse="/"))
#> Joining, by = c("name", "cooks")
#> # A tibble: 3 x 4
#>   name  plays  cooks band           
#>   <chr> <chr>  <chr> <chr>          
#> 1 John  guitar pizza Beatles/The Who
#> 2 Paul  bass   pasta <NA>           
#> 3 Keith guitar pizza <NA>
```

Finally, `conflict = "patch"` is a special value where matches found in `y` overwrite the values in `x`, and other values are kept. It's different from `conflict = ~coalesce(.y,.x)` because some values in `x` might be overwritten by `NA`.

``` r
band_members_extended %>% eat(band_instruments_extended, by="name", conflict = "patch")
#> # A tibble: 4 x 4
#>   name  band    cooks plays 
#>   <chr> <chr>   <fct> <chr> 
#> 1 Mick  Stones  pasta <NA>  
#> 2 John  Beatles pizza guitar
#> 3 Paul  Beatles pasta bass  
#> 4 John  The Who pizza guitar
```