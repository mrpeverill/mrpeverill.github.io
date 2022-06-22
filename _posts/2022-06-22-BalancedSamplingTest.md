---
layout: post
title: "Splitting a Sample by Multiple Balancing Factors"
author: "Matthew Peverill"
date: "2022-06-22"
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
of several variables in R.

``` r
library(sn)
library(tidyverse); library(ggthemes); theme_set(theme_tufte())
library(caret)
library(pander)
library(simstudy)
```

# Two factors using caret

``` r
set.seed(3453)
#rsn samples from a skewed normal distribution
site1<-data.frame(i=rsn(2000,alpha=-3))
site2<-data.frame(i=rsn(4000,alpha=0))
site3<-data.frame(i=rsn(1000,alpha=3))
sitedesc<-factor(c(rep("site.one",2000),
                   rep("site.two",4000),
                   rep("site.three",1000)))
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
                    include.lowest = TRUE,
                    labels=FALSE),
        # interact the factors to make a unique level for each combination.
        interaction = interaction(i.bin, site) 
    )
pander(head(df))
```

|    i    |   site   | i.bin | interaction |
|:-------:|:--------:|:-----:|:-----------:|
| -1.504  | site.one |   1   | 1.site.one  |
| -1.031  | site.one |   2   | 2.site.one  |
| -0.8683 | site.one |   3   | 3.site.one  |
| -1.119  | site.one |   2   | 2.site.one  |
| -0.4916 | site.one |   4   | 4.site.one  |
| -0.4953 | site.one |   4   | 4.site.one  |

Now that the factors are combined, we can sample evenly from them using
caret

``` r
trainIndex<-createDataPartition(df$interaction,p=.5,times=1,list=FALSE)
```

    ## Warning in createDataPartition(df$interaction, p = 0.5, times = 1, list =
    ## FALSE): Some classes have no records ( 9.site.one, 10.site.one, 1.site.three,
    ## 2.site.three ) and these will be ignored

    ## Warning in createDataPartition(df$interaction, p = 0.5, times = 1, list =
    ## FALSE): Some classes have a single record ( 3.site.three ) and these will be
    ## selected for the sample

``` r
df$train<-FALSE
df$train[trainIndex]<-TRUE
```

Let’s use some plots to verify:

``` r
histbysite<-function(plotdata,xvar="i") {
    ggplot(plotdata,aes_string(x=xvar)) +
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

# Many factors

## Simulate

Let’s simulate some other factors to add to our test dataset.

``` r
simdef<-defData(varname="age",
                dist="categorical",
                formula=genCatFormula(n=5))
simdef<-defData(simdef,varname="sex",
                dist="binary",
                formula=".5")
simdef<-defData(simdef,varname="parent.ed",
                dist="categorical",
                formula=genCatFormula(n=6))
simdef<-defData(simdef,varname="missingdata",
                dist="binary",
                formula=".2")

df2<-cbind(df[,1:3],genData(nrow(df),simdef)) # drop interaction
df2 <- df2 %>%
  select(id, everything()) # put id at the front of the dataset

factorialize<-c("i.bin","age","sex","missingdata","parent.ed")
df2[factorialize] <- lapply(df2[factorialize], factor)

pander(head(df2))
```

| id  |    i    |   site   | i.bin | age | sex | parent.ed | missingdata |
|:---:|:-------:|:--------:|:-----:|:---:|:---:|:---------:|:-----------:|
|  1  | -1.504  | site.one |   1   |  4  |  1  |     3     |      0      |
|  2  | -1.031  | site.one |   2   |  5  |  1  |     3     |      0      |
|  3  | -0.8683 | site.one |   3   |  5  |  0  |     3     |      0      |
|  4  | -1.119  | site.one |   2   |  4  |  1  |     4     |      1      |
|  5  | -0.4916 | site.one |   4   |  5  |  0  |     3     |      1      |
|  6  | -0.4953 | site.one |   4   |  3  |  1  |     5     |      1      |

Then we partition as above:

``` r
df2$interaction=interaction(df2[,-c(1:2)])
trainIndex<-createDataPartition(df2$interaction,p=.5,times=1,list=FALSE)
```

    ## Warning in createDataPartition(df2$interaction, p = 0.5, times = 1,
    ## list = FALSE): Some classes have no records ( site.three.1.1.0.1.0,
    ## site.three.2.1.0.1.0, site.three.3.1.0.1.0, site.three.4.1.0.1.0,
    ## site.three.6.1.0.1.0, site.one.7.1.0.1.0, site.one.8.1.0.1.0,
    ## site.one.9.1.0.1.0, site.one.10.1.0.1.0, site.three.1.2.0.1.0,
    ## site.three.2.2.0.1.0, site.three.3.2.0.1.0, site.one.4.2.0.1.0,
    ## site.three.4.2.0.1.0, site.one.7.2.0.1.0, site.one.8.2.0.1.0,
    ## site.one.9.2.0.1.0, site.one.10.2.0.1.0, site.three.1.3.0.1.0,
    ## site.three.2.3.0.1.0, site.three.3.3.0.1.0, site.three.4.3.0.1.0,
    ## site.one.8.3.0.1.0, site.one.9.3.0.1.0, site.one.10.3.0.1.0,
    ## site.three.10.3.0.1.0, site.three.1.4.0.1.0, site.three.2.4.0.1.0,
    ## site.three.4.4.0.1.0, site.three.5.4.0.1.0, site.one.9.4.0.1.0,
    ## site.one.10.4.0.1.0, site.three.1.5.0.1.0, site.three.2.5.0.1.0,
    ## site.three.3.5.0.1.0, site.three.4.5.0.1.0, site.three.5.5.0.1.0,
    ## site.one.9.5.0.1.0, site.one.10.5.0.1.0, site.three.1.1.1.1.0,
    ## site.three.2.1.1.1.0, site.three.3.1.1.1.0, site.three.4.1.1.1.0,
    ## site.one.7.1.1.1.0, site.one.9.1.1.1.0, site.one.10.1.1.1.0,
    ## site.three.1.2.1.1.0, site.three.2.2.1.1.0, site.three.3.2.1.1.0,
    ## site.two.3.2.1.1.0, site.three.4.2.1.1.0, site.three.5.2.1.1.0,
    ## site.one.9.2.1.1.0, site.one.10.2.1.1.0, site.three.1.3.1.1.0,
    ## site.three.2.3.1.1.0, site.three.3.3.1.1.0, site.three.4.3.1.1.0,
    ## site.three.5.3.1.1.0, site.three.6.3.1.1.0, site.one.7.3.1.1.0,
    ## site.three.7.3.1.1.0, site.one.8.3.1.1.0, site.one.9.3.1.1.0,
    ## site.one.10.3.1.1.0, site.three.1.4.1.1.0, site.three.2.4.1.1.0,
    ## site.three.3.4.1.1.0, site.three.4.4.1.1.0, site.one.8.4.1.1.0,
    ## site.one.9.4.1.1.0, site.one.10.4.1.1.0, site.three.1.5.1.1.0,
    ## site.three.2.5.1.1.0, site.three.3.5.1.1.0, site.three.4.5.1.1.0,
    ## site.two.4.5.1.1.0, site.three.5.5.1.1.0, site.one.6.5.1.1.0,
    ## site.three.6.5.1.1.0, site.one.7.5.1.1.0, site.one.8.5.1.1.0,
    ## site.one.9.5.1.1.0, site.one.10.5.1.1.0, site.three.1.1.0.2.0,
    ## site.three.2.1.0.2.0, site.three.3.1.0.2.0, site.three.4.1.0.2.0,
    ## site.three.5.1.0.2.0, site.one.7.1.0.2.0, site.one.8.1.0.2.0,
    ## site.one.9.1.0.2.0, site.one.10.1.0.2.0, site.three.1.2.0.2.0,
    ## site.three.2.2.0.2.0, site.three.3.2.0.2.0, site.three.4.2.0.2.0,
    ## site.one.7.2.0.2.0, site.one.8.2.0.2.0, site.one.9.2.0.2.0,
    ## site.one.10.2.0.2.0, site.three.1.3.0.2.0, site.three.2.3.0.2.0,
    ## site.three.3.3.0.2.0, site.three.4.3.0.2.0, site.three.5.3.0.2.0,
    ## site.three.6.3.0.2.0, site.one.9.3.0.2.0, site.one.10.3.0.2.0,
    ## site.three.1.4.0.2.0, site.three.2.4.0.2.0, site.three.3.4.0.2.0,
    ## site.three.4.4.0.2.0, site.one.5.4.0.2.0, site.three.5.4.0.2.0,
    ## site.one.7.4.0.2.0, site.one.8.4.0.2.0, site.one.9.4.0.2.0, site.one.10.4.0.2.0,
    ## site.three.1.5.0.2.0, site.three.2.5.0.2.0, site.three.3.5.0.2.0,
    ## site.three.5.5.0.2.0, site.three.6.5.0.2.0, site.one.7.5.0.2.0,
    ## site.one.8.5.0.2.0, site.one.9.5.0.2.0, site.one.10.5.0.2.0,
    ## site.three.1.1.1.2.0, site.three.2.1.1.2.0, site.three.3.1.1.2.0,
    ## site.three.4.1.1.2.0, site.three.5.1.1.2.0, site.three.6.1.1.2.0,
    ## site.one.8.1.1.2.0, site.one.9.1.1.2.0, site.one.10.1.1.2.0,
    ## site.three.1.2.1.2.0, site.three.2.2.1.2.0, site.three.3.2.1.2.0,
    ## site.three.4.2.1.2.0, site.three.5.2.1.2.0, site.three.6.2.1.2.0,
    ## site.one.8.2.1.2.0, site.one.9.2.1.2.0, site.one.10.2.1.2.0,
    ## site.three.1.3.1.2.0, site.three.2.3.1.2.0, site.three.3.3.1.2.0,
    ## site.three.4.3.1.2.0, site.three.6.3.1.2.0, site.one.7.3.1.2.0,
    ## site.one.9.3.1.2.0, site.one.10.3.1.2.0, site.three.1.4.1.2.0,
    ## site.three.2.4.1.2.0, site.three.3.4.1.2.0, site.one.7.4.1.2.0,
    ## site.one.9.4.1.2.0, site.one.10.4.1.2.0, site.three.1.5.1.2.0,
    ## site.three.2.5.1.2.0, site.three.3.5.1.2.0, site.three.4.5.1.2.0,
    ## site.three.5.5.1.2.0, site.one.6.5.1.2.0, site.one.8.5.1.2.0,
    ## site.one.9.5.1.2.0, site.one.10.5.1.2.0, site.three.1.1.0.3.0,
    ## site.three.2.1.0.3.0, site.three.3.1.0.3.0, site.three.4.1.0.3.0,
    ## site.three.5.1.0.3.0, site.one.8.1.0.3.0, site.one.9.1.0.3.0,
    ## site.one.10.1.0.3.0, site.three.1.2.0.3.0, site.three.2.2.0.3.0,
    ## site.three.3.2.0.3.0, site.three.5.2.0.3.0, site.one.8.2.0.3.0,
    ## site.one.9.2.0.3.0, site.one.10.2.0.3.0, site.one.1.3.0.3.0,
    ## site.three.1.3.0.3.0, site.three.2.3.0.3.0, site.three.3.3.0.3.0,
    ## site.three.4.3.0.3.0, site.three.5.3.0.3.0, site.one.8.3.0.3.0,
    ## site.one.9.3.0.3.0, site.one.10.3.0.3.0, site.three.1.4.0.3.0,
    ## site.three.2.4.0.3.0, site.three.3.4.0.3.0, site.three.4.4.0.3.0,
    ## site.three.5.4.0.3.0, site.one.7.4.0.3.0, site.three.7.4.0.3.0,
    ## site.one.8.4.0.3.0, site.one.9.4.0.3.0, site.one.10.4.0.3.0,
    ## site.three.1.5.0.3.0, site.three.2.5.0.3.0, site.three.3.5.0.3.0,
    ## site.three.4.5.0.3.0, site.three.5.5.0.3.0, site.three.6.5.0.3.0,
    ## site.one.9.5.0.3.0, site.one.10.5.0.3.0, site.three.1.1.1.3.0,
    ## site.three.2.1.1.3.0, site.three.3.1.1.3.0, site.three.4.1.1.3.0,
    ## site.three.5.1.1.3.0, site.one.7.1.1.3.0, site.one.9.1.1.3.0,
    ## site.one.10.1.1.3.0, site.three.1.2.1.3.0, site.three.2.2.1.3.0,
    ## site.three.3.2.1.3.0, site.three.4.2.1.3.0, site.three.5.2.1.3.0,
    ## site.one.9.2.1.3.0, site.one.10.2.1.3.0, site.three.1.3.1.3.0,
    ## site.three.2.3.1.3.0, site.three.3.3.1.3.0, site.three.4.3.1.3.0,
    ## site.three.5.3.1.3.0, site.three.6.3.1.3.0, site.three.7.3.1.3.0,
    ## site.one.9.3.1.3.0, site.one.10.3.1.3.0, site.three.1.4.1.3.0,
    ## site.three.2.4.1.3.0, site.three.3.4.1.3.0, site.three.4.4.1.3.0,
    ## site.three.5.4.1.3.0, site.one.7.4.1.3.0, site.one.8.4.1.3.0,
    ## site.one.9.4.1.3.0, site.one.10.4.1.3.0, site.three.10.4.1.3.0,
    ## site.three.1.5.1.3.0, site.three.2.5.1.3.0, site.three.3.5.1.3.0,
    ## site.three.5.5.1.3.0, site.one.6.5.1.3.0, site.three.6.5.1.3.0,
    ## site.one.8.5.1.3.0, site.one.9.5.1.3.0, site.one.10.5.1.3.0,
    ## site.three.1.1.0.4.0, site.three.2.1.0.4.0, site.three.3.1.0.4.0,
    ## site.three.4.1.0.4.0, site.three.5.1.0.4.0, site.three.6.1.0.4.0,
    ## site.one.8.1.0.4.0, site.one.9.1.0.4.0, site.one.10.1.0.4.0,
    ## site.three.1.2.0.4.0, site.three.2.2.0.4.0, site.three.3.2.0.4.0,
    ## site.three.4.2.0.4.0, site.three.5.2.0.4.0, site.one.8.2.0.4.0,
    ## site.one.9.2.0.4.0, site.one.10.2.0.4.0, site.three.1.3.0.4.0,
    ## site.three.2.3.0.4.0, site.three.3.3.0.4.0, site.one.4.3.0.4.0,
    ## site.three.4.3.0.4.0, site.one.9.3.0.4.0, site.one.10.3.0.4.0,
    ## site.three.1.4.0.4.0, site.three.2.4.0.4.0, site.three.3.4.0.4.0,
    ## site.three.4.4.0.4.0, site.one.7.4.0.4.0, site.one.8.4.0.4.0,
    ## site.one.9.4.0.4.0, site.one.10.4.0.4.0, site.three.1.5.0.4.0,
    ## site.three.2.5.0.4.0, site.three.3.5.0.4.0, site.three.4.5.0.4.0,
    ## site.one.8.5.0.4.0, site.one.9.5.0.4.0, site.one.10.5.0.4.0,
    ## site.three.1.1.1.4.0, site.three.2.1.1.4.0, site.three.3.1.1.4.0,
    ## site.three.4.1.1.4.0, site.three.5.1.1.4.0, site.one.6.1.1.4.0,
    ## site.three.7.1.1.4.0, site.one.8.1.1.4.0, site.one.9.1.1.4.0,
    ## site.one.10.1.1.4.0, site.three.1.2.1.4.0, site.three.2.2.1.4.0,
    ## site.three.3.2.1.4.0, site.three.4.2.1.4.0, site.three.6.2.1.4.0,
    ## site.one.7.2.1.4.0, site.one.8.2.1.4.0, site.one.9.2.1.4.0, site.one.10.2.1.4.0,
    ## site.three.1.3.1.4.0, site.three.2.3.1.4.0, site.three.3.3.1.4.0,
    ## site.one.8.3.1.4.0, site.three.8.3.1.4.0, site.one.9.3.1.4.0,
    ## site.one.10.3.1.4.0, site.three.1.4.1.4.0, site.three.2.4.1.4.0,
    ## site.three.3.4.1.4.0, site.three.4.4.1.4.0, site.one.6.4.1.4.0,
    ## site.three.6.4.1.4.0, site.one.8.4.1.4.0, site.one.9.4.1.4.0,
    ## site.one.10.4.1.4.0, site.three.1.5.1.4.0, site.three.2.5.1.4.0,
    ## site.three.3.5.1.4.0, site.three.4.5.1.4.0, site.one.7.5.1.4.0,
    ## site.one.8.5.1.4.0, site.one.9.5.1.4.0, site.one.10.5.1.4.0,
    ## site.three.1.1.0.5.0, site.three.2.1.0.5.0, site.three.3.1.0.5.0,
    ## site.three.4.1.0.5.0, site.one.6.1.0.5.0, site.one.9.1.0.5.0,
    ## site.one.10.1.0.5.0, site.three.1.2.0.5.0, site.three.2.2.0.5.0,
    ## site.three.3.2.0.5.0, site.three.4.2.0.5.0, site.three.6.2.0.5.0,
    ## site.one.8.2.0.5.0, site.one.9.2.0.5.0, site.one.10.2.0.5.0,
    ## site.three.1.3.0.5.0, site.three.2.3.0.5.0, site.three.3.3.0.5.0,
    ## site.three.4.3.0.5.0, site.one.8.3.0.5.0, site.three.8.3.0.5.0,
    ## site.one.9.3.0.5.0, site.one.10.3.0.5.0, site.three.1.4.0.5.0,
    ## site.three.2.4.0.5.0, site.three.3.4.0.5.0, site.three.4.4.0.5.0,
    ## site.three.5.4.0.5.0, site.one.8.4.0.5.0, site.one.9.4.0.5.0,
    ## site.one.10.4.0.5.0, site.three.1.5.0.5.0, site.three.2.5.0.5.0,
    ## site.three.3.5.0.5.0, site.three.4.5.0.5.0, site.one.9.5.0.5.0,
    ## site.one.10.5.0.5.0, site.three.1.1.1.5.0, site.three.2.1.1.5.0,
    ## site.three.3.1.1.5.0, site.three.5.1.1.5.0, site.one.8.1.1.5.0,
    ## site.one.9.1.1.5.0, site.one.10.1.1.5.0, site.three.1.2.1.5.0,
    ## site.three.2.2.1.5.0, site.three.3.

    ## Warning in createDataPartition(df2$interaction, p = 0.5, times = 1,
    ## list = FALSE): Some classes have a single record ( site.three.5.1.0.1.0,
    ## site.three.8.1.0.1.0, site.one.6.2.0.1.0, site.three.6.2.0.1.0,
    ## site.three.5.3.0.1.0, site.three.8.3.0.1.0, site.three.3.4.0.1.0,
    ## site.one.6.4.0.1.0, site.three.6.4.0.1.0, site.one.7.4.0.1.0,
    ## site.one.8.4.0.1.0, site.three.9.4.0.1.0, site.one.8.5.0.1.0,
    ## site.three.6.1.1.1.0, site.one.8.1.1.1.0, site.one.2.2.1.1.0,
    ## site.two.4.2.1.1.0, site.one.6.2.1.1.0, site.one.7.2.1.1.0,
    ## site.one.8.2.1.1.0, site.one.1.3.1.1.0, site.three.10.3.1.1.0,
    ## site.two.4.4.1.1.0, site.one.6.4.1.1.0, site.one.7.4.1.1.0,
    ## site.two.1.5.1.1.0, site.three.7.5.1.1.0, site.three.9.5.1.1.0,
    ## site.three.10.5.1.1.0, site.three.6.1.0.2.0, site.three.7.1.0.2.0,
    ## site.two.3.2.0.2.0, site.three.5.2.0.2.0, site.three.10.2.0.2.0,
    ## site.one.5.3.0.2.0, site.one.8.3.0.2.0, site.three.9.4.0.2.0,
    ## site.three.4.5.0.2.0, site.one.6.5.0.2.0, site.one.4.1.1.2.0,
    ## site.one.7.1.1.2.0, site.three.7.1.1.2.0, site.one.7.2.1.2.0,
    ## site.three.8.2.1.2.0, site.three.7.3.1.2.0, site.one.8.3.1.2.0,
    ## site.two.2.4.1.2.0, site.three.4.4.1.2.0, site.three.5.4.1.2.0,
    ## site.three.6.4.1.2.0, site.two.3.5.1.2.0, site.one.7.5.1.2.0,
    ## site.three.7.5.1.2.0, site.two.8.5.1.2.0, site.three.9.5.1.2.0,
    ## site.one.5.1.0.3.0, site.three.6.1.0.3.0, site.three.10.1.0.3.0,
    ## site.one.6.2.0.3.0, site.three.6.2.0.3.0, site.three.8.2.0.3.0,
    ## site.three.10.2.0.3.0, site.one.7.3.0.3.0, site.three.6.4.0.3.0,
    ## site.three.8.4.0.3.0, site.two.2.5.0.3.0, site.one.8.5.0.3.0,
    ## site.two.8.5.0.3.0, site.three.9.1.1.3.0, site.one.8.2.1.3.0,
    ## site.one.8.3.1.3.0, site.two.2.4.1.3.0, site.three.6.4.1.3.0,
    ## site.three.4.5.1.3.0, site.one.5.5.1.3.0, site.three.7.5.1.3.0,
    ## site.three.8.5.1.3.0, site.one.6.1.0.4.0, site.one.7.1.0.4.0,
    ## site.three.5.3.0.4.0, site.one.6.3.0.4.0, site.three.6.3.0.4.0,
    ## site.one.8.3.0.4.0, site.two.3.4.0.4.0, site.three.5.4.0.4.0,
    ## site.three.6.4.0.4.0, site.three.5.5.0.4.0, site.three.10.1.1.4.0,
    ## site.three.5.2.1.4.0, site.one.6.2.1.4.0, site.three.4.3.1.4.0,
    ## site.three.6.3.1.4.0, site.one.7.3.1.4.0, site.two.7.3.1.4.0,
    ## site.three.5.4.1.4.0, site.three.8.4.1.4.0, site.three.9.4.1.4.0,
    ## site.two.4.5.1.4.0, site.three.5.5.1.4.0, site.one.8.1.0.5.0,
    ## site.three.5.2.0.5.0, site.one.7.2.0.5.0, site.three.7.2.0.5.0,
    ## site.three.10.2.0.5.0, site.three.5.3.0.5.0, site.one.7.3.0.5.0,
    ## site.one.5.4.0.5.0, site.one.6.4.0.5.0, site.three.6.4.0.5.0,
    ## site.three.5.5.0.5.0, site.one.8.5.0.5.0, site.three.10.5.0.5.0,
    ## site.one.3.1.1.5.0, site.three.4.1.1.5.0, site.one.7.1.1.5.0,
    ## site.one.1.2.1.5.0, site.three.4.2.1.5.0, site.one.6.2.1.5.0,
    ## site.three.6.2.1.5.0, site.one.7.2.1.5.0, site.three.7.2.1.5.0,
    ## site.one.8.2.1.5.0, site.three.6.3.1.5.0, site.three.5.4.1.5.0,
    ## site.three.6.4.1.5.0, site.three.8.4.1.5.0, site.three.9.4.1.5.0,
    ## site.three.4.5.1.5.0, site.three.7.5.1.5.0, site.three.8.5.1.5.0,
    ## site.one.3.1.0.6.0, site.one.5.1.0.6.0, site.three.5.1.0.6.0,
    ## site.one.8.1.0.6.0, site.three.10.1.0.6.0, site.three.5.2.0.6.0,
    ## site.one.7.2.0.6.0, site.one.8.2.0.6.0, site.one.3.3.0.6.0,
    ## site.one.7.3.0.6.0, site.one.5.4.0.6.0, site.three.5.4.0.6.0,
    ## site.three.5.5.0.6.0, site.two.3.1.1.6.0, site.one.5.1.1.6.0,
    ## site.three.6.1.1.6.0, site.three.8.1.1.6.0, site.one.7.2.1.6.0,
    ## site.three.7.2.1.6.0, site.one.7.3.1.6.0, site.three.4.4.1.6.0,
    ## site.three.6.4.1.6.0, site.one.7.4.1.6.0, site.two.3.5.1.6.0,
    ## site.one.3.1.0.1.1, site.three.5.1.0.1.1, site.three.6.1.0.1.1,
    ## site.two.6.1.0.1.1, site.one.7.1.0.1.1, site.three.8.1.0.1.1,
    ## site.two.9.1.0.1.1, site.one.1.2.0.1.1, site.one.2.2.0.1.1, site.one.6.2.0.1.1,
    ## site.three.7.2.0.1.1, site.two.7.2.0.1.1, site.two.8.2.0.1.1,
    ## site.two.9.2.0.1.1, site.three.10.2.0.1.1, site.three.4.3.0.1.1,
    ## site.one.5.3.0.1.1, site.one.6.3.0.1.1, site.three.7.3.0.1.1,
    ## site.two.7.3.0.1.1, site.two.8.3.0.1.1, site.three.10.3.0.1.1,
    ## site.two.1.4.0.1.1, site.two.2.4.0.1.1, site.two.6.4.0.1.1, site.one.7.4.0.1.1,
    ## site.three.8.4.0.1.1, site.two.8.4.0.1.1, site.three.9.4.0.1.1,
    ## site.three.10.4.0.1.1, site.two.10.4.0.1.1, site.two.3.5.0.1.1,
    ## site.one.4.5.0.1.1, site.one.5.5.0.1.1, site.two.5.5.0.1.1,
    ## site.three.7.5.0.1.1, site.two.7.5.0.1.1, site.two.8.5.0.1.1,
    ## site.one.1.1.1.1.1, site.two.1.1.1.1.1, site.two.2.1.1.1.1, site.two.3.1.1.1.1,
    ## site.one.6.1.1.1.1, site.three.8.1.1.1.1, site.three.9.1.1.1.1,
    ## site.three.10.1.1.1.1, site.two.10.1.1.1.1, site.one.5.2.1.1.1,
    ## site.three.5.2.1.1.1, site.two.6.2.1.1.1, site.two.8.2.1.1.1,
    ## site.two.10.2.1.1.1, site.two.1.3.1.1.1, site.two.2.3.1.1.1,
    ## site.one.3.3.1.1.1, site.one.5.3.1.1.1, site.two.5.3.1.1.1, site.one.7.3.1.1.1,
    ## site.two.7.3.1.1.1, site.three.8.3.1.1.1, site.two.8.3.1.1.1,
    ## site.three.9.3.1.1.1, site.two.9.3.1.1.1, site.one.2.4.1.1.1,
    ## site.two.2.4.1.1.1, site.one.3.4.1.1.1, site.two.4.4.1.1.1, site.two.5.4.1.1.1,
    ## site.two.6.4.1.1.1, site.three.8.4.1.1.1, site.three.9.4.1.1.1,
    ## site.two.9.4.1.1.1, site.one.2.5.1.1.1, site.two.6.5.1.1.1, site.one.7.5.1.1.1,
    ## site.three.7.5.1.1.1, site.three.9.5.1.1.1, site.two.9.5.1.1.1,
    ## site.three.10.5.1.1.1, site.one.1.1.0.2.1, site.two.2.1.0.2.1,
    ## site.two.4.1.0.2.1, site.one.5.1.0.2.1, site.three.6.1.0.2.1,
    ## site.two.6.1.0.2.1, site.two.9.1.0.2.1, site.one.2.2.0.2.1, site.one.5.2.0.2.1,
    ## site.three.6.2.0.2.1, site.two.6.2.0.2.1, site.three.7.2.0.2.1,
    ## site.two.9.2.0.2.1, site.one.1.3.0.2.1, site.one.3.3.0.2.1, site.two.3.3.0.2.1,
    ## site.one.4.3.0.2.1, site.three.6.3.0.2.1, site.three.7.3.0.2.1,
    ## site.two.7.3.0.2.1, site.three.8.3.0.2.1, site.two.10.3.0.2.1,
    ## site.two.1.4.0.2.1, site.one.3.4.0.2.1, site.two.4.4.0.2.1, site.one.5.4.0.2.1,
    ## site.two.5.4.0.2.1, site.one.6.4.0.2.1, site.three.7.4.0.2.1,
    ## site.one.8.4.0.2.1, site.one.1.5.0.2.1, site.two.1.5.0.2.1, site.one.2.5.0.2.1,
    ## site.one.3.5.0.2.1, site.one.4.5.0.2.1, site.three.5.5.0.2.1,
    ## site.two.5.5.0.2.1, site.three.7.5.0.2.1, site.two.7.5.0.2.1,
    ## site.two.8.5.0.2.1, site.three.9.5.0.2.1, site.one.1.1.1.2.1,
    ## site.two.5.1.1.2.1, site.one.6.1.1.2.1, site.one.7.1.1.2.1,
    ## site.three.9.1.1.2.1, site.two.9.1.1.2.1, site.three.10.1.1.2.1,
    ## site.one.1.2.1.2.1, site.two.1.2.1.2.1, site.two.2.2.1.2.1, site.two.3.2.1.2.1,
    ## site.one.5.2.1.2.1, site.two.6.2.1.2.1, site.three.7.2.1.2.1,
    ## site.two.8.2.1.2.1, site.three.10.2.1.2.1, site.two.10.2.1.2.1,
    ## site.one.1.3.1.2.1, site.one.2.3.1.2.1, site.two.3.3.1.2.1,
    ## site.one.4.3.1.2.1, site.two.4.3.1.2.1, site.one.6.3.1.2.1, site.two.7.3.1.2.1,
    ## site.two.8.3.1.2.1, site.three.9.3.1.2.1, site.one.1.4.1.2.1,
    ## site.one.2.4.1.2.1, site.two.2.4.1.2.1, site.two.3.4.1.2.1, site.one.5.4.1.2.1,
    ## site.one.6.4.1.2.1, site.two.6.4.1.2.1, site.three.8.4.1.2.1,
    ## site.three.9.4.1.2.1, site.two.10.4.1.2.1, site.two.3.5.1.2.1,
    ## site.two.4.5.1.2.1, site.one.5.5.1.2.1, site.two.5.5.1.2.1, site.two.9.5.1.2.1,
    ## site.two.10.5.1.2.1, site.two.2.1.0.3.1, site.two.3.1.0.3.1,
    ## site.one.4.1.0.3.1, site.two.4.1.0.3.1, site.two.5.1.0.3.1, site.one.7.1.0.3.1,
    ## site.three.7.1.0.3.1, site.two.9.1.0.3.1, site.two.1.2.0.3.1,
    ## site.one.2.2.0.3.1, site.two.5.2.0.3.1, site.three.7.2.0.3.1,
    ## site.two.7.2.0.3.1, site.two.9.2.0.3.1, site.two.1.3.0.3.1,
    ## site.two.5.3.0.3.1, site.two.7.3.0.3.1, site.two.8.3.0.3.1, site.two.9.3.0.3.1,
    ## site.two.2.4.0.3.1, site.one.3.4.0.3.1, site.two.4.4.0.3.1, site.one.8.4.0.3.1,
    ## site.two.9.4.0.3.1, site.one.4.5.0.3.1, site.three.5.5.0.3.1,
    ## site.three.6.5.0.3.1, site.one.8.5.0.3.1, site.three.8.5.0.3.1,
    ## site.two.3.1.1.3.1, site.two.9.1.1.3.1, site.one.1.2.1.3.1, site.two.1.2.1.3.1,
    ## site.two.3.2.1.3.1, site.three.5.2.1.3.1, site.three.8.2.1.3.1,
    ## site.two.1.3.1.3.1, site.one.2.3.1.3.1, site.two.3.3.1.3.1, site.one.4.3.1.3.1,
    ## site.two.4.3.1.3.1, site.three.5.3.1.3.1, site.two.5.3.1.3.1,
    ## site.one.6.3.1.3.1, site.two.6.3.1.3.1, site.three.7.3.1.3.1,
    ## site.two.8.3.1.3.1, site.two.9.3.1.3.1, site.one.1.4.1.3.1,
    ## site.two.1.4.1.3.1, site.two.2.4.1.3.1, site.one.3.4.1.3.1, site.two.3.4.1.3.1,
    ## site.one.4.4.1.3.1, site.one.5.4.1.3.1, site.one.6.4.1.3.1, site.two.6.4.1.3.1,
    ## site.one.7.4.1.3.1, site.three.9.4.1.3.1, site.two.9.4.1.3.1,
    ## site.one.1.5.1.3.1, site.one.4.5.1.3.1, site.two.4.5.1.3.1, site.one.5.5.1.3.1,
    ## site.two.9.5.1.3.1, site.one.1.1.0.4.1, site.two.2.1.0.4.1, site.two.5.1.0.4.1,
    ## site.three.6.1.0.4.1, site.three.9.1.0.4.1, site.two.10.1.0.4.1,
    ## site.one.1.2.0.4.1, site.two.1.2.0.4.1, site.one.2.2.0.4.1, site.one.3.2.0.4.1,
    ## site.two.3.2.0.4.1, site.two.4.2.0.4.1, site

``` r
df2$train<-FALSE
df2$train[trainIndex]<-TRUE
```

Testing:

``` r
histbysite(df2) + ggtitle("i in Whole Sample")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-1.png)<!-- -->

``` r
histbysite(df2[df2$train,]) + ggtitle("i in Training")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-2.png)<!-- -->

``` r
histbysite(df2[!df2$train,]) + ggtitle("i in Test")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-3.png)<!-- -->

``` r
barbysite<-function(plotdata,xvar="i") {
    ggplot(plotdata,aes_string(x=xvar)) +
        geom_bar() +
        facet_grid(~site)
}

barbysite(df2,"age") + ggtitle("Age in Whole Sample")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-4.png)<!-- -->

``` r
barbysite(df2[df2$train,],"age") + ggtitle("Age in Training")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-5.png)<!-- -->

``` r
barbysite(df2[!df2$train,],"age") + ggtitle("Age in Test")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-6.png)<!-- -->

``` r
barbysite(df2,"missingdata") + ggtitle("missingdata in Whole Sample")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-7.png)<!-- -->

``` r
barbysite(df2[df2$train,],"missingdata") + ggtitle("missingdata in Training")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-8.png)<!-- -->

``` r
barbysite(df2[!df2$train,],"missingdata") + ggtitle("missingdata in Test")
```

![](/assets/img/BalancedSamplingTest/unnamed-chunk-7-9.png)<!-- -->
