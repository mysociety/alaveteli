---
layout: page
title: Redacting Sensitive Information
---

# Redacting Sensitive Information

In some countries, local requirements mean that requests need to contain personal information such as the address or ID number of the person asking for information. Usually requesters do not want this information to be displayed to the general public.

Alaveteli has some ability to deal with this through the use of <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rules</a>.

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

At this point we haven't added any <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rules</a>. When the authority replies it is unlikely that the responder will remove the quoted section of the email:

![ID Number in Quoted Section]({{ site.baseurl }}assets/img/redaction-id-number-in-quoted-section.png)

We could add a <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> for the individual request, but as every request will contain a user's ID Number its better to add some code to do do it automatically.

To illustrate this we'll patch the `User` model with a callback that creates a <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> when the user is created and updated.

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

You can see the new <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> in the admin interface:

![Automatically added Censor Rule]({{ site.baseurl }}assets/img/redaction-automatically-added-id-number-censor-rule.png)

Now the ID Number gets redacted:

![Automatically Redacted ID Number]({{ site.baseurl }}assets/img/redaction-id-number-redacted.png)

It also gets redacted if the public body use the ID Number in the main email body:

![ID Number redacted in main body]({{ site.baseurl }}assets/img/redaction-id-number-in-main-body-redacted.png)

A <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">censor rule</a> added to a user only gets applied to correspondence on requests created by that user. It does not get applied to annotations made by the user.

**Warning:** Redaction in this way requires the sensitive text to be in exactly the same format as the <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a>. If it differs even slightly, the redaction can fail. If the public body was to remove the hyphens from the number it would not be redacted:

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

This allows a <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> to match the special formatting and remove anything contained within. This <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> is global, so it will act on matches in all requests.

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

Its really difficult to add a <a href="{{site.baseurl}}docs/glossary/#censor-rule" class="glossary__link">Censor Rule</a> to remove this type of information. One suggestion might be to remove all mentions of the user's Date of Birth, but you would have to account for [every type of date format](http://en.wikipedia.org/wiki/Calendar_date#Date_format). Likewise, you could redact all occurrences of the user's Domicile, but if they a question about their local area (very likely) the request would become unintelligible.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule.png)

The redaction has been applied but there is no way of knowing the context that the use of the sensitive word is used.

![Censor Rule to redact a user's Domicile]({{ site.baseurl }}assets/img/redaction-domicile-censor-rule-applied.png)
