This is my personal website, based on al-folio (https://github.com/alshedivat/al-folio) A simple and clean [Jekyll](https://jekyllrb.com/) theme for academics.

# Notes on updating:
The source for the page is in the 'source' branch (directories start with '_' and have .md). The deploy script generates a webpage based on these (no prefix, files end in .html).

## Environment

The system you build the webpage on must have Imagemagick installed.

## Editing:

1. Make sure source is checked out.
2. Make changes.
3. Commit them.
4. Run chcp.com 65001
5. THEN run the deploy script.
6. If there are errors (currently the assets folder doesn't get moved), resolve them and then push to origin.

## Other notes

You can [preview the webpage locally](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll) before you deploy it. The local preview will update automatically as you make changed to files -- very handy! jekyll-diagrams and imagemagick were disabled because I don't use them and they were causing build errors for me.

When you run deploy, if you don't see 'deployed succesfully' then something went wrong in the process. Sometimes the deploy script fails silently.

# License

The theme is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Originally, **al-folio** was based on the [\*folio theme](https://github.com/bogoli/-folio) (published by [Lia Bogoev](http://liabogoev.com) and under the MIT license).
