---
layout: post
title: My Workflow for Posting to Jekyll using Rmarkdown
date: 2022-06-21 12:40
---

A lot has been written about writing Jekyll (the platform that generates this website -- it's frequently used with github pages), but I haven't seen a one size fits all solution. This is how I'm doing it (thanks to [Johannes Hellmuth](https://jchellmuth.com/news/jekyll/website/code/2020/01/04/Rmarkdown-posts-to-Jekyll.html) for getting me started)

The magic happens in the yaml header of your rmarkdown file. Here's the header from [a recent post]({% post_url 2022-06-21-BalancedSamplingTest %}):

```yaml
---
layout: post
title: "Splitting a Sample by Two Balancing Factors"
author: "Matthew Peverill"
date: "`r Sys.Date()`"
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

```

In addition to the standard fields, you need to have everything that your Jekyll website will expect (in my case layout: post). Then preserve_yaml makes it so that those yaml fields get passed to the md that is built by rmarkdown. The 'knit: ' is a hook for the rstudio 'knit' button that changes the output file to save an md file in the correct location for my website, with todays date as a prefix (which is the naming convention I use for posts). 

Then, in your setup block, include something like this:

```r
knitr::opts_knit$set(base.dir = "~/Dropbox/mrpeverill-website/", base.url = "/")
knitr::opts_chunk$set(fig.path = "assets/img/BalancedSamplingTest/")
```

Obviously you will need to change the base.dir and fig.path as appropriate. base.dir needs to be absolute within your filesystem, fig.path needs to be relative to theh base.url. I like to store my images in a subfolder named after the post (because typically they just get named 'unnamed chunk img 4-4' or some such, which would conflict with other posts.
