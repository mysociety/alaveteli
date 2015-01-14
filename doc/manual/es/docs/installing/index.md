---
layout: es/page
title: Instalación
---

# Instalación de Alaveteli

<p class="lead">
  Existen diversas formas de instalar Alaveteli.
  Hemos elaborado una Amazon Machine Image (AMI) para que pueda desplegar rápidamente
  en EC2 de Amazon (práctico si solamente desea evaluarlo, por ejemplo).
  Si prefiere utilizar su propio servidor, existe un script de instalación que 
  efectúa la mayor parte del trabajo, o también puede seguir las instrucciones de
  instalación manual.
</p>

## Antes de empezar

Importante: necesita decidir si está instalando Alaveteli para su
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">desarrollo</a> o su
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">producción</a>.

Un servidor de **desarrollo** en aquel donde modificará, personalizará y tal vez
experimentará mientras lo pone en funcionamiento. Siempre debería hacer esto en primer
lugar. En este entorno podrá ver mensajes de depuración y no necesitará preocuparse
demasiado sobre la eficiencia y el rendimiento del sitio (pues en realidad no 
recibe gran cantidad de tráfico).

Un servidor de **producción** es diferente: le interesa que el servidor de producción funcione
de la forma más eficiente posible, así que opciones tales como la memoria caché se activan
y otras como los mensajes de depuración se desactivan. Es importante que pueda implementar cambios
rápida y eficientemente en un servidor de producción, por lo que recomendamos que considere también
 el uso de un [mecanismo de despliegue]({{ page.baseurl }}/docs/installing/deploy/).

Lo ideal sería que también tuviera un
<a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">servidor de pruebas</a>,
utilizado exclusivamente para probar el código nuevo en un entorno idéntico a su servidor 
de producción antes de publicarlo.

Si tiene dudas, probablemente deba utilizar un servidor de desarrollo. Póngalo en marcha, juegue
con él, personalícelo y, más adelante, puede instalarlo como un servidor de producción.

## Despliegue

Si está utilizando un servidor de producción, le **recomendamos encarecidamente** el
uso del [mecanismo de despliegue]({{ page.baseurl }}/docs/installing/deploy/) Capistrano
incluido en Alaveteli. Configúrelo y nunca tendrá que editar archivos en estos servidores,
pues Capistrano se encargará de ello en su lugar.

## Instalación del código principal

* [Instalación en un entorno de desarrollo virtual de Vagrant]({{ page.baseurl }}/docs/installing/vagrant/): una buena elección para desarrollo y para poder jugar con el sitio.
* [Instalación con EC2 de Amazon]({{ page.baseurl }}/docs/installing/ami/) utilizando nuesta AMI.
* [Instalación utilizando el script]({{ page.baseurl }}/docs/installing/script/) que efectúa la instalación completa en su propio servidor.
* [Instalación manual]({{ page.baseurl }}/docs/installing/manual_install/): instrucciones paso a paso.

Si está configurando un servidor de desarrollo en MacOS X, también disponemos de
[instrucciones de instalación para MacOS]({{ page.baseurl }}/docs/installing/macos/).

## Otros datos sobre la instalación

Alaveteli necesita poder enviar y recibir correo. Si efectúa la instalación manual, necesitará [configurar su
MTA (servidor de correo) en consecuencia]({{ page.baseurl }}/docs/installing/email/). Los otros métodos de instalación lo harán automáticamente.

* [Instalación del MTA]({{ page.baseurl }}/docs/installing/email/).
