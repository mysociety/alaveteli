---
layout: page
title: Handling spam
---

# Handling spam

<p class="lead">
  As your Alaveteli site becomes more popular, you may find that spammers begin to target it in various ways. This guide will tell you how Alaveteli supports you in dealing with spam.
</p>

There are several ways in which spammers can cause problems on an Alaveteli site:

* [Spam emails sent to request addresses](#spam-emails-sent-to-request-addresses)
* [Spammy user profiles](#spammy-user-profiles)
* [Spammy annotations](#spammy-annotations)

We will discuss each of these in turn.

## Spam emails sent to request addresses

Spammers can send an email to the special email address for a request, causing that email to appear on the request thread, and a notification to be sent to the requester that there’s a new response to their request.

Spammers can obtain the special email for a request in two ways:

1. Alaveteli's automatic redaction tries to hide all email addresses in the public view of a response made to a request. In some cases  e.g. in some PDF files attached to responses, this may not work. Spammers then could obtain the address from the response displayed on the site.

1. The email address falls into the hands of spammers from the authority end e.g. the email account of someone at the authority is hacked and spammers get access to the address book.

### Handling spam on individual requests

Alaveteli has several ways of reducing this kind of email spam. If a spam message has already appeared on a request thread, an administrator can delete it. For
instructions on how to do this, see the admin manual section on [deleting an incoming or outgoing message]({{ page.baseurl }}/docs/running/admin_manual#deleting-an-incoming-or-outgoing-message).

To prevent further spam emails from being displayed on a request, you can use a request's **allow
new responses from...** and **handle rejected responses** settings. **Allow new responses from...**
determines who can send new responses to a request. It has three possible values:

* `anybody` - anybody with the special request email can send a response to the request. This is the default setting for a new request.
* `authority_only` - anybody who has already sent a response to the request can send a new response. Additionally, any email address that matches the authority domain can send a new response.
* `nobody` - nobody can send a new response to the request.

If a new response is sent to a request which is not allowed by its **allow
new responses from...** setting, **handle rejected responses** determines what happens to the response. It has three possible values:

* `bounce` - an email is sent to the `from` address of the response, letting the sender know that
the request is closed to new responses and asking them to contact the [contact email address]({{ page.baseurl }}/docs/customising/config#contact_email) for the site for help. The original response
message is attached.
* `holding_pen` - the response is sent to the <a href="{{ page.baseurl }}/docs/running/holding_pen">holding pen</a>. For more information on how to remove a response from the holding pen, see [removing a message from the holding pen]({{ page.baseurl }}/docs/running/admin_manual/#removing-a-message-from-the-holding-pen).
* `blackhole` -  responses are destroyed by being sent to a <a href="{{ page.baseurl }}/docs/glossary/#blackhole" class="glossary__link">black hole</a>.

Setting **allow new responses from...** to `authority_only` or `nobody` should prevent new spam emails from appearing on a particular request. If the request has completed and no more genuine responses are expected, you can set **handle rejected responses** to `blackhole`. If there's a possibility of further genuine responses, you can set it to `holding_pen`. Using the setting `bounce` in this situation may cause problems in the case where the spam is using an invalid or forged `from` address. A bounce message to an invalid address will sit in the queue of your <a href="{{ page.baseurl }}/docs/glossary/#mta" class="glossary__link">Mail Transfer Agent</a> until it times out. A bounce message to a forged address will contribute to <a href="https://en.wikipedia.org/wiki/Backscatter_%28email%29">backscatter</a> and may reduce your mail sending reputation.

### Global spam settings

By default, after 6 months of inactivity, Alaveteli
automatically changes a request's **Allow new responses from...** setting to
`authority_only`, and after 12 months, the request's **Allow new responses
from...** setting becomes `nobody`. If you are experiencing a lot of spam requests,
you can reduce these periods. See the [old requests]({{ page.baseurl }}/docs/running/requests/#old-requests-by-default-6-months-without-activity) section in the guide to managing requests for more information on how to do that.

Additionally, since Alaveteli version 0.22.2.0, it is possible to filter incoming emails to Alaveteli through a spam filter like SpamAssassin and have Alaveteli act on the results. If Alaveteli has been configured to work with a spam filter, once a request has checked that it is open to new responses from a response sender, it will also check the incoming message for a special header, defined in the <code><a href="{{ page.baseurl }}/docs/customising/config/#incoming_email_spam_header">
INCOMING_EMAIL_SPAM_HEADER</a></code> setting in the config. Alaveteli compares the value in
this header to the value defined in the <code><a href="{{ page.baseurl }}/docs/customising/config/#incoming_email_spam_threshold">
INCOMING_EMAIL_SPAM_THRESHOLD</a></code> setting in the config. If the number in the header is
bigger, the incoming message will either be silently discarded or sent to the <a href="{{ page.baseurl }}/docs/running/holding_pen">holding pen</a>, depending on the value of the <code><a href="{{ page.baseurl }}/docs/customising/config/#incoming_email_spam_action">
INCOMING_EMAIL_SPAM_ACTION</a></code> setting in the config.

To be used in this way, SpamAssassin should be configured so that it just adds a spam score header to messages coming into Alaveteli, and doesn't reject them.

### Removal of spam from the holding pen

If there is a lot of spam in the <a href="{{ page.baseurl }}/docs/running/holding_pen">holding pen</a>, you can delete it using the incoming message checkboxes on the admin page for the holding pen request. Find the holding pen by searching for 'holding_pen' on the requests page of the admin interface. In the 'incoming messages' section of the admin page for the holding pen request, you will see checkboxes and a 'Delete selected messages' button that you can use to delete multiple spam messages in one go.

### Advanced feature - rejection of incoming messages at the MTA

<div class="attention-box info">
  To set this up you will need the ability to run `rake` tasks from the command line on your copy of Alaveteli, and the ability to change the configuration files of your MTA.
</div>

For requests that are finished but are receiving lots of incoming spam, there is the option to reject incoming messages at the MTA before they ever reach Alaveteli. One reason to do this is to reduce the load on the server that runs Alaveteli as processing incoming messages in Alaveteli does use some resources.

You can generate a list of requests for which you may want to reject incoming mail at the MTA by executing:

`bundle exec config_files:set_reject_incoming_at_mta REJECTED_THRESHOLD=5 AGE_IN_MONTHS=12`

This will print out a list of requests that have **allow new responses from...**  set to  `nobody`, haven't been updated for at least a year and have received at least 5 incoming messages that were rejected. You can adjust the `REJECTED_THRESHOLD` and `AGE_IN_MONTHS` params until you get a suitable set of requests.

Run the task with the additional parameter `DRYRUN=0`. This will flag each of these requests as rejecting incoming messages at the MTA. Within Alaveteli, this means that a warning will appear on these requests in the admin interface saying that mail for them is being rejected at the MTA, and admins will not be able to change the **allow new responses from...** and **handle rejected responses** settings for them.

To produce a list of the email addresses associated with requests that are set to reject incoming mail at the MTA, you can use the task:

    rake config_files:generate_mta_rejection_list MTA=exim

Your MTA parameter should either be `exim` or `postfix`, depending on which MTA you're using. Save the output to a file `recipient-reject` in your Alaveteli `config` directory.

Now you need to configure your MTA to actually reject mail for these request addresses at SMTP time.

#### Exim configuration

Edit the file `/etc/exim4/conf.d/acl/30_exim4-config_check_rcpt` to add the following lines before the final `accept` statement:

    # Deny recipient addresses that now just get spam
    deny   recipients     = /var/www/alaveteli/config/recipient-reject

_Note:_ Replace `/var/www/alaveteli` with the correct path to alaveteli if required.

Now, execute the commands:

    update-exim4.conf
    service exim4 restart

Incoming mail for any address in the file `/var/www/alaveteli/config/recipient-reject` should now be rejected by Exim. You can test this by running a simulated SMTP session in Exim:

    exim -bh [some remote IP address]

To test the mail rejection, issue the following commands in the session

    HELO X

    MAIL FROM: <test@local.domain>

    RCPT TO: <foi+request-1234@example.com>

If `foi+request-1234@example.com` is listed in your `recipient-reject` file, you should see the line
`550 Administrative prohibition` in the response from Exim.

#### Postfix configuration

Add a line to  `/etc/postfix/main.cf` to indicate that Postfix should be checking the recipient-reject file,
and not delivering messages for other destinations.

    cat >> /etc/postfix/main.cf <<EOF
    smtpd_recipient_restrictions=check_recipient_access hash:/var/www/alaveteli/config/recipient-reject,reject_unauth_destination

_Note:_ Replace `/var/www/alaveteli` with the correct path to alaveteli if required.

Now, create a postfix lookup table from the file

    postmap /var/www/alaveteli/config/recipient-reject

Finally, restart postfix

    service postfix restart

Incoming mail for any address in `/var/www/alaveteli/config/recipient-reject` should now be rejected by Postfix. You can test this by initiating an SMTP session with the server:

    telnet localhost 25

To test the mail rejection, issue the following commands in the session

    HELO X

    MAIL FROM: <test@local.domain>

    RCPT TO: <foi+request-1234@example.com>

If `foi+request-1234@example.com` is listed in your `recipient-reject` file, you should see the line
`554 5.7.1 <foi+request-1234@example.com>: Recipient address rejected: Access denied` in the response from Postfix.

#### Unsetting rejection of incoming messages at the MTA

You can unset the rejection of incoming messages at the MTA for a given request using the rake task `unset_reject_incoming_at_mta` e.g

    bundle exec rake config_files:unset_reject_incoming_at_mta REQUEST_ID=4

This will unset the flag that shows that mail is being rejected at the MTA, and set **allow new responses from...** to `authority_only` for the request.

## Spammy user profiles

Spammers may create user accounts on Alaveteli just to publish spam links on their profile pages. You can find profiles with links in them by searching for "http" in the front end of Alaveteli and then selecting to show only users. You can delete spam user profiles - for more details on how to do this, see the admin manual section on [deleting a user]({{ page.baseurl }}/docs/running/admin_manual/#deleting-a-user).

## Spammy annotations

Spam links are also sometimes left as annotations on request threads.  This means that spam content can appear on email alerts to users. This in turn can also cause email providers to reject users’ emails alerts, as they detect spam content in the email. You can hide an annotation from the admin page for a request - the admin manual has more information about [how to do this]({{ page.baseurl }}/docs/running/admin_manual/#editing-or-hiding-annotations-comments). You can also prevent new annotations being added to a request from the request admin page using the **Are comments allowed?** setting.
