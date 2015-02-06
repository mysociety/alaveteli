---
layout: page
title: Themes
---

# Alaveteli's themes

<p class="lead">
    Alaveteli uses <strong>themes</strong> to make the site look and run
    differently from the default.
    Simple changes like colour and logo are relatively easy, but themes can also
  control more complex things like <em>how</em> the site behaves.
</p>

When you customise your Alaveteli site, there is a lot you can change just
by editing the [config settings]({{ site.baseurl }}docs/customising/config/).
But if you want to change the way the site looks, or add more specific
behaviour, you'll need to make a **theme**.

You don't need to be a programmer in order to make simple changes, but you will
need to be confident enough to copy and change some files. If you're not sure
about this, [ask for help](/community/)!

## What you might want to change

The most common requirement is to brand the site: at a minimum,
[inserting your own logo](#changing-the-logo) and [colour scheme](#changing-the-colour-scheme).  You may also want to tweak
the different states that a request can go through.  You'll also want
to edit the categories that public bodies can appear in (i.e. the
groupings on the left hand side of the
"[View authorities](https://www.whatdotheyknow.com/body/list/all)" page
on WhatDoTheyKnow.

There may also be other things you want to customise -- drop a line on
the developer's mailing list to discuss what you need.  We're still working
out the best way of doing these kinds of customisations!

In any case, the important principle to bear in mind is that the less
you override and customise the code, the easier your site will be to
maintain in the long term.  Any customisation is possible, but for
each customisation beyond the simple cases documented here, ask
yourself (or your client), "can we possibly live without this?"  If the
answer is "no", then consider starting a discussion about a pluggable
way of achieving your goals, rather than overriding any of the core
code.

## General principles

We try to encapsulate all site-specific functionality in one of these
places:

* Site [configuration]({{ site.baseurl }}docs/customising/config/)
  (e.g., the name of your site, the available
  languages, and so on &mdash; all in `config/general.yml`)
* Data (e.g. the public bodies to whom requests should be addressed)
* A theme, installed in `lib/themes`.

This document is about what you can do in a theme.

By default, the sample theme ("alavetelitheme") has already been
installed.  See the setting
[`THEME_URLS`]({{ site.baseurl }}docs/customising/config/#theme_urls)
in `general.yml` for an explanation.

You can also install the sample theme by hand, by running:

    bundle exec rake themes:install

The sample theme contains examples for nearly everything you might
want to customise.  You should probably make a copy, rename it, and
use that as the basis for your own theme.

## Make sure your theme is as lightweight as possible

The more you put in your theme, the harder it will be to upgrade to
future versions of Alaveteli.  Everything you place in your theme
overrides things in the core theme, so if you make a new "main
template", then new widgets that appear in the core theme won't appear
on your website.

Therefore, you should consider how you can brand your website without
changing much in the core theme.  The ideal would be if you are able
to rebrand the site by only changing the CSS.  You will also need to
add custom help pages, as described below.

## Branding the site

The core templates that comprise the layout and user interface of an
Alaveteli site live in `app/views/`.  They use Rails' ERB syntax.
For example, the template for the home page lives at
`app/views/general/frontpage.html.erb`, and the template for the "about
us" page is at `app/views/help/about.html.erb`.

Obviously, you *could* edit those core files directly, but this would
be a Bad Idea, because you would find it increasingly hard to do
upgrades.  Having said that, sometimes you may want to change the core
templates in a way that would benefit everyone, in which case, discuss
the changes on the mailing list, make them in a fork of Alaveteli, and
then issue a pull request.

Normally, however, you should override these pages **in your own
theme**, by placing them at a corresponding location within your
theme's `lib/` directory.  These means that a file at
`lib/themes/alavetelitheme/lib/views/help/about.html.erb` will appear
instead of the core "about us" file.

### Changing the logo

Alaveteli uses Rails' [asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html) to convert and compress stylesheets written in
<a href="{{ site.baseurl }}docs/glossary/#sass" class="glossary__link">Sass</a>,
the css extension language, to minified concatenated css. Assets are stored in core Alaveteli under `app/assets` - in `fonts`, `images`, `javascripts` and `stylesheets`.
The default theme has corresponding asset directories in `alavetelitheme/assets` Asset files placed in these directories will  override those in the core directories. As with templates, a file at `lib/themes/alavetelitheme/assets/images/logo.png` will appear on the site instead of the logo from `app/assets/images/logo.png`.

### Changing the colour scheme

Alaveteli uses a set of basic
<a href="{{ site.baseurl }}docs/glossary/#sass" class="glossary__link">Sass</a>
modules to define the layout for the site on different device sizes, and some basic styling. These modules are in `app/assets/stylesheets/responsive`. The colours and fonts are added in the theme - alavetelitheme defines them in `lib/themes/alavetelitheme/assets/stylesheets/responsive/custom.scss`. Colours used in the theme are defined as variables at the top of this file and you can edit them here.

### Changing other styling

To change other styling, you can add to or edit the styles in `lib/themes/alavetelitheme/assets/stylesheets/responsive/custom.scss`. Styles defined here will override those in the sass modules in `app/assets/stylesheets/responsive` as they will be imported last by `app/assets/stylesheets/responsive/all.scss`. However, if you want to substantially change the way a particular part of the site is laid out, you may want to override one of the core sass modules. You could override the layout of the front page, for example, by copying `app/assets/stylesheets/responsive/_frontpage_layout.scss` to `lib/themes/alavetelitheme/assets/stylesheets/responsive/_frontpage_layout.scss` and editing it.

You can load extra stylesheets and javascript files by adding them to `lib/themes/alavetelitheme/lib/views/general/_before_head_end.html.erb`

## Adding your own categories for public bodies

Categories are implemented in Alaveteli using tags. Specific tags can be
used to group authorities together as a category. Categories themselves
are grouped under category headings on the side of the "View
authorities" page. You can create, edit and reorder categories and
category headings in the admin interface, from the "Categories" admin
menu item. You can apply the category tags you have created to
authorities under the "Authorities" admin menu item. For an authority to
appear under a category, the category's "category tag" must be one of
the tags applied to the authority.

## Customising the request states

As mentioned above, if you can possibly live with the
[default Alaveteli request statuses]({{ site.baseurl }}docs/customising/states/),
it would be good to do so.  Note that you can set how many days counts
as "overdue" in the main site config file &mdash;
see [`REPLY_LATE_AFTER_DAYS`]({{ site.baseurl }}docs/customising/config/#reply_late_after_days).

If you can't live with the states as they are, there's a very basic
way to add to them (which will get improved over time).  There's not
currently a way to remove any easily.  There is an example of how to
do this in the `alavetelitheme`.

To do add states, create two modules in your theme,
`InfoRequestCustomStates` and `RequestControllerCustomStates`.  The
former must have these methods:

* `theme_calculate_status`: return a tag to identify the current state of the request
* `theme_extra_states`: return a list of tags which identify the extra states you'd like to support
* `theme_display_status`: return human-readable strings corresponding with these tags

The latter must have one method:

* `theme_describe_state`: Return a notice for the user suitable for
  displaying after they've categorised a request; and redirect them to
  a suitable next page

When you've added your extra states, you also need to create the following files in your theme:

* `lib/views/general/_custom_state_descriptions.html.erb`: Descriptions
  of your new states, suitable for displaying to end users
* `lib/views/general/_custom_state_transitions_complete.html.erb`:
  Descriptions for any new states that you might characterise as
  'completion' states, for displaying on the categorisation form that
  we ask requestors to fill out
* `lib/views/general/_custom_state_transitions_pending.html.erb`: As
  above, but for new states you might characterise as 'pending'
  states.

You can see examples of these customisations in
[this commit](https://github.com/sebbacon/informatazyrtare-theme/commit/2b240491237bd72415990399904361ce9bfa431d)
for the Kosovan version of Alaveteli, Informata Zyrtare (ignore the
file `lib/views/general/_custom_state_transitions.html.erb`, which is
unused).

## Customising the help pages

If you're running Alaveteli in another language, you'll want to show
your users localised versions of the help pages. Even if you're running
the site in English, the default help pages in Alaveteli are taken from
WhatDoTheyKnow, and are therefore relevant only to the UK. You should
take these pages as inspiration, but review their content with a view to
your jurisdiction. The important pages to customise and translate are:

* [About](https://github.com/mysociety/alaveteli/blob/master/app/views/help/about.html.erb): why the website exists, why it works, etc
* [contact](https://github.com/mysociety/alaveteli/blob/master/app/views/help/contact.html.erb): how to get in touch
* [credits](https://github.com/mysociety/alaveteli/blob/master/app/views/help/credits.html.erb): who is involved in the site.  Importantly, includes a section on how users can help the project.
* [officers](https://github.com/mysociety/alaveteli/blob/master/app/views/help/officers.html.erb): information for the officers who deal with FOI at authorities.  They get a link to this page in emails that the site sends them.
* [privacy](https://github.com/mysociety/alaveteli/blob/master/app/views/help/privacy.html.erb): privacy policy, plus information making it clear that requests are going to appear on the internet.  Let users know if they are allowed to use pseudonyms in your jurisdiction.
* [requesting](https://github.com/mysociety/alaveteli/blob/master/app/views/help/requesting.html.erb): the main help page about making requests.  How it works, how to decide who to write to, what they can expect in terms of responses, how to make appeals, etc.
* [unhappy](https://github.com/mysociety/alaveteli/blob/master/app/views/help/unhappy.html.erb): users are taken to this page after a request that has been somehow unsuccessful (e.g. the request has been refused, or the authority is insisting on a postal request).  The page should encourage them to keep going, e.g. by starting a new request or addressing it to a different body.
* [why email](https://github.com/mysociety/alaveteli/blob/master/app/views/help/_why_they_should_reply_by_email.html.erb): a snippet of information that explains why users should insist on replies by email.  This is displayed next to requests that have "gone postal".

You can add your own help pages to your site by replacing the default
pages in your theme with your own versions, using a locale suffix for
each page to indicate what language the page is written in. No locale
suffix is needed for pages written for the [default locale]({{ site.baseurl }}docs/customising/config/#default_locale) for the site.
For example, [alavetelitheme contains help
pages](https://github.com/mysociety/alavetelitheme/tree/master/lib/views/help)
for the default 'en' locale and an example Spanish 'about' page.


## Adding new pages in the navigation

`alavetelitheme/lib/config/custom-routes.rb` allows you to extend the base routes in
Alaveteli.  The example in `alavetelitheme` adds an extra help page.
You can also use this to override the behaviour of specific pages if
necessary.

## Adding or overriding models and controllers

If you need to extend the behaviour of Alaveteli at the controller or model level, see `alavetelitheme/lib/controller_patches.rb` and `alavetelitheme/lib/model_patches.rb` for examples.

## Working with themes

You can use [`script/switch-theme.rb`](https://github.com/mysociety/alaveteli/blob/master/script/switch-theme.rb) to set the current theme if you are working with multiple themes. This might be useful for switching between the default `alavetelitheme` and your own fork.
