---
layout: page
title: Next Steps
---
# Next Steps

<p class="lead">
    OK, you've installed a copy of Alaveteli, and can see the site in a browser. What next?
</p>

## Load test data

If you want some dummy data to play with, you can try loading the fixtures that
the test suite uses into your development database. You can do this with:

    script/load-sample-data

## Create a superuser account for yourself

* Sign up for a new account on the site. You should receive a confirmation email. Click on the link in it to confirm the account.

* Get access to the [admin interface]({{ site.baseurl}}docs/running/admin_manual/#administrator-privileges). You can find the
`general.yml` file you'll need to get the `ADMIN_USERNAME` and
`ADMIN_PASSWORD` credentials in the `config` subdirectory of the
directory Alaveteli was installed into.

* In the admin interface, go to the 'Users' section and find the account you just created. Promote the account you just created to superuser status by clicking the 'Edit' button and setting the 'Admin level' value to 'super'.

## Test out the request process

* Create a new public authority in the admin interface - give it a name something like 'Test authority'. Set the request email to an address that you will receive.

* From the main interface of the site, make a request to the new authority.

* You should receive the request email - try replying to it. Your response email should appear in Alaveteli. Not working? Take a look at our [troubleshooting tips]({{ site.baseurl}}docs/installing/manual_install/#troubleshooting). If that doesn't sort it out, [get in touch]({{ site.baseurl}}community/) on the project mailing list or IRC
for help.

## Start thinking about customising Alaveteli

Check out [our guide]({{ site.baseurl}}docs/customising/).
