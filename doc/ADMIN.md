adminbootstraptheme
===================

A theme for the Alaveteli admin interface that uses Twitter's
Bootstrap project to prettify it.  It depends on (and is the default
admin theme for) Alaveteli verion 0.6 or above.

If you want to work on the CSS, you'll want to use
[bootstrap-sass](https://github.com/thomas-mcdonald/bootstrap-sass). Do something like:


    $ gem install bootstrap-sass
    $ gem install compass
    $ compass compile --config .compass/config.rb

The javascript is included in a funky way
[for reasons explained in this commit](https://github.com/sebbacon/adminbootstraptheme/commit/45a73d53fc9e8f0b728933ff58764bd8d0612dab).
To change it, edit the coffeescript at
`lib/view/general/admin.coffee`, and then do something like:

    $ coffee -o /tmp/ -c lib/views/general/admin.coffee
    $ mv /tmp/admin.js lib/views/general/admin_js.erb
    
See 
[tags](https://github.com/mysociety/adminbootstraptheme/tags) for the correct version of the code to use with your version of Alaveteli.

