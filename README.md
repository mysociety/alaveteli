# Alaveteli за България
<small>*Вижте по долу за оригиналното съдържание на READMЕ файла.*</small>
## Резюме & Увод
Това е интеграция на вече изградения код от [mySociety](http://mysociety.org), първоначално използван за [WhatDoTheyKnow](http://www.whatdotheyknow.com).

Сайт позволяващ изпращането на [Заявление за достъп до информация](http://www.aip-bg.org/howto/%D0%97%D0%B0%D1%8F%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5/) към набор от институции. Може да се каже, че това е по-скоро **искане за информация** понеже институциите са задължени да отговорят на всички валидни **заявления** в срок от 2 седмици.

Общо казано питате нещо и държавата трябва да отговори. Има и [много малко изключения](http://www.aip-bg.org/howto/%D0%92%D1%8A%D0%BF%D1%80%D0%BE%D1%81%D0%B8/#QH9), които са свързани главно с тайни, лична информация и повторения. Нямат право да ви питат защо искате информацията.

Исканията не са ограничени само до държавни институции. Всяка [организация финансирана от държавата/бюджета](http://www.aip-bg.org/howto/%D0%92%D1%8A%D0%BF%D1%80%D0%BE%D1%81%D0%B8/#QH9)

## Есенция
Сайт, в който се запращат заявления за достъп до информацията, изцяло през сайта. Написаното от потребителя е публикувано в сайта, отговора от институцията също. Лични данни като адрес и име са заличени.

Така информацията е публично достъпна за търсене, а институциите не се налага да отговарят повторно на зададени вече въпроси.

### Пример

1. Петър иска да знае колко струва (каква сума от държавния бюджет е дадена) за изготването на http://www.government.bg . Петър и иска детайли за това какво вкючва сайтът като функции за дадени пари.
1. Петър влиза в сайтът на Alaveteli България и намира "Министерски съвет"
1. Натиска "Попитай" и във стандартно текстово поле описва исканата от него информация. В допълнителни полета пише лична информация като име и адрес, която няма да бъде достъпна публично.
1. Информацията е запратена, като автоматично е добавен абзац поясняваш, че това е Заявление за достъп до информация
1. След 1 седмица и половина Министерския съвет изпраща отговор, който е автоматично публикуван на сайта Alaveteli България. 
1. Петър е уведомен за отговора и може да го прегледа в сайта, както и да маркира направеното си искане като успешно или неуспешно.
1. Ако Петър бива "разкарван" от институцията чрез многобройни въпроси, други потребители от сайта Alaveteli могат да се включат с предложения по темата как Петър да форумира искането си ясно и настойчиво, да подчертаят дадени задължения или грешки в отговора от институцията.

-----------
# Welcome to Alaveteli!

[![Build Status](https://secure.travis-ci.org/mysociety/alaveteli.png)](http://travis-ci.org/mysociety/alaveteli) [![Dependency Status](https://gemnasium.com/mysociety/alaveteli.png)](https://gemnasium.com/mysociety/alaveteli) [![Coverage Status](https://coveralls.io/repos/mysociety/alaveteli/badge.png?branch=rails-3-develop)](https://coveralls.io/r/mysociety/alaveteli) [![Code Climate](https://codeclimate.com/github/mysociety/alaveteli.png)](https://codeclimate.com/github/mysociety/alaveteli)

This is an open source project to create a standard, internationalised
platform for making Freedom of Information (FOI) requests in different
countries around the world. The software started off life as
[WhatDoTheyKnow](http://www.whatdotheyknow.com), a website produced by
[mySociety](http://mysociety.org) for making FOI requests in the UK.

We hope that by joining forces between teams across the world, we can
all work together on producing the best possible software, and help
move towards a world where governments approach transparency as the
norm, rather than the exception.

Please join our mailing list at
https://groups.google.com/group/alaveteli-dev and introduce yourself, or
drop a line to hello@alaveteli.org to let us know that you're using Alaveteli.

Some documentation can be found in the
[`doc/` folder](https://github.com/mysociety/alaveteli/tree/master/doc).
There's background information and more documentation on
[our wiki](https://github.com/mysociety/alaveteli/wiki/Home/), and lots
of useful information (including a blog) on
[the project website](http://alaveteli.org)

## How to contribute

If you find what looks like a bug:

* Check the [GitHub issue tracker](http://github.com/mysociety/alaveteli/issues/)
  to see if anyone else has reported issue.
* If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

* Fork the project on GitHub.
* Make a topic branch from the rails-3-develop branch.
* Make your changes with tests.
* Commit the changes without making changes to any files that aren't related to your enhancement or fix.
* Send a pull request against the rails-3-develop branch.

Looking for the latest stable release? It's on the
[master branch](https://github.com/mysociety/alaveteli/tree/master).

