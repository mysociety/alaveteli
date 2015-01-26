---
layout: page
title: Categories & tags
---

#  Categories and tags for authorities

<p class="lead">
  
  Use tags to arrange
  <a href="{{ site.baseurl }}docs/glossary/#authority"
  class="glossary__link">authorities</a> into categories, or to associate
  related authorities with each other. This helps your users find the right
  authority for the 
  <a href="{{ site.baseurl }}docs/glossary/#request" class="glossary__link">request</a>
  (or <a href="{{ site.baseurl }}docs/glossary/#response" class="glossary__link">response</a>)
  they are interested in.
</p>

## Categories & category headings

Alaveteli lets you organise your authorities into *categories*. Categories can
themselves belong to *category headings*. For example, some of the categories
and headings on
<a href="{{ site.baseurl }}docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>'s
<a href="https://www.whatdotheyknow.com/body/list/all">View  authorities</a> page look like this:

>  * **Media and culture**
>    * Media
>    * Museums and galleries
>  * **Military and security services**
>    * Armed Forces
>    * Military colleges
>    * Security services
>  * **Emergency services**
>    * Police forces
>    * Fire & rescue services


In this example, "Emergency services" is a heading which contains the categories
"Police forces" and "Fire & rescue services".

Tags are simply searchable words that you can add to an authority. Nominate one
or more tags for each category: any authority which has such a tag is
automatically assigned to the category. For example, if the tag `police` is
associated with the category "Police forces", any authority which has the tag
`police` will appear in that category.

Make sure you choose good category headings and names, because they help your find the specific authorities they are looking for. 

<div class="attention-box info">
  Try to use simple but descriptive words for tags. Tags cannot contain spaces
  (use an underscore if you need to, <code>like_this</code>).
  Remember that tags will be seen and used by the public (for example, in the
  <a href="{{ site.baseurl }}docs/glossary/#advanced-search" class="glossary__link">advanced search</a>).
</div>

### Adding a new category

In the admin interface, click on **Categories**. It's a good idea to create
category headings first (but don't worry if you don't &mdash; you can change
them later).

Click on **New category heading**, enter a name (for example, "Emergency
services") and click **Create**.

To create a category, click on **New category**. As well as providing a title
and a description, you must enter a category tag. Any authority with this tag
will be assigned to this category.

Select the checkbox next to the category heading under which you want this
category to be listed. It's common for a category to be under just one heading.
But sometimes it makes sense for a category to go under more than one, so you
can select multiple checkboxes if you need to.

Click **Save** to create the category.

### Editing or deleting a category

Click on **Categories** then find the category in the list (if the category is
under a heading, you may need to click on the heading's chevron to expand the
list to show it). Click the name of the category to select it. You can edit it
and click **Save**.

If you want to destroy a category,  go to edit it but instead of saving it,
click on the **Destroy** button at the  bottom of the page. This does not
delete any authorities in that category &mdash; they simply no longer belong to
it.

## Special tags

Some tags are special. Alaveteli behaves differently when an authority has one
of these tags. 

<table class="table">
  <tr>
    <th>
      Tag
    </th>
    <th>
      Effect
    </th>
  </tr>
  <tr>
    <td>
      <code>site_administration</code>
    </td>
    <td>
      This is a test/dummy authority. It is not displayed to the public on your
      main site, and it is not included when you 
      <a href="{{ site.baseurl }}docs/running/admin_manual/#creating-changing-and-uploading-public-authority-data">export authorities in CSV format</a>.
    </td>
  </tr>
  <tr>
    <td>
      <code>defunct</code>
    </td>
    <td>
      This authority no longer operates: new requests cannot be sent to an
      authority with this tag.
    </td>
  </tr>
  <tr>
    <td>
      <code>not_apply</code>
    </td>
    <td>
      <a href="{{ site.baseurl }}docs/glossary/#foi" class="glossary__link">Freedom of Information</a>
      law does not apply to this authority: new requests cannot be sent to an
      authority with this tag.
    </td>
  </tr>
  <tr>
    <td>
      <code>eir_only</code>
    </td>
    <td>
      <em>Custom example:</em> (see below)<br>
      On our UK installation of Alaveteli,
      <a href="{{ site.baseurl }}docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>,
      this tag indicates that the authority is subject to an alternative law
      (Environment Information Regulations, rather than the Freedom of
      Information), which means Alaveteli must change the wording of these
      requests appropriately.
    </td>
  </tr>
  <tr>
    <td>
      <code>school</code>
    </td>
    <td>
      <em>Custom example:</em> (see below)<br>
      <a href="{{ site.baseurl }}docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
      applies a different definition of "late" if an authority has the <code>school</code> tag.
    </td>
  </tr>
</table>

## Custom tags and custom behaviour

You can add any tag you want &mdash; they don't have to be associated with
categories.
  
If you are a developer, and you want to add special behaviour to your site
based on your own tags, you need to add custom code, which should probably go
in your own
<a href="{{ site.baseurl}}docs/glossary/#theme" class="glossary__link">theme</a>.
For example, in the UK, schools are granted special concession in the law to allow for
requests that are made out of term-time. Alaveteli handles this by using the
[`SPECIAL_REPLY_VERY_LATE_AFTER_DAYS`]({{ site.baseurl }}docs/customising/config/#special_reply_very_late_after_days)
config value if the authority has the `school` tag.
See
[`is_school?`](https://github.com/mysociety/alaveteli/blob/f0bbeb4abf4bf07e5cfb46668f39bbff72ed7210/app/models/public_body.rb#L391)
and
[`date_very_overdue_after`](https://github.com/mysociety/alaveteli/blob/81b778622ed47e24a2dea59c0529d1f928c68a58/app/models/info_request.rb#L752)
for the source code.

## Searching with tags

Alaveteli's
<a href="{{ site.baseurl }}docs/glossary/#advanced-search" class="glossary__link">advanced search</a>
feature (which is available to all your users) can search for specific tags. So
if you add useful tags and publicise them, your users can use them to find
related authorities. For example, see the <a
href="https://www.whatdotheyknow.com/advancedsearch">advanced search on
WhatDoTheyKnow</a> to see this at work.

You can add reference numbers or specific values to tags using a colon. On
<a href="{{ site.baseurl }}docs/glossary/#wdtk" class="glossary__link">WhatDoTheyKnow</a>
we tag all authorities that are charities with the tag `charity:123456` (where
123456 is the authority's registered charity number).




