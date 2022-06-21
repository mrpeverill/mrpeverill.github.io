---
layout: post
title: "Splitting a Sample by Two Balancing Factors"
author: "Matthew Peverill"
date: "2022-06-21"
output:
  md_document:
    variant: gfm
    preserve_yaml: true
knit: (function(inputFile, encoding) {
    rmarkdown::render(inputFile,
                      encoding = encoding,
                      output_file = file.path(paste0(
                                                  "~/Dropbox/mrpeverill-website/_posts/",
                                                  Sys.Date(),
                                                  '-',
                                                  substr(basename(inputFile), 1, nchar(basename(inputFile)) - 4),
                                                  '.md'
                                                  )
                                              )
                      )
    })
---

This is an example of splitting a sample in two preserving the balance
of two related factors (in my case, site and binned income) in R using
the ‘caret’ package.

``` r
library(sn)
library(tidyverse); library(ggthemes); theme_set(theme_tufte())
library(caret)
library(pander)
```

``` r
set.seed(3453)
#rsn samples from a skewed normal distribution
site1<-data.frame(i=rsn(2000,alpha=-3))
site2<-data.frame(i=rsn(4000,alpha=0))
site3<-data.frame(i=rsn(1000,alpha=3))
sitedesc<-factor(c(rep("one",2000),
                   rep("two",4000),
                   rep("three",1000)))
df<-rbind(site1,site2,site3)
df$site<-sitedesc


numbers_of_bins = 10
df <- df %>%
    mutate(
        # bin i:
        i.bin = cut(i,
                    breaks = unique(quantile(
                        i,
                        probs = seq.int(0, 1, by = 1 / numbers_of_bins)
                    )),
                    include.lowest = TRUE),
        # interact the factors to make a unique level for each combination.
        interaction = interaction(i.bin, site) 
    )
pander(head(df))
```

|    i    | site |      i.bin       |     interaction      |
|:-------:|:----:|:----------------:|:--------------------:|
| -1.504  | one  |  \[-3.9,-1.39\]  |  \[-3.9,-1.39\].one  |
| -1.031  | one  | (-1.39,-0.952\]  | (-1.39,-0.952\].one  |
| -0.8683 | one  | (-0.952,-0.636\] | (-0.952,-0.636\].one |
| -1.119  | one  | (-1.39,-0.952\]  | (-1.39,-0.952\].one  |
| -0.4916 | one  | (-0.636,-0.384\] | (-0.636,-0.384\].one |
| -0.4953 | one  | (-0.636,-0.384\] | (-0.636,-0.384\].one |

Now that the factors are combined, we can sample evenly from them using
caret

``` r
trainIndex<-createDataPartition(df$interaction,p=.5,times=1,list=FALSE)
```

    ## Warning in createDataPartition(df$interaction, p = 0.5, times = 1, list =
    ## FALSE): Some classes have no records ( (0.72,1.17].one, (1.17,3.84].one,
    ## [-3.9,-1.39].three, (-1.39,-0.952].three ) and these will be ignored

    ## Warning in createDataPartition(df$interaction, p = 0.5, times = 1, list =
    ## FALSE): Some classes have a single record ( (-0.952,-0.636].three ) and these
    ## will be selected for the sample

``` r
df$train<-FALSE
df$train[trainIndex]<-TRUE
```

Let’s use some plots to verify:

``` r
histbysite<-function(plotdata) {
    ggplot(plotdata,aes(x=i)) +
        geom_histogram() +
        facet_grid(~site)
}
histbysite(df) + ggtitle("Whole Sample")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-4-1.png)<!-- -->

``` r
histbysite(df[df$train,]) + ggtitle("Training")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-4-2.png)<!-- -->

``` r
histbysite(df[!df$train,]) + ggtitle("Test")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-4-3.png)<!-- -->
