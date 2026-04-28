---
layout: es/page
title: Buenas prácticas para el servidor de producción
---

# Buenas prácticas para el servidor de producción

<p class="lead">
  Estas notas sirven como lista de verificación de detalles a tener en cuenta al preparar
  el despliegue de su servidor de producción basado en Alaveteli.
</p>


## Opciones de hospedaje

Su servidor de producción debe ser seguro y fiable. Si aún no gestiona sus propios servidores,
considere una de las siguientes opciones:

* Servidor en la nube
* Servidor privado virtual

En algunos casos podemos hospedar nuevos proyectos basados en Alaveteli; si necesita ayuda,
consúltenos sobre el hospedaje.

## Trabajos de tipo cron

No olvide definir los trabajos de tipo cron tal como se expone en las
[instrucciones de instalación]({{ page.baseurl }}/docs/installing/manual_install/).

## Configuración del servidor web

Le recomendamos gestionar su sitio mediante
[Apache](https://httpd.apache.org) y
[Passenger](https://www.phusionpassenger.com) o [Nginx](http://wiki.nginx.org/Main) y [Thin](http://code.macournoyer.com/thin/).

Si utiliza Passenger, consulte las
[instrucciones de instalación]({{ page.baseurl }}/docs/installing/manual_install/)
sobre `PassengerMaxPoolSize`, con el que debería experimentar
para adaptarse a su memoria RAM disponible. Es muy poco probable que jamás
necesite un pool de mayor tamaño que el [predeterminado de
Passenger](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_passengermaxpoolsize_lt_integer_gt) de 6.

Le recomendamos poner en funcionamiento su servidor con un acelerador HTTP como
[Varnish](https://www.varnish-cache.org).
Alaveteli se proporciona con un
[VCL de varnish de muestra](https://github.com/mysociety/alaveteli/blob/master/config/varnish-alaveteli.vcl).

## Seguridad

_Debe_ modificar todos los [ajustes de configuración]({{ page.baseurl }}/docs/customising/config/)
relacionados con claves en el archivo `general.yml`, incluidos (¡pero existen otros!)
los siguientes:

* [`INCOMING_EMAIL_SECRET`]({{ page.baseurl }}/docs/customising/config/#incoming_email_secret)
* [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
* [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password)
* [`COOKIE_STORE_SESSION_SECRET`]({{ page.baseurl }}/docs/customising/config/#cookie_store_session_secret)
* [`RECAPTCHA_PUBLIC_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_public_key)
* [`RECAPTCHA_PRIVATE_KEY`]({{ page.baseurl }}/docs/customising/config/#recaptcha_private_key)

Debería considerar la posibilidad de gestionar el apartado de administración del sitio a través de HTTPS. 
Para ello puede reescribir normas que redirijan direcciones URL que empiecen por `/admin`.

## Configuración del correo electrónico

Consulte la [configuración para exim o postfix]({{ page.baseurl }}/docs/installing/email/) para
configurar su servidor de correo (MTA). Es posible utilizar otros MTA;
si utiliza uno diferente, la documentación debería proporcionarle suficiente información
para empezar. Si este tema le interesa, ¡añada documentación!

En un servidor real debería considerar también lo siguiente, para mejorar la capacidad de
entrega de su correo electrónico:

* Establezca [registros SPF](http://www.openspf.org/) para su dominio.
* Establezca <a
  href="http://wiki.asrg.sp.am/wiki/Feedback_loop_links_for_some_email_providers">bucles de retroalimentación</a> con los proveedores de correo principales
  (se recomienda Hotmail y Yahoo!)
* Especialmente si realiza el despliegue a partir de Amazon EC2, utilice un relevo SMTP externo
  para enviar correo saliente. Consulte el [AMI EC2 de Alaveteli]( {{ page.baseurl }}/docs/installing/ami/)
  para ver más sugerencias.

## Copia de seguridad

Muchos de los datos del sitio se almacenan en la base de datos de producción. La excepción
radica en los datos de tipo raw del correo entrante, que se almacenan en el sistema de archivos, tal como se
especifica en el ajuste
[`RAW_EMAILS_LOCATION`]({{ page.baseurl }}/docs/customising/config/#raw_emails_location)
del archivo `config/general.yml`.

Consulte la [documentación de
Postgres](http://www.postgresql.org/docs/8.4/static/backup.html) para
ver estrategias de copia de seguridad de bases de datos. El método más habitual consiste en utilizar `pg_dump`
para crear un volcado SQL de la base de datos y después realizar una copia de seguridad comprimida de dicho volcado.

Las copias de seguridad de los correos de tipo raw se llevarían a cabo mejor mediante una estrategia de incremento progresivo.
[Rsync](http://rsync.samba.org/) es una forma de hacerlo.

Otra estrategia de copia de seguridad para curarse en salud consiste en programar su MTA para que copie todo
el correo entrante y saliente en un buzón de correo que funcione como copia de seguridad. Un método para hacerlo mediante exim
consiste en incorporar lo siguiente en su configuración de exim:

    system_filter = ALAVETELI_HOME/config/exim.filter
    system_filter_user = ALAVETELI_USER

Y después crear un filtro en `ALAVETELI_HOME/config/exim.filter` similar a:

    if error_message then finish endif
    if $header_to: contains "midominio.org"
    then
    unseen deliver "copia@midominiodecopia.org"
    endif

    if $sender_address: contains "midominio.org"
    then
    unseen deliver "copia@midominiodecopia.org"
    endif

