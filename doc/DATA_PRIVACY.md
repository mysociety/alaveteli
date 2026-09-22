# Data privacy in Alaveteli

Alaveteli handles a lot of personal information. To do this properly, it offers a variety of tools to find, redact and remove PII.

This document gives an overview of the concepts and tools available. It is useful for both developers, and site admins, specifically the Glossary part, which helps use a common vocabulary.

## Glossary of alaveteli concepts for developers

These words are used in Alaveteli with a specific meaning. As many of them are quite similar, we try to give some clearer definitions of what they entail so developers can use the appropriate concepts and methods in their code.

## General

### Admins

There are 2 types of admins in alaveteli, defined by the corresponding roles assigned to the user:

- `admin`: they can access the admin section of the site, that allows them to manage users, public bodies, and requests. They do not have access to content under embargo.
- `pro_admin`: like `admin`, but also have access to content under embargo.

## InfoRequest, messages and attachments

### Prominence

Visibility settings around who to display content to. Does not modify data.

4 values are used:
- `normal`: everyone can see the content (unless it is under embargo)
- `backpage`: like `normal` but search engines can't see it
- `requester_only`: the author of the `InfoRequest` can view the element, as well as site admins.
- `hidden`: only site admins can see the element, nobody else.

### Redact

Reduce visibility of specific parts of content via hard-coded Text Masks or admin-manageable CensorRules. Underlying data still remains. This is done at presentation time, but because the process can be quite heavy, the result is cached.
In other words, we keep both the unredacted and redacted versions of messages (there are exceptions, see below).

#### CensorRules vs Masks

- masks are blanket logic applied to everything for everyone. There are currently 2 masks in use to hide phone numbers and email addresses. As of v0.47.x, the default masks can be customised per site, and it is possible to bypass them in some circumstances.
- censor rules are more flexible, and allow admins to hide specific text, such as a person's name. They allow the use of regular expressions. A censor rule can apply to a single request, a user's content, all content related to a public body, or the entire site (global censor rules, best avoided).

### Edit

Destructively modify a specific attribute of a record.

### Erase

Destructively purge all non-metadata attributes from a record, ie. make them null or empty. This usually implies deleting files from storage.

### Delete/Destroy

Remove all traces of record entirely with no record left that it ever existed. This deletes the record from the database, and deletes the corresponding file in `ActiveStorage` if there was one.

It is best to avoid deleting records entirely, as this goes against the objectives of transparency for the site.

## FoiAttachment Specific

### Mask

Cache publicly viewable attributes with redactions applied.

### Lock

Prevent further modifications to masked copy (no reparsing from underlying raw email; no additional censor rules; existing censor rule edits/removals will not have an effect).

### Replace

Upload a copy of the attachment edited outside the app which takes precedence over the copy from the underlying raw email; replacing an attachment also locks it. This is typically used to remove PII from a scanned PDF where CensorRules cannot do their job.

## User Specific

### Close

Account can no longer be accessed / alerts no longer sent / very reduced public display of account; all account data remains intact.

### Anonymise

User's PII (name) is redacted for public display but we still hold the original data.
