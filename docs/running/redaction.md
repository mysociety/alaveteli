---
layout: page
title: Redacting Sensitive Information
---

# Redacting Sensitive Information

<p class="lead">
  Redacting means removing or hiding part of a message so it cannot be read:
  you are effectively removing part of a document from your site. Typically you
  do this to conceal sensitive (usually, that means personal) information on
  the public site. Alaveteli supports an automatic form of redaction using
  <a href="{{ site.baseurl }}docs/glossary/#censor-rule" class="glossary__link">censor rules</a>.
  These can be powerful, so must be used with caution.
</p>

This page describes redaction in Alaveteli. It explains how to add censor rules, and
contains a detailed example of how we use this to prevent publication of citizens'
national ID numbers in the Nicaraguan installation of Alaveteli.

<div class="attention-box info">
  Redaction only affects what is <em>shown</em> on the site. It does not remove
  anything from the emails that Alaveteli sends out.
</div>

<div class="attention-box warning">
  Automatic redaction can be complex. Before you use decide to use it, you
  should be familiar with other ways to hide information on your site. You can
  manually edit message text and annotations, and you can also hide whole
  request pages or individual messages. For an overview of the various methods
  available to you, see
  <a href="{{ site.baseurl }}docs/running/hiding_information">hiding or removing information</a>.
</div>

Alaveteli supports redaction because it _automatically publishes_
correspondance between a requester and the authority. The most common need for
redaction is when one or more of the messages in that correspondance contain
personal or sensitive information. Sometimes this is because the requester
included personal information in the outgoing request. Often the authority, by
automatically quoting the incoming email in their reply, then includes that
information _again_ in their response. This is one example; there are lots of
other reasons why sensitive information might be included in messages &mdash;
hence the need for redaction.

## Overview of redaction

Alaveteli's automatic redaction requires that you can predict the following. Together,
these form a censor rule:

* *the specific pattern of text that you want to redact*
  <br>
  This might be a particular word, email address or number; or
  a particular pattern (described using a 
  <a href="{{ site.baseurl }}docs/glossary/#regexp" class="glossary__link">regular expression</a>)
* *the range of messages to which this redaction applies*
  <br>
  This could be _all_ messages, or only messages relating to a specific user
* *the replacement text*
  <br>
  The word or words that should be used instead of the redacted text. We
  recommend something like "<code>[REDACTED]</code>".

For example, your can tell Alaveteli to automatically replace the word `swordfish`
with `[password]` in any messages relating to a request created by user Groucho
with email `groucho@example.com`.

A regular expression (regexp) is a method of pattern-matching often used by
programmers, and if the redaction you want is more complicated than simply
matching exact text. But a regexp can be difficult to get right, especially for
complex patterns. If you haven't used them before, we recommend you learn about
them first &mdash; there are a lot of resources online, including websites that
let you test and experiment with your regexp before you add it to Alaveteli. If
you make a mistake in your regexp, either it won't match when you think it
should (redacting nothing), or it will match too much (redacting things that
should have been left). Be careful; if you're not sure, ask us for help first.

Redaction will attempt to apply to attachments as well as the text body of
message. For example, text may be redacted within PDFs or Word documents that are 
attached to a response to which censor rules apply.

<div class="attention-box warning">
  Binary files, that is, formats such as PDF, Word, or Excel can be difficult
  to redact. Some other formats, such as photos or JPEG files of scanned text,
  will not be redacted at all. If you are applying censor rules, you should
  always check they are working as expected on incoming attachments.
</div>

Redaction within binary files does not use the replacement text you have
specified, because it needs to approximate the length of the text that has been
redacted. Alaveteli automatically uses `[xxxxx]` as the replacement text, with
as many <code>x</code>s as needed.

## How to add a censor rule

To add a censor rule to a specific user, in the admin interface click on
**Users** and click of their name. Scroll down to _censor rules_, and click
**New censor rule**.

To add a censor rule to a specific request, click on the the **New censor rule**
button at the bottom of that request's admin page.

If you want to redact any text that matches a particular pattern, you can use a
<a href="{{ site.baseurl }}docs/glossary/#regexp" class="glossary__link">regular expression</a>
(regexp). You need to tell Alaveteli that the text is describing such a pattern
rather than the exact text you want to replace. Tick the checkbox labelled _Is
it a regular expression_ if you're using a regexp instead of a simple, exact
text match.

If you're not using a regular expression, the text match is case sensitive
&mdash; so `Reading` will _not_ redact the word `reading`. If you need case
insensitive matching, use a regular expression.

Enter the _replacement text_ that should be inserted in place of the redacted
text. We recommend something like `[REDACTED]` or <code>[personal&nbsp;details&nbsp;removed]</code>
to make it very clear that this is not the original text. Remember that the
replacement text will look the same as the running text into which it is 
inserted, which is why you should use square brackets, or something like them.

Provide a _comment_ explaining why this rule is needed. This will be seen only
by other administrators on the site.

Click the **create** button when you are ready to add the censor rule. 

## Seeing unredacted text

Censor rules are applied when the site pages (which includes the admin) are
displayed. If you want to see unredacted text, Alaveteli shows the original
text when you 
[edit the text of a message]({{ site.baseurl }}docs/running/admin_manual/#editing-an-outgoing-message).

## Redaction scope: requests, users, or more

The admin interface lets you easily add a censor rule to a specific request
or a particular user. 

But it's also technically possible to add censor rules with a different
scope by working directly within the source code. If you need to apply a
censor rule across a broader scope, for example, for _all_ requests on your
site, ask us for help. 

By way of an example, in the detailed example below, we add some code to apply
a unique redaction rule to every user (for hiding their own citizen ID number).

## A detailed example

In some countries, local requirements mean that requests need to contain
personal information such as the address or ID number of the person asking for
information. Usually requesters do not want this information to be displayed to
the general public.

Alaveteli has some ability to deal with this through the use of <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rules</a>.

The [theme](https://github.com/mysociety/derechoapreguntar-theme) we'll use as an example requires a National Identity Card Number and what's known as General Law in Nicaragua (Date of Birth, Domicile, Occupation and Marital Status).

![Sign up form with additional details]({{ site.baseurl }}assets/img/redaction-sign-up-form.png)

## Identity Card Number

We'll start off by looking at the National Identity Card Number (ID Number from here). Its a good example of something that is relatively easy to redact. It's unique for each user, and it has a specified format to match against.

To send the ID Number to the authority we'll override the [initial request template](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb) (code snippet shortened):

    <%= raw @outgoing_message.body.strip %>

    -------------------------------------------------------------------

    <%= _('Requestor details') %>
    <%= _('Identity Card Number') %>: <%= @user_identity_card_number %>

When a request is made the user's ID Number is now added to the footer of the outgoing email.

![Outgoing Message with ID Number]({{ site.baseurl }}assets/img/redaction-outgoing-message-with-id-number.png)

At this point we haven't added any <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rules</a>. When the authority replies it is unlikely that the responder will remove the quoted section of the email:

![ID Number in Quoted Section]({{ site.baseurl }}assets/img/redaction-id-number-in-quoted-section.png)

We could add a <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> for the individual request, but as every request will contain a user's ID Number its better to add some code to do do it automatically.

To illustrate this we'll patch the `User` model with a callback that creates a <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> when the user is created and updated.

    # THEME_ROOT/lib/model_patches.rb
    User.class_eval do
      after_save :update_censor_rules

      private

      def update_censor_rules
        censor_rules.where(:text => identity_card_number).first_or_create(
          :text => identity_card_number,
          :replacement => _('REDACTED'),
          :last_edit_editor => THEME_NAME,
          :last_edit_comment => _('Updated automatically after_save')
        )
      end
    end

You can see the new <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> in the admin interface:

![Automatically added Censor Rule]({{ site.baseurl }}assets/img/redaction-automatically-added-id-number-censor-rule.png)

Now the ID Number gets redacted:

![Automatically Redacted ID Number]({{ site.baseurl }}assets/img/redaction-id-number-redacted.png)

It also gets redacted if the public body use the ID Number in the main email body:

![ID Number redacted in main body]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-redacted.png)

A <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">censor rule</a> added to a user only gets applied to correspondence on requests created by that user. It does not get applied to annotations made by the user.

**Warning:** Redaction in this way requires the sensitive text to be in exactly the same format as the <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a>. If it differs even slightly, the redaction can fail. If the public body was to remove the hyphens from the number it would not be redacted:

![ID Number not redacted in main body]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-not-redacted.png)

**Warning:** Alaveteli also attempts to redact the text from any attachments. It can only do this if it can find the exact string, which is often not possible in binary formats such as PDF or Word.

Alaveteli can usually redact the sensitive information when converting a PDF or text based attachment to HTML:

![PDF to HTML Redaction]({{ site.baseurl }}assets/img/redaction-pdf-redaction-as-html.png)

This PDF does not contain the string in the raw binary so the redaction is _not_ applied when downloading the original PDF document:

![Download original PDF]({{ site.baseurl }}assets/img/redaction-pdf-redaction-download.png)

## General Law

The General Law information is much harder to automatically redact. It is not as structured, and the information is unlikely to be unique (e.g. Domicile: London).

We'll add the General Law information to the [initial request template](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb) in the same way as the ID Number:

    <%= _('Requestor details') %>:
    <%-# !!!IF YOU CHANGE THE FORMAT OF THE BLOCK BELOW, ADD A NEW CENSOR RULE!!! -%>
    ===================================================================
    # <%= _('Name') %>: <%= @user_name %>
    # <%= _('Identity Card Number') %>: <%= @user_identity_card_number %>
    <% @user_general_law_attributes.each do |key, value| %>
    # <%= _(key.humanize) %>: <%= value %>
    <% end %>
    ===================================================================

Note that the information is now contained in a specially formatted block of text.

![Outgoing message with general law]({{ site.baseurl }}assets/img/redaction-outgoing-message-with-general-law.png)

This allows a <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> to match the special formatting and remove anything contained within. This <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> is global, so it will act on matches in all requests.

    # THEME_ROOT/lib/censor_rules.rb
    # If not already created, make a CensorRule that hides personal information
    regexp = '={67}\s*\n(?:[^\n]*?#[^\n]*?: ?[^\n]*\n){3,10}[^\n]*={67}'

    unless CensorRule.find_by_text(regexp)
      Rails.logger.info("Creating new censor rule: /#{regexp}/")
      CensorRule.create!(:text => regexp,
                         :allow_global => true,
                         :replacement => _('REDACTED'),
                         :regexp => true,
                         :last_edit_editor => THEME_NAME,
                         :last_edit_comment => 'Added automatically')
    end

![Redacted address in fence]({{ site.baseurl }}assets/img/redaction-address-quoted-redacted.png)

**Warning:** Redacting unstructured information is a very fragile approach, as it relies on authorities always quoting the entire formatted block.

In this case the authority has revealed the user's Date of Birth and Domicile:

![Address outside formatted block]({{ site.baseurl }}assets/img/redaction-address-outside-fence.png)

Its really difficult to add a <a href="{{ page.baseurl }}/docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> to remove this type of information. One suggestion might be to remove all mentions of the user's Date of Birth, but you would have to account for [every type of date format](http://en.wikipedia.org/wiki/Calendar_date#Date_format). Likewise, you could redact all occurrences of the user's Domicile, but if they a question about their local area (very likely) the request would become unintelligible.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule.png)

The redaction has been applied but there is no way of knowing the context that the use of the sensitive word is used.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule-applied.png)
