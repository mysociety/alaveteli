---
layout: es/page
title: Para desarrolladores
---

# Información para desarrolladores

<p class="lead">
    Alaveteli es un proyecto de código abierto. Los desarrolladores a tiempo completo de mySociety junto con desarrolladores de todo el mundo contribuyen de forma activa en la base del código. Estos enlaces y notas le ayudarán si también desea ayudar.
</p>

* El software está escrito en **Ruby on Rails 3.x**. Soportamos postgresql como
  sistema gestor de base de datos. Se necesita un agente de transferencia de correo (MTA) 
  configurado, como exim, para analizar los correos recibidos. Disponemos de servidores de
  producción implementados en Debian (Squeeze y Wheezy) y en Ubuntu (12.04 LTS). Por motivos
  de rendimiento, recomendamos el uso de [Varnish](https://www.varnish-cache.org).

* Para ayudarle a entender qué hace el código, le recomendamos que lea esta [vista general
  de alto nivel]({{ page.baseurl }}/docs/developers/overview/), que incluye un esquema de
  los modelos y las relaciones entre ellos.

* Consulte la [documentación del API]({{ page.baseurl }}/docs/developers/api/) para averiguar
  cómo extraer e introducir datos en Alaveteli.

* Si necesita modificar o añadir cadenas de texto en la interfaz, consulte nuestras [guías
  de internacionalización](http://mysociety.github.io/internationalization.html),
  donde encontrará notas sobre nuestro uso de `gettext`.

* Utilizamos el [modelo de ramas de flujo
  de git](http://nvie.com/posts/a-successful-git-branching-model/)
  la última versión de desarrollo siempre se halla en la
  [rama develop](https://github.com/mysociety/alaveteli/). La última
  versión estable se encuentra siempre en la [rama
  maestra](https://github.com/mysociety/alaveteli/tree/master). Si tiene previsto colaborar en
  la elaboración del software, es posible que las [extensiones de flujo de
  git](https://github.com/nvie/gitflow) le resultes prácticas.

* La instalación del software es un tanto compleja, pero poco a poco se vuelve más sencilla.
  Si utiliza Debian o Ubuntu, debería poder poner en funcionamiento una versión en varias horas.
  Si dispone de su propio servidor, ejecute el
  [script de instalación]({{ page.baseurl }}/docs/installing/script/) o siga las
  indicaciones de
  [instalación manual]({{ page.baseurl }}/docs/installing/manual_install/).
  Alternativamente existe una [AMI EC2 de Alaveteli]({{ page.baseurl }}/docs/installing/ami/)
  que puede ayudarle a ponerlo en marcha rápidamente.
  [Póngase en contacto]({{ page.baseurl }}/community/) a través de la lista de correo del proyecto o mediante IRC
  para obtener ayuda.

* Un paso inicial estándar en la personalización de su implementación es la [escritura de un
  tema]({{ page.baseurl }}/docs/customising/themes/). **Si solo va a leer un apartado,
  ¡que sea este!**

* Al igual que numerosos sitios construidos con Ruby on Rails, el software no proporciona un rendimiento muy elevado (consulte
  [estas notas sobre los problemas de rendimiento](https://github.com/mysociety/alaveteli/wiki/Performance-issues) recopiladas a través del tiempo con
  WhatDoTheyKnow). El sitio funcionará sobre un servidor con 512 MB de memoria RAM, pero se recomienda un mínimo
  de 2 GB. La implementación detrás de [Varnish](https://www.varnish-cache.org) también resulta esencial. Consulte las
  [buenas prácticas en el servidor de producción]({{ page.baseurl }}/docs/running/server/) para obtener más información.

* Existe un conjunto de [proposiciones de mejora](https://github.com/mysociety/alaveteli/wiki/Proposals-for-enhancements),
  tales como un mayor número de funcionalidades centradas en el usuario, pero consulte también...

* ...las [publicaciones de github](https://github.com/mysociety/alaveteli/issues). Marcamos
  las publicaciones con la etiqueta **suitable for volunteers** (adecuada para voluntarios) cuando creemos que
  son especialmente adecuadas para quien busca una tarea relativamente pequeña a la que dedicarse.

* Intentamos garantizar que cada modificación confirmada cuente con su publicación correspondiente en el gestor.
  Así los registros de modificaciones se vuelven más sencillos, pues podemos reunir todos los cambios propios de 
  una actualización concreta respecto a un objetivo intermedio en el gestor de publicaciones, [como esta actualización
  0.4](https://github.com/mysociety/alaveteli/issues?milestone=7&state=closed).

* Si experimenta problemas de memoria, consulte [esta publicación del blog sobre estrategias utilizadas 
  anteriormente](https://www.mysociety.org/2009/09/17/whatdotheyknow-growing-pains-and-ruby-memory-leaks/).

* Si edita el código en un Mac, consulte estas [notas de instalación en MacOS X]({{ page.baseurl }}/docs/installing/macos/). <!-- [[OS X Quickstart]] -->

* Intentamos seguir unas buenas prácticas similares en todos nuestros proyectos: visite
  [mysociety.github.io](http://mysociety.github.io/) para obtener información sobre temas tales como nuestros
  [estándares de código](http://mysociety.github.io/coding-standards.html).
