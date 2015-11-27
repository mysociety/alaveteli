---
layout: page
title: Make a new theme
---

# How to make a new theme

<p class="lead">
    Every new Alaveteli site
    <a href="{{ page.baseurl}}/docs/customising/themes">needs its own theme</a>
    before it can go into the world. This page describes the process for making
    a new one.
</p>

There's a lot you can do with Alaveteli's themes, but to get started all you
need to know is: your site must have one. Later, you can
[read all about themes]({{ page.baseurl }}/docs/customising/themes) and the
things you can do with them. But for now we suggest you follow these steps.
You'll end up with your own theme, with your own colour and logo displayed on
your Alaveteli site. Once you've got that, you can — of course — make more
customisations, as fancy as you like.

If you've already got a theme, well done! Also, remember that there are other
[ways to customise your site]({{ page.baseurl }}/docs/customising/) — such as
configuration settings and translations — in addition to the changes you can
make to the theme.

But if you've just installed the software (for example, you've just completed a
[Vagrant installation]({{ page.baseurl }}/docs/installing/vagrant)), follow
these steps to make your Alaveteli site your own.

<div class="attention-box helpful-hint">
  If you're using Vagrant, remember that you log into the virtual machine's
  shell by <code>cd</code>ing into the root directory of your Alaveteli 
  installation, and then issuing <code>vagrant&nbsp;ssh</code>.
</div>

## 1. Fork the Alaveteli theme

If you're familiar with git, you can do this your own way. But we think the
easiest way is to do it within GitHub.

You'll need your own account on GitHub to do this.

* Go to [github.com/mysociety/alavetelitheme](https://github.com/mysociety/alavetelitheme)
* Click on the **Fork** button (top right) — if you've got access to multiple
  accounts/organisations you can choose which one to use

...and it's done!

## 2. Give it a unique name

You must give the repo you've just forked its own name. Ideally, it should
match the sitename you're planning on running (for example, if your site is
going to be `abcexample.org`, then a good name would be `abcexample-theme`).
Don't worry if you haven't really sorted out the domain or even the final name
yet; this is just so your theme cannot be mistaken for any others.

To do this, go to [GitHub](https://github.com) and find the repo you've just
forked, and click on its **Settings** tab. You can edit the name of the repo
there: change it from `alavetelitheme` to your own theme name.

Note: if you're using the Firefox browser, you may encounter a bug with GitHub+Firefox
here, so you might need to use another browser for this operation.

<div class="attention-box warning">
  You <strong>must</strong> rename the repo, because you'll run into problems
  later on if <em>your</em> theme has the same name as the default one,
  <code>alavetelitheme</code>.
</div>

## 3. Point your config at your new repo

Now your own theme repo exists, point your Alaveteli install at it by editing
the
<code><a href="{{ page.baseurl }}/docs/customising/config/#theme_urls">THEME_URLS</a></code>
setting in the config file.

Set it to the URL of your uniquely named repo, for example:

    THEME_URLS:
         - 'https://github.com/yourgithub/abcexample-theme.git'


<div class="attention-box helpful-hint">
  <p>
    Other types of git urls are available but are much harder to get up and
    running inside a Vagrant box. Github maintains a
    <a href="https://help.github.com/articles/which-remote-url-should-i-use/">useful
    guide to git url formats</a> if you would like to read more about this.
  </p>
</div>

## 4. Tell Alaveteli to get its theme

Next, tell Alaveteli to pull the repo down from the URL in `THEMES_URL`, and
install it as the theme your installation will use.

Do this by issuing this command within your Vagrant virtual machine:

    bundle exec rake themes:install

Alaveteli will connect to GitHub, pull down your theme repo and put it in the
right place within your Alaveteli installation.

When it's finished, you can see that your theme (that is, all the files from
the repo) has been reproduced in `lib/themes/`.

<div class="attention-box helpful-hint">
  <p>
    If you're just following this guide to see what is possible and have no
    interest in saving the changes you're about to make, you can skip this bit!
  </p>
  <p>
    On the command line (back on your own machine rather than inside Vagrant
    box), <code>cd</code> to your theme's folder inside <code>lib/themes/</code>. 
    This is where your theme code will live, and is where you should issue your 
    git commands from to commit and push your changes.
  </p>
  <p>
    You now need to issue this command:

    <pre><code>git checkout master</code></pre>

    This is needed because, unless you've told it explicitly to do otherwise,
    the rake task won't checkout a branch (instead, it leaves you in a 
    "detached HEAD" state) -- see the 
    <a href="#branches-within-your-theme-repo">note about branches</a> below.

    You are now all set to be able to push your changes back to Github when
    you're happy with them.
  </p>
</div>

## 5. Change the primary colour

You're ready to make a change and see that change appear in your browser.

Alaveteli uses a set of basic <a href="{{ page.baseurl }}/docs/glossary/#sass"
class="glossary__link">Sass</a> variables to define the layout for the site on
different device sizes, and some basic styling.

There's more than one way to do this, but the simplest way (which means you
can most easily see the consequences of any changes you make) is to edit your
theme's files inside Alaveteli installation, within `lib/themes/`. Within that
directory, find your theme and edit
`/assets/stylesheets/responsive/custom.scss`. Find the Sass variable
`$color_primary` and change the colour value. For example:

    $color_primary = #ff0000;

This sets the primary colour to red (`#ff0000` in that example can be any CSS
colour value). Of course, this is just to show that you _can_ change it: really, you can change anything in this theme — that's the whole point.

The development server automatically rebuilds any resources that have been
changed; in this case it means it will build new versions of the CSS file from
the Sass, containing the new colour you've picked.

## 6. See the new colour!

Before trying to look at the site, make sure the development server is running.
Within the Vagrant VM, do this to start it:

    bundle exec rails server

Now if you look at the home page on your development server, you'll
see the new colour.

<div class="attention-box helpful-hint">
  If you change the colour again, and it doesn't update when you refresh the
  browser, you <em>might</em> need to delete everything in 
  <code>/tmp/cache</code> within your installation to force this
  behaviour.
</div>

## 7. Change the logo

To change the default, placeholder logo, replace the file
`/assets/images/logo.png` with one of your own (don't change the filename —
you're really just replacing its contents). We recommend you keep to the same
aspect ratio to start with, because that will fit in with the rest of the
layout. Of course, you can change all of that later: this is just to get you
comfortable with the most important changes.

Alaveteli uses Rails'
[asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html),
and when it gathers its resources together (of which your `logo.png` is one),
anything in your custom theme will override what's in the default theme. So
your logo will appear if you put it into your theme, because you've nominated
your theme as the primary one in `THEME_URLS`. Any resources that aren't in
your theme will be taken from the core asset directories instead.

## 8. Commit the changes

<div class="attention-box info">
  If you're used to working with git, you might have done this already, when
  you changed the colour and the logo.
</div>

You need to commit the changes (that is, tell git what you changed and why),
and then push those changes back up to your repo on GitHub. This is because,
eventually, your production site will be pulling the theme from there (you'll
put the URL of your theme in your `THEME_URLS` config setting for your
production server, just like you have done for this development one).

There are different ways to commit your changes, but here's one method:
<div class="attention-box helpful-hint">
  Note that <em>inside</em> your Vagrant virtual machine, you won't be able to
  access GitHub with your user settings, and so on. So you will need to do this
  from "outside" the VM. This can trip you up because the command shell looks
  very similar when you are inside a <code>vagrant&nbsp;ssh</code> session,
  and when you are not.
</div>

    git commit -a -m "changed colour and logo to match brand style" 

The `-a` option of the `commit` command commits all the files you've changed,
and the `-m` option adds a message describing what you did and why.


Well done — when you've customised your theme and pushed that work back up to
GitHub, you're well on your way to having your own Alaveteli site.

One good reason for pushing to GitHub is that we can look at it (or, more
usefully perhaps, run it on a development server of our own by putting that URL
into our `THEME_URLS` setting) if you need any help.

### Branches *within* your theme repo

The `rake themes:install` task deploys your theme by pulling it down from the
nominated URL. As mentioned above, by default this will check out your theme at
the most recent commit on the `master` branch. It does this with a detached
HEAD, which is usually what you want in production (because you won't be making
changes there), but might catch you out in your development environment. All
this means is that after running the rake task, the state of the git repo
that's now inside `lib/themes` isn't explicitly on any branch: you can remedy
this manually with <code>git&nbsp;checkout&nbsp;<em>branch-name</em></code>.

However, there's a setting in your config called
[`THEME_BRANCH`]({{page.baseurl }}/docs/customising/config/#theme_branch)
that overrides this behaviour. If you're not familiar with git you don't need
to worry about it (because your changes will probably be going onto `master`,
the default, anyway). But if you are using branches in your development, use
this config setting to tell your Alaveteli which branch of your theme repo you
want <code>rake&nbsp;themes:install</code> to deploy.

Remember that this is about the branch your *theme* repo is on, not the main
git repo for your Alaveteli install. The `themes:install` rake task is cloning
your theme repo into a directory *inside* the Alaveteli repo. That is, it's one
repo inside another. If you don't like working like this, you can always edit
your theme files in a repo elsewhere, and push them up to GitHub before you do
`themes:install`.

---

## More changes...

That's the end of the step-by-step process to make your own theme, but of
course this is just the start of your customisation.

For more detail about what you can do in your theme, see
[more about themes]({{ page.baseurl }}docs/customising/themes/#customising-the-help-pages).

### Changing the help pages

Every Alaveteli site is doing _something_ unique so you must update the help
information that comes as standard. Perhaps some of it is applicable, but we
promise you that the "boilerplate" text in the default theme is not ready to go
onto your own site without some changes.

The help pages live in your theme like the other customisations, and not the
core site code, so that you can update the core Alaveteli code on your site
whenever we release a newer version without that update colliding with your
changes.

See
[changing the help pages]({{ page.baseurl }}docs/customising/themes/#customising-the-help-pages) 
for details.

As usual, whenever you make changes, commit them and be sure to push them
up the your theme's repo on GitHub.

## Not just in English?

Although Alaveteli ships with English as the default, the platform happily
runs in any language.

If we've already got translations available for the language (or
language<strong>s</strong>: Alaveteli supports multilingual sites too),
you can probably just switch them on.

However, note that switching the language, and some of the consequences of
customising in one or more different languages, is not really happening in your
theme. It's a site-wide issue, and — especially if you need to add new
translations — this is handled differently. Get in touch with us and we'll help
— we're always happy to add new translations to Alaveteli.


