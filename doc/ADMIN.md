Doing development work on the administration interface
======================================================

The Alaveteli admin interface uses Twitter's Bootstrap project to prettify it.

If you want to work on the CSS, you'll want to use
[bootstrap-sass](https://github.com/thomas-mcdonald/bootstrap-sass). Do something like:


    $ gem install bootstrap-sass
    $ gem install compass
    $ compass compile --config .compass/config.rb

To change the JavaScript, edit `public/admin/javascripts/admin.coffee`
and then run:

    $ coffee -c public/admin/javascripts/admin.coffee

That will update `public/admin/javascripts/admin.js`.