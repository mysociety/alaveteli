---
layout: page
title: Translation
---

# Translating Alaveteli

<p class="lead">
	We've designed Alaveteli to be used in many different 
	jurisdictions all around the world. If it doesn't already
	support the language you need, you can help by translating
	it. This page explains how.
</p>

## Alaveteli's translations

The software translations are implemented using GNU gettext, and the resource
files are managed in Transifex.

The Transifex project is at
[https://www.transifex.net/projects/p/alaveteli](https://www.transifex.net/proje
cts/p/alaveteli) -- you'll probably want an account there (ask on the mailing
list). It has a fairly easy-to-use interface for contributing translations.

There are three roles in the translation process, and each one is described
below: **translator**, **developer**, and **release manager**. You probably only
need to know about the one that applies to you.

## Translation process: translator's view

**If you're just working on translating Alaveteli into a language you know, then
this section is for you.**

When a developer adds a new feature to the user interface in Alaveteli, they
use some code to mark sentences or words ("strings") that they think will need
to be translated.

When the Alaveteli release manager is planning a release, they will upload a
template containing all the strings to be translated (called a POT) to
Transifex. This causes your own translations in Transifex to be updated with
the latest strings.

When you visit Transifex, it will prompt you to fill out values for all new
strings, and all strings that have been modified. In the case where a string
has only been slightly modified, such as with punctuation ("Hello" has become
"Hello!"), Transifex will suggest a suitable translation for you (look for the
"suggestions" tab under the source string).

In order for this feature to work properly, the release manager has to download
your translations, run a program that inserts the suggestions, and then upload
them again. Therefore, when a release candidate is announced, make sure you
have uploaded any outstanding translations, or you will lose them.

When a release candidate has been annouced, there is a **translation freeze**:
during this period, developers must not add any new strings to the software, so
you can be confident that you're translating everything that will be in the
final release.

The release manager will also give you a **translation deadline**. After this
date, you can continue to contribute new translations, but they won't make it
into the release.

### General notes on translation in Transifex

Some strings will have comments attached to them from the Alaveteli
application developers about the context in which the text appears in the
application — these comments will appear under the 'Details' tab for the text
in Transifex.

Some strings will have **placeholders** in them to indicate that Alaveteli
will insert some text of its own into them when they're displayed. They
will be surrounded by double curly brackets, and look like this:

<code>
    some text with &#123;&#123;placeholder&#125;&#125; in it
</code>
    
For these strings, don't translate the placeholder. It needs to stay exactly
the same for the text to be inserted properly:

<code>
    ein Text mit &#123;&#123;placeholder&#125;&#125; in ihm
</code>

Similarly, some strings may contain small bits of HTML — these will have 
code in angle brackets (it might really be indicating that the text is a link, 
or that it needs special formatting). For example: 

<code>
    please &lt;a href=\"&#123;&#123;url&#125;&#125;\"&gt;send it to us&lt;/a&gt;
</code>

Again, don't edit the bits between the angle brackets — preserve them in your
translation, and just edit the text around them. So the example might become:

<code>
    bitte &lt;a href=\"&#123;&#123;url&#125;&#125;\"&gt;schicken Sie es uns&lt;/a&gt;
</code>

Some strings are in the form of two pieces of text separated by a vertical
bar (`|`) character, e.g. `IncomingMessage|Subject`. These represent attribute
names, so `IncomingMessage|Subject` is the subject attribute of an incoming
message on the site. Do not prioritise these types of text when translating --
they do not appear on the site anywhere at the moment, and when they do, they
will only be used in the admin interface. If you do translate them, only
translate the text that comes *after* the `|`.

## Translation process: developers' view

**If you're writing new code for Alaveteli, then you're a developer, and you
need to understand how to make any text you add easy for translators to work
with.**

Please read our [internationalisation
guide](http://mysociety.github.io/internationalization.html) for our advice on
using strings that will need translation. This applies across all mySociety
projects, not just Alaveteli.

The release manager will enforce a translation freeze just before a new release
is cut. During such time, you must not introduce new strings to the code if
your work is due for inclusion in this release. This is necessary to allow
translators time to complete and check their translations against all the known
strings.
