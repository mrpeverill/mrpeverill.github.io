---
layout: post
title: Keeping Participant IDs and other Sensitive Information off of Github.
date: 2024-01-26 10:00:00
---

Research participant IDs can be considered sensitive research data. Unfortunately, it's easy for them to creep into code bases. In my own workflows, they can get added to script comments, show up unintended in tables, or even display in warning messages in rmarkdown documents. Github makes it easy to publish research code, but that also means that it's easy to inadvertently share something you ought not to. Although it's possible to [remove sensitive data from Github histories](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) using tools like [git-filter-repo](https://github.com/newren/git-filter-repo), it's extremely time consuming. More importantly, once the data has been posted it's always possible that someone saved it. It's better to avoid posting information in the first place.

## Using Git Hooks to Check for Sensitive Information
Git (not github) has an underlying ability to run code when certain events happen. The system is extremely powerful, but the type of hook I want to focus on is called a pre-commit hook. This is a script that runs before you commit a repository. If the script errors out, the commit doesn't proceed. Because you have to commit your changes locally before pushing them to github, one use for this is to check our repository for data we'd rather not post. If anything is detected, the script can abort the commit and prevent you from pushing it. Here's an example script which will check a repository for NDA id's (like those used in ABCD) prior to allowing a commit:

{% gist 7b76b57de2f8dc19b926119a8f1166e0 %}

If you write this script to .git/hooks/pre-commit (the name is important) and make it executable, if you try to make a commit containing an NDA id in either a pdf file or plaintext document you will get a message like this one:

```
Error: grep found sensitive data (pattern: NDAR_INV[0-9A-Z]{8})
Aborting Commit
```

The script uses grep and pdfgrep (a separate application) to work. I'm not sure if it would work on Windows (let me know if it does).
