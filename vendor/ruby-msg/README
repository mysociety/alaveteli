= Introduction

Generally, the goal of the project is to enable the conversion of
msg and pst files into standards based formats, without reliance on
outlook, or any platform dependencies. In fact its currently <em>pure
ruby</em>, so it should be easy to get running.

It is targeted at people who want to migrate their PIM data from outlook,
converting msg and pst files into rfc2822 emails, vCard contacts,
iCalendar appointments etc. However, it also aims to be a fairly complete
mapi message store manipulation library, providing a sane model for
(currently read-only) access to msg and pst files (message stores).

I am happy to accept patches, give commit bits etc.

Please let me know how it works for you, any feedback would be welcomed.

= Features

Broad features of the project:

* Can be used as a general mapi library, where conversion to and working
  on a standard format doesn't make sense.

* Supports conversion of messages to standard formats, like rfc2822
  emails, vCard, etc.

* Well commented, and easily extended.

* Basic RTF converter, for providing a readable body when only RTF
  exists (needs work)

* RTF decompression support included, as well as HTML extraction from
  RTF where appropriate (both in pure ruby, see <tt>lib/mapi/rtf.rb</tt>)

* Support for mapping property codes to symbolic names, with many
  included.

Features of the msg format message store:

* Most key .msg structures are understood, and the only the parsing
  code should require minor tweaks. Most of remaining work is in achieving
  high-fidelity conversion to standards formats (see [TODO]).

* Supports both types of property storage (large ones in +substg+
  files, and small ones in the +properties+ file.

* Complete support for named properties in different GUID namespaces.

* Initial support for handling embedded ole files, converting nested
  .msg files to message/rfc822 attachments, and serializing others
  as ole file attachments (allows you to view embedded excel for example).

Features of the pst format message store:

* Handles both Outlook 1997 & 2003 format pst files, both with no-
  and "compressible-" encryption.

* Understanding of the file format is still very superficial.

= Usage

At the command line, it is simple to convert individual msg or pst
files to .eml, or to convert a batch to an mbox format file. See mapitool
help for details:

  mapitool -si some_email.msg > some_email.eml
  mapitool -s *.msg > mbox

There is also a fairly complete and easy to use high level library
access:

  require 'mapi/msg'
  
  msg = Mapi::Msg.open filename
  
  # access to the 3 main data stores, if you want to poke with the msg
  # internals
  msg.recipients
  # => [#<Recipient:'\'Marley, Bob\' <bob.marley@gmail.com>'>]
  msg.attachments
  # => [#<Attachment filename='blah1.tif'>, #<Attachment filename='blah2.tif'>]
  msg.properties
  # => #<Properties ... normalized_subject='Testing' ... 
  # creation_time=#<DateTime: 2454042.45074714,0,2299161> ...>

To completely abstract away all msg peculiarities, convert the msg
to a mime object. The message as a whole, and some of its main parts
support conversion to mime objects.

  msg.attachments.first.to_mime
  # => #<Mime content_type='application/octet-stream'>
  mime = msg.to_mime
  puts mime.to_tree
  # =>
  - #<Mime content_type='multipart/mixed'>
    |- #<Mime content_type='multipart/alternative'>
    |  |- #<Mime content_type='text/plain'>
    |  \- #<Mime content_type='text/html'>
    |- #<Mime content_type='application/octet-stream'>
    \- #<Mime content_type='application/octet-stream'>
  
  # convert mime object to serialised form,
  # inclusive of attachments etc. (not ideal in memory, but its wip).
  puts mime.to_s

= Thanks

* The initial implementation of parsing msg files was based primarily
  on msgconvert.pl[http://www.matijs.net/software/msgconv/].

* The basis for the outlook 97 pst file was the source to +libpst+.

* The code for rtf decompression was implemented by inspecting the
  algorithm used in the +JTNEF+ project.

= Other

For more information, see

* TODO

* MsgDetails[http://code.google.com/p/ruby-msg/wiki/MsgDetails]

* PstDetails[http://code.google.com/p/ruby-msg/wiki/PstDetails]

* OleDetails[http://code.google.com/p/ruby-ole/wiki/OleDetails]

