---
layout: post
title: A Tool for Comparing Publication Lists
date: 2022-09-21 10:00:00
---

Every web page (e.g. research gate, ORCID, google scholar) seems to want to curate their own list of my publications, which leaves me to try and bring them in to alignment. Here's a quickpython script which will scrape the DOI numbers from two of either a webpage or text file and compare them for unique values you might want to add to the other. It also searches for duplicate DOIs. Use at your own risk, and you might have to edit the list of pre-print server DOI prefixes if you use something other than bioarxiv or psyarxiv. The script requires the pandas library.

You can download the script from [github](https://github.com/mrpeverill/cv_compare)

# cv_compare.py

Compare lists of publications with DOIs. Also reports duplicate DOIs.

Currently only works with two arguments. Will take a url or file path. Searches DOI's for a manually coded list of preprint servers so those can be reported.

usage:

```
~/Dropbox/code/cv_compare$ ./cv_compare.py ex_a.txt ex_b.txt

```
Outputs:

```
ex_a.txt
Found 4 DOI codes
Found 3 preprints
___________________
ex_b.txt
Found 4 DOI codes
Found 2 preprints
___________________
Duplicate Detection:
1 duplicates in A
3    10.1101/2021.09.22.461242
Name: DOIs, dtype: object
0 duplicates in B
Series([], Name: DOIs, dtype: object)
___________________
Unique Items:
                         DOIs  preprint                      DOIsB preprintB
1   10.1101/2021.03.13.432212  preprint
2  10.1016/j.jaac.2015.06.010
0                                         10.3389/fninf.2016.00002
1                                            10.31234/osf.io/97qbw  preprint
3                                        10.1016/j.dcn.2017.11.006
```
