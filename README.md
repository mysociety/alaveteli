# Alaveteli documentation (github pages)

The `gh-branch` contains the Alaveteli documentation that is hosted
as GitHub Pages, and available at <http://www.alaveteli.org>

The mySociety documentation "github pages" sites share the same styling.
It comes from the 
[mysociety-docs-theme](https://github.com/mysociety/mysociety-docs-theme)
repo, which is included as a submodule in the `theme/` directory.

## Updating the CSS, manually

If you're building locally, and you change the theme, rebuild it with:

    sass --update --style=compressed theme/sass/global.scss:assets/css/global.css

There's also an Alaveteli-specific stylesheet, so do:

    sass --update --style=compressed assets/sass/alaveteli-org.scss:assets/css/alaveteli-org.css

You can use `--watch` instead of `--update` to continually monitor for changes.

## Viewing locally manually

To view the documentation locally using Jekyll, do something like:

    jekyll serve --watch


## Using grunt to work locally

If you run grunt (there's a Gruntfile in the repo for this branch) then the CSS
will automagically update if you change it, *and* pages magically refresh whenever
you change any of the files. It's like `--watch` on steroids.

### Installation
In the below you could of course run `sudo gem install` or `npm install -g` but
I personally never think that's a good idea. You must already have gem and git
installed (you probably do).

```
gem install --no-document --user-install github-pages
# Add ~/.gem/ruby/2.0.0/bin/ or similar to your $PATH
# Check you can run "jekyll"
git clone --recursive -b gh-pages https://github.com/mysociety/alaveteli alaveteli-pages
cd alaveteli-pages
```

If you only want to edit the *text* of the site, this is all you need. Run
`jekyll serve --watch` to run a webserver of the static site, and make changes
to the text you want.

If you want to edit the CSS or JS, or you'd like live reloading of changes in
your web browser, you might as well set up the thing that monitors it all for
you. You will need npm already installed.

```
gem install --no-document --user-install sass
npm install grunt-cli
npm install
node_modules/.bin/grunt
```

This will start up a watcher that monitors the files and automatically compiles
SASS, JavaScript, and runs `jekyll build` when necessary. It also live reloads
your web pages.

Lastly, if you'd like to add more JavaScript *libraries* than the ones already,
you'll additionally need to install bower and use it to fetch the libraries
used:

```
npm install bower
node_modules/.bin/bower install
```

Then use bower to install a new library and add it to the `Gruntfile.js`.

