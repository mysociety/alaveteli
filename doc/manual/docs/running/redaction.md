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

Alaveteli's redaction feature is useful because the site _automatically publishes_
correspondence between a requester and the authority. The most common need for
redaction is when one or more of the messages in that correspondence contain
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

In some countries, local requirements mean that Freedom of Information requests
need to contain personal details such as the address or ID number of the person
asking for information. Usually requesters do not want this information to be
displayed to the general public.

The following example shows how Alaveteli can help deal with this problem by
automatically redacting such information using
<a href="{{ site.baseurl }}docs/glossary/#censor-rule" class="glossary__link">censor
rules</a>.

### Nicaragua's "General Law" (providing personal details)

This example is based on the specific requirements of 
[Derecho a Preguntar](https://derechoapreguntar.org), the 
Alaveteli site running in Nicaragua. As usual, this site is running its own
<a href="{{ site.baseurl }}docs/glossary/#them" class="glossary__link">theme</a>.
The 
[theme is available on github](https://github.com/mysociety/derechoapreguntar-theme)
and is called `derechoapreguntar-theme`.

The law in Nicaragua demands that, when a citizen makes a request, they must
provide their national identity card number together with what's known as
"General Law". Specifically, this means they must provide:

* national identity card number ("ID number")
* date of birth
* domicile
* occupation
* marital status

In this example, we'll show how Alaveteli collects this information, and subsequently
redacts from the request pages that show the correspondence between the citizen and
the authorities.

<div class="attention-box helpful-hint">
  If you're not interested in how the theme collects and includes the personal
  details (which requires changes to the source code), you can jump straight to
  how the redaction is done:
  <a href="#redaction-example-1">ID&nbsp;number</a> and
  <a href="#redaction-example-2">personal&nbsp;details</a>.
</div>

### Capturing personal details at sign-up

The `derechoapreguntar-theme` overrides the default sign-up form by collecting
this information (because a user must sign up before their request will be
sent):

![Sign up form with additional details]({{ site.baseurl }}assets/img/redaction-sign-up-form.png)

### Identity card number

We'll start off by looking at the requester's ID number. It's a good example of
something that is relatively easy to redact because it:

* is unique for each user
* has a specified format to match against

To send the ID number to the authority we override the
[initial request template](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb)
(code snippet shortened):

    <%= raw @outgoing_message.body.strip %>

    -------------------------------------------------------------------

    <%= _('Requestor details') %>
    <%= _('Identity Card Number') %>: <%= @user_identity_card_number %>

When a request is made the user's ID number is automatically included in the
footer of the outgoing email:

![Outgoing Message with ID Number]({{ site.baseurl }}assets/img/redaction-outgoing-message-with-id-number.png)

When the authority replies (by email), it's unlikely that they will remove the
quoted section of the email, which contains the requester's ID number. This is
a typical circumstance for redaction &mdash; we want to prevent Alaveteli
displaying this information on the request page where the response (and other
messages) are published.

![ID Number in Quoted Section]({{ site.baseurl }}assets/img/redaction-id-number-in-quoted-section.png)

<a name="redaction-example-1"> </a>

One way to do this is to use the admin interface to 
[add a censor rule](#how-to-add-a-censor-rule)
to the individual request, like this:

* text: `123-456789-1234Z`
* replacement text: `REDACTED`
* scope: this request

...but this is an unsatisfactory solution, because that the administrators
would need to add such a rule to _every_ request as new requests are created.

Instead, because we know that every request will contain the user's ID number, we can
add some code to automatically create such a censor rule.

In this case, we patch the `User` model with a callback that creates a censor
rule as soon as the user is created (or updated):

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

Administrators can see the new censor rule in the admin interface:

![Automatically added Censor Rule]({{ site.baseurl }}assets/img/redaction-automatically-added-id-number-censor-rule.png)

So now the ID number gets redacted:

![Automatically Redacted ID Number]({{ site.baseurl }}assets/img/redaction-id-number-redacted.png)

Because censor rules apply to the whole of every message, the ID number also
gets redacted if the public body quote it anywhere in the main email body:

![ID Number redacted in main body]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-redacted.png)

A censor rule added to a user gets applied to all correspondence on requests
created by that user (that is, messages that are sent or received). But it does
*not* get applied to annotations made by the user.

<div class="attention-box warning">
  Redaction in this way requires the sensitive text to be in <em>exactly</em>
  the same format as the censor rule. If it differs even slightly, the
  redaction can fail.
</div>

For example, if the public body was to remove the hyphens from the ID number it
would not be redacted (because the censor rule _does_ include them):

![ID Number not redacted in main body]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-not-redacted.png)

Alaveteli also attempts to redact the text from any attachments. It can only do
this if it can find the exact string, which is not always possible in binary
formats such as PDF or Word.

<div class="attention-box warning">
  Redaction in some binary formats such as PDF or Word cannot be 100% reliable
  &mdash; you should always check incoming documents to be sure.
</div>

Alaveteli can usually redact the sensitive information when converting a PDF or
text based attachment to HTML:

![PDF to HTML Redaction]({{ site.baseurl }}assets/img/redaction-pdf-redaction-as-html.png)

In contrast, this PDF does not contain the string in the raw binary so the
redaction is _not_ applied when downloading the original PDF document:

![Download original PDF]({{ site.baseurl }}assets/img/redaction-pdf-redaction-download.png)

### Redacting the "General Law" (personal details)

The General Law information is much harder to automatically redact. It is not
as well-structured, and the information is unlikely to be unique to the user
(for example, Domicile: London).

We add the General Law information to the
[initial request template](https://github.com/mysociety/alaveteli/blob/master/app/views/outgoing_mailer/initial_request.text.erb)
in the same way as we did for the ID number:

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

<a name="redaction-example-2"> </a>

This allows a censor rule to match the special formatting and remove anything
contained within. This rule is global, so it will act on matches in all
requests.

Because this is matching a pattern of text, rather than an exact string, this
censor rule uses a
<a href="{{ site.baseurl }}docs/glossary/#regexp" class="glossary__link">regular expression</a>.

`={67}\s*\n(?:[^\n]*?#[^\n]*?: ?[^\n]*\n){3,10}[^\n]*={67}`

The regular expression broadly describes this pattern:

* two lines of sixty-seven equals signs (`=`), with this in between:
* between three and ten (inclusive) lines that:
   * start with a hash (`#`)
   * have something (without any newlines) followed by a colon (`:`)
   * followed by some data on the same line

The code, in the theme's `lib/censor_rules.rb`, looks like this:

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

<div class="attention-box warning"> 
  Redacting unstructured information is a very fragile approach, as it relies
  on authorities always quoting the entire formatted block.
</div>

For example, here the authority has revealed the user's date of birth and domicile:

![Address outside formatted block]({{ site.baseurl }}assets/img/redaction-address-outside-fence.png)

Its really difficult to add a censor rule to remove this type of information,
because it's so general. One approach might be to remove all mentions of the
user's date of birth, but you would have to account for
[every type of date format](http://en.wikipedia.org/wiki/Calendar_date#Date_format).
Likewise, you could redact all occurrences of the user's domicile, but if they
ask a question about their local area (which is very likely) the request would
become unintelligible.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule.png)

Here the redaction has been applied but there is no way of knowing the context
that the use of the sensitive word is used.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule-applied.png)
