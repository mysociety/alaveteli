# Alaveteli documentation (github pages)

The `gh-branch` contains the Alaveteli documentation that is hosted
as GitHub Pages, and available at code.alaveteli.org

The styling comes from the 
[mysociety-docs-theme](https://github.com/mysociety/mysociety-docs-theme)
repo, which is included as a submodule in the `theme/` directory.

If you're building locally, and you change the theme, rebuild it with:

`sass --update theme/sass/:assets/css/`

To view the documentation locally using Jekyll, do something like:

`jekyll serve --watch`



