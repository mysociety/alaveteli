When installing an Alaveteli site, there are a few things that you
might want to do to customise it, beyond the available settings in the
`config/general` file.

The most common requirement is to brand the site: at a minimum,
inserting your own logo and colour scheme.  You may also want to tweak
the different states that a request can go through.

There may also be other things you want to customise; drop a line on
the developer's mailing list to discuss, if so.  We're still working
out the best way of doing these kinds of customisations!

In any case, the important principle to bear in mind is that the less
you override and customise the code, the easier your site will be to
maintain in the long term.  Any customisation is possible, but for
each customisation beyond the simple cases documented here, ask
yourself or your client, "can we possibly live without this?"  If the
answer is "no", then consider starting a discussion about a pluggable
way of achieving your goals, rather than overriding any of the core
code.

# General principles

We try to encapsulate all site-specific functionality in one of these
places:

* Site configuration (e.g. the name of your site, the available
  languages etc -- all in `config/general`)
* Data (e.g. the public bodies to whom requests should be addressed)
* A rails "plugin", installed in `vendor/plugins/`.  We call these
  "themes".

This document is about what you can do in a theme.

To get started, install the sample theme by running 

    ./script/plugin install git://github.com/sebbacon/alavetelitheme.git

# Branding the site 

The core templates that comprise the layout and user interface of an
Alaveteli site live in `app/views/`.  They are use Rails' ERB syntax.
For example, the template for the home page lives at
`app/views/general/frontpage.rhtml`, and the template for the "about
us" page is at `app/views/help/about.rhtml`.

Any of these pages can be overridden in your own theme, by placing
them at a corresponding location within your theme's `lib/` directory.
These means that a file at
`vendor/plugins/alavetelitheme/lib/help/about.rhml` will appear in
place of the core "about us" file.

Rails expects all its stylesheets to live at `<railshome>/public`,
which presents a problem for plugins.  Here's how we solve it: the
stylesheet and associated resources for your theme live (by
convention) in at `alavetelitheme/public/`.  This is symlinked from
the main Rails app -- see `alavetelitheme/install.rb` to see how this
happens.

The partial at
`alavetelitheme/lib/views/general/_before_head_end.rhtml` includes the
custom CSS in your theme's stylesheet folder (by convention, in
`alavetelitheme/public/stylesheets/`), with:

     <%= stylesheet_link_tag "/alavetelitheme/stylesheets/custom" %>

...which will, of course, need changing for your theme.

# Customising the request states

As mentioned above, if you can possibly live with the
[default Alaveteli request statuses](https://github.com/sebbacon/alaveteli/wiki/Alaveteli's-request-statuses),
it would be good to do so.  Note that you can set how many days counts
as "overdue" in the main site config file.

If you can't live with the states as they are, there's a very basic
way to add to them (which will get improved over time).  There's not
currently a way to remove any.

To do this, create two modules in your theme,
`InfoRequestCustomStates` and `RequestControllerCustomStates`.  The
former must have these two methods:

* `theme_extra_states`: return a list of tags which identify the extra states you'd like to support
* `theme_display_status`: return human-readable strings corresponding with these tags

The latter must have one method:

* `theme_describe_state`: Return a notice for the user suitable for
  displaying after they've categorised a request; and redirect them to
  a suitable next page

When you've added your extra states, you also need to create the following files in your theme:

* `lib/views/general/_custom_state_descriptions.rhtml`: Descriptions
  of your new states, suitable for displaying to end users
* `lib/views/general/_custom_state_transitions_complete.rhtml`:
  Descriptions for any new states that you might characterise as
  'completion' states, for displaying on the categorisation form that
  we ask requestors to fill out
* `lib/views/general/_custom_state_transitions_pending.rhtml`: As
  above, but for new states you might characterise as 'pending'
  states.

You can see examples of these customisations in
[this commit](https://github.com/sebbacon/informatazyrtare-theme/commit/2b240491237bd72415990399904361ce9bfa431d)
for the Kosovan version of Alaveteli, Informata Zyrtare (ignore the
file `lib/views/general/_custom_state_transitions.rhtml`, which is
unused).
