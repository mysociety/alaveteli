# Welcome to Alaveteli!

[![CI](https://img.shields.io/travis/mysociety/alaveteli?label=CI)](http://travis.org/mysociety/alaveteli)
[![RuboCop](https://img.shields.io/github/workflow/status/mysociety/alaveteli/RuboCop?label=RuboCop)](https://github.com/mysociety/alaveteli/actions?query=workflow%3ARuboCop)
[![Coverage Status](https://img.shields.io/coveralls/github/mysociety/alaveteli/develop)](https://coveralls.io/r/mysociety/alaveteli)
[![Code Climate](https://img.shields.io/codeclimate/maintainability-percentage/mysociety/alaveteli)](https://codeclimate.com/github/mysociety/alaveteli)
[![Installability: Gold](http://img.shields.io/badge/installability-gold-ffd700.svg "Installability: Gold")](http://mysociety.github.io/installation-standards.html)

This is an open source project to create a standard, internationalised
platform for making Freedom of Information (FOI) requests in different
countries around the world. The software started off life as
[WhatDoTheyKnow](https://www.whatdotheyknow.com), a website produced by
[mySociety](http://mysociety.org) for making FOI requests in the UK.

We hope that by joining forces between teams across the world, we can
all work together on producing the best possible software, and help
move towards a world where governments approach transparency as the
norm, rather than the exception.

Please join our mailing list at
https://groups.google.com/group/alaveteli-dev and introduce yourself, or
drop a line to hello@alaveteli.org to let us know that you're using Alaveteli.

There's lots of useful information and documentation (including a blog)
on [the project website](http://alaveteli.org). There's background
information and notes on [our
wiki](https://github.com/mysociety/alaveteli/wiki/Home/), and upgrade
notes in the [`doc/`
folder](https://github.com/mysociety/alaveteli/tree/master/doc/CHANGES.md)

## Installing

We've been working hard to make Alaveteli easy to install and re-use anywhere. Please
see [the project website](http://alaveteli.org) for instructions on installing Alaveteli.

## Compatibility

Every Alaveteli commit is tested by Travis on the [following Ruby platforms](https://github.com/mysociety/alaveteli/blob/master/.travis.yml#L7)

* ruby-2.3.0
* ruby-2.4.0
* ruby-2.5.0
* ruby-2.6.0

If you use a ruby version management tool (such as RVM or .rbenv) and want to use the default development version used by the alaveteli team (currently 2.3.8), you can create a `.ruby-version` symlink with a target of `.ruby-version.example` to switch to that automatically in the project directory.

## How to contribute

If you find what looks like a bug:

* Check the [GitHub issue tracker](http://github.com/mysociety/alaveteli/issues/)
  to see if anyone else has reported issue.
* If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

* Fork the project on GitHub.
* Make a topic branch from the develop branch.
* Make your changes with tests.
* Commit the changes without making changes to any files that aren't related to your enhancement or fix.
* Send a pull request against the develop branch.

Looking for the latest stable release? It's on the
[master branch](https://github.com/mysociety/alaveteli/tree/master).

We have some more notes for developers [on the project site](http://alaveteli.org/docs/developers/).

## Examples

* [WhatDoTheyKnow](https://www.whatdotheyknow.com)
* [KiMitTud](http://kimittud.atlatszo.hu)
* [Informace Pro Všechny](http://www.infoprovsechny.cz)
* [fyi.org.nz](https://fyi.org.nz)

See more at [alaveteli.org](http://alaveteli.org/deployments/).

## Acknowledgements

Thanks to [Browserstack](https://www.browserstack.com/) who let us use their
web-based cross-browser testing tools for this project.

This product includes GeoLite data created by MaxMind, available from
<a href="http://www.maxmind.com">http://www.maxmind.com</a>.
