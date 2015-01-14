---
layout: page
title: Next Steps
---
# Next Steps

<p class="lead">
    OK, you've installed a copy of Alaveteli, and can see the site in a browser. What next?
</p>

   * [Create a superuser admin account](#create-a-superuser-admin-account)
   * [Load sample data](#load-sample-data)
   * [Test out the request process](#test-out-the-request-process)
   * [Import Public Authorities](#import-public-authorities)
   


## Create a superuser admin account

Alaveteli ships with an
<a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">emergency user</a>
that has access to the admin. So when you've just created a new site, you
should sign up to create your own account, then log into admin as the emergency
user to promote your new account to be an administrator with
<a href="{{ page.baseurl }}/docs/glossary/#super" class="glossary__link">super</a>
privilege.

As soon as that's done, disable the emergency user, because you don't need to
use it any more: you've superseded it with your new admin account.

Alaveteli ships with sample data that includes a dummy admin user called "Joe
Admin". If the sample data has been loaded into the database (this will depend on
how you installed), you must revoke Joe's administrator status too, because you
will be using your own admin account instead.

### Step-by-step:

First, in the browser:

* Go to `/profile/sign_in` and create a user by signing up.
* Check your email and confirm your account.
* Go to `/admin?emergency=1`, log in with the username and password you specified in
  [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
  and [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password).
  You can find these settings in `config/general.yml`.
* You're now on the Alaveteli admin page.
* Click on **Users**  (in the navigation menu across the top of the page), and
  click on your name in the list of users. On *that* page,  click **Edit**.
* Change your *Admin level* to "super" and click **Save**.
* From now on, when you are logged into your Alavateli site, you'll have access
  to the admin (at `/admin`). Furthermore, you'll see links to admin pages off
  the main site (which don't appear for regular users).

If your installation has loaded the sample data, there will be a dummy user in
your database called "Joe Admin" who has admin status too. You should remove
this status so there's no risk of it being used to access your site admin. You
can either do this while you're still logged in as the emergency user... or
else, later, logged in as yourself:

* Go to `/admin/users` or click on **Users** in the navigation menu on any
  admin page.
* Find "Joe Admin" in the list of users, and click on the name to see the
  user details. On *that* page, click **Edit**.
* Change the *Admin level* from "super" to "none" and click **Save**.
* Joe Admin no longer has admin status.

Now that your account is a superuser admin, you don't need to allow the
emergency user access to the admin. On the command line shell, edit
`/var/www/alaveteli/alaveteli/config/general.yml`:

* It's important that you change the emergency user's password (and, ideally,
  the username too) from the values Alavateli ships with, because they are
  public and hence insecure. In `general.yml`, change
  [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password)
  (and maybe [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
  too) to new, unique values.
* Additionally, you can totally disable the emergency user. Under normal
  operation you don't need it, because from now on you'll be using the admin
  user you've just created.
  Set [`DISABLE_EMERGENCY_USER`]({{ page.baseurl }}/docs/customising/config/#disable_emergency_user)
  to `true`.
* To apply these changes restart the service as a user with root privileges:
  `sudo service alaveteli restart`

You can use the same process (logged in as your admin account) to add or remove
superuser admin status to any users that are subsequently added to your site.
If you accidentally remove admin privilege from all accounts (try not to do
this, though!), you can enable the emergency user by editing the `general.yml`
file and restarting Alaveteli.

## Load sample data

If you want some dummy data to play with, you can try loading the fixtures that
the test suite uses into your development database. As the `alaveteli` user, do:

    script/load-sample-data

If the sample data has already been loaded into the database, this command won't
do anything, but will instead <abbr
title='PG::Error: ERROR:  permission denied: "RI_ConstraintTrigger_XXXXXX" is a system trigger'>fail
with an error</abbr>.

If you have added the sample data, update the Xapian search index afterwards:

    script/update-xapian-index

Remember that the sample data includes a user with admin access to your site.
You should revoke that status so it cannot be used to access your site --
follow the steps described in the previous section.

## Test out the request process

* Create a new public authority in the admin interface -- give it a name like
  "Test authority". Set the request email to an address that you will receive.

* From the main interface of the site, make a request to the new authority.

* You should receive the request email -- try replying to it. Your response
  email should appear in Alaveteli. Not working? Take a look at our
  [troubleshooting tips]({{ page.baseurl }}/docs/installing/manual_install/#troubleshooting).
  If that doesn't sort it out, [get in touch]({{ page.baseurl }}/community/) on
  the [developer mailing list](https://groups.google.com/forum/#!forum/alaveteli-dev) or [IRC](http://www.irc.mysociety.org/) for help.

## Import Public Authorities

Alaveteli can import a list of public authorities and their contact email addresses from a CSV file.

Follow the instructions for
[uploading public authority data]({{ page.baseurl }}/docs/running/admin_manual/#creating-changing-and-uploading-public-authority-data).

## Set the amount of time authorities will be given to respond to requests

In most countries that have a Freedom of Information law, authorities
have a certain number of days in order to respond to requests. Alaveteli
helps requesters by reminding them when their request is overdue for a
response according to the law. You can set the number of days an
authority is given to respond to a request in the
[`REPLY_LATE_AFTER_DAYS`]({{ page.baseurl }}/docs/customising/config/#reply_late_after_days),
[`REPLY_VERY_LATE_AFTER_DAYS`]({{ page.baseurl }}/docs/customising/config/#reply_very_late_after_days)
and
[`SPECIAL_REPLY_VERY_LATE_AFTER_DAYS`]({{ page.baseurl }}/docs/customising/config/#special_reply_very_late_after_days)
options in `config/general.yml`. Most laws specify that the days are
either working days, or calendar days. You can set this using the
[`WORKING_OR_CALENDAR_DAYS`]({{ page.baseurl }}/docs/customising/config/#working_or_calendar_days)
option in `config/general.yml`.

## Add some public holidays

<div class="attention-box info">
Interface introduced in Alaveteli version 0.21
</div>

Alaveteli calculates the due dates of requests taking account of the
public holidays you enter into the admin interface. If you have set the
[`WORKING_OR_CALENDAR_DAYS`]({{ page.baseurl }}/docs/customising/config/#working_or_calendar_days)
setting for Alaveteli to `working`, the date when a response to a
request is officially overdue will be calculated in days that are not
weekends or public holidays. If you have set
[`WORKING_OR_CALENDAR_DAYS`]({{ page.baseurl }}/docs/customising/config/#working_or_calendar_days)
to `calendar`, the date will be calculated in calendar days, but if the
due date falls on a public holiday or weekend day, then the due date is
considered to be the next week day that isn't a holiday.

To add public holidays, go to the "Holidays" tab of the admin interface.
From here you can either add each holiday day by hand, using the "New
Holiday" button, or you can create multiple holidays at once using the
"Create holidays from suggestions or iCal feed" button.

## Start thinking about customising Alaveteli

Check out [our guide]({{ page.baseurl }}/docs/customising/).
