This file contains some notes on changing your Alaveteli theme for the
upgrade to Rails 3, in version 0.11 of Alaveteli.  These were written
by Henare Degan, with some additions by Mark Longair.

# Alaveteli Theme Upgrade Checks

## RAILS_ROOT/RAILS_ENV

[Example](https://github.com/henare/adminbootstraptheme/commit/857e33c9b0bc577024b476404aec4f9749f65a0b)

Check your theme for instances of:

* `RAILS_ROOT` and replace it with `Rails.root`
* `RAILS_ENV` and replace it with `Rails.env`

Note that `Rails.root` is a `Pathname`, so you can replace, for
example:

    File.join(RAILS_ROOT, 'public', 'alavetelitheme')

... with:

    Rails.root.join('public', 'alavetelitheme')

## Dispatcher

[Example](https://github.com/henare/adminbootstraptheme/commit/fba2d6b7dfdc26a25fdc1596bfe120270dd4cd0d)

This...

```ruby
require 'dispatcher'
Dispatcher.to_prepare do
```

should be replaced with this...

```ruby
Rails.configuration.to_prepare do
````

## Routes

[Example](https://github.com/henare/adminbootstraptheme/commit/87f1991dafb09401f9b17f642a94382d5a47a713)

You need to upgrade your custom routes to the new Rails syntax.

## list_public_bodies_default removed

[Example](https://github.com/openaustralia/alavetelitheme/commit/5927877af996a1afb1a23a950f0d012b52c36f83)

The list_public_bodies_default helper has been removed from Alaveteli

## Patching mailer templates has changed

[Example](https://github.com/openaustralia/alavetelitheme/commit/ffb5242973a0b2acc4981c25659fcb752b92eb97)

In `lib/patch_mailer_paths.rb` change `ActionMailer::Base.view_paths.unshift File.join(File.dirname(__FILE__), "views")` to `ActionMailer::Base.prepend_view_path File.join(File.dirname(__FILE__), "views")`

There's also `ActionMailer::Base.append_view_path` for replacing `ActionMailer::Base.view_paths <<`.

## Rename view templates

[Example](https://github.com/henare/adminbootstraptheme/commit/b616b636c283ae6cf696a6af1fa481f371baf2b6)

Rename view templates from `filename.rhtml` to `filename.html.erb`.

Run this in the root of your theme directory:

    for r in $(find lib/views -name '*.rhtml'); do echo git mv $r ${r%.rhtml}.html.erb; done

[GOTCHA!](https://github.com/openaustralia/alavetelitheme/commit/65e775488822367d981bb15ab2cbcf1fce842cc2)
One exception is mailer templates, these should be renamed to
`filename.text.erb` as we only use text emails.

## The Configuration class has been renamed

[Example](https://github.com/openaustralia/alavetelitheme/commit/db6cca4650216c6f85acffaea380727344f0f740)

Due to a naming conflict, `Configuration` has been renamed to `AlaveteliConfiguration`.

You may have this in your theme for things like `Configuration::site_name`, just change it to `AlaveteliConfiguration::site_name`

## request.request_uri is deprecated

[Example](https://github.com/openaustralia/alavetelitheme/commit/d670eeebfb049e1dc83fdb36a628f7722d2ad419)

Replace instances of `request.request_uri` with `request.fullpath`

## content-inserting <% %> block helpers are deprecated

[Example](https://github.com/openaustralia/alavetelitheme/commit/a4b13bbd76249b3a28e2a755cede20dd9db30140)

The Rails 3 releases notes are [irritatingly
imprecise](http://edgeguides.rubyonrails.org/3_0_release_notes.html#helpers-with-blocks)
about which such helpers have changed.  You can find some candidates
with this `git grep` command:

    git grep -E '<%[^=].*(_for|_tag|link_to)\b'

(Ignore `content_for` in those results.)
