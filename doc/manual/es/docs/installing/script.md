---
layout: es/page
title: Script de instalación
---

# Script de instalación

<p class="lead">
  Si prefiere utilizar su propio servidor, hemos elaborado un script de instalación, que efectúa la mayor parte del trabajo en su lugar.
</p>

Existen [otras formas de instalar Alaveteli]({{ page.baseurl }}/docs/installing/).

## Instalación con el script de instalación

Si dispone de una instalación limpia de Debian Wheezy de 64 bits o Ubuntu Precise, puede
utilizar un script de instalación de nuestro repositorio commonlib para configurar una implementación
funcional de Alaveteli. Esta opción no es válida para producción (funciona, por ejemplo, en modo
de desarrollo), pero deberá llevar a cabo una instalación funcional del sitio, que pueda
enviar y recibir correo.

**Advertencia: utilice este script solamente en un servidor recién instalado, pues efectuará
cambios significativos en la configuración de su servidor, incluidas modificaciones en la configuración
de Nginx, la creación de una cuenta de usuario, la generación de una base de datos y la instalación
de nuevos paquetes.**

Para descargar el script, ejecute el siguiente comando:

    curl -O https://raw.githubusercontent.com/mysociety/commonlib/master/bin/install-site.sh

Si ejecuta este script con `sh install-site.sh`, verá su mensaje de uso:

    Usage: ./install-site.sh [--default] <SITE-NAME> <UNIX-USER> [HOST]
    HOST is only optional if you are running this on an EC2 instance.
    --default means to install as the default site for this server,
    rather than a virtualhost for HOST.

En este caso `<SITE-NAME>` debería ser `alaveteli`. `<UNIX-USER>` es el nombre del
usuario de Unix que será propietario del código y lo podrá en funcionamiento 
(este usuario será creado por el script).

El parámetro `HOST` es un nombre de host para el servidor que podrá ser utilizado
externamente. El script creará un host virtual para este nombre, a menos que
haya especificado la opción `--default`. Este parámetro es opcional si se halla en
una implementación de EC2, en cuyo caso se utilizará el nombre de host de dicha implementación.

Por ejemplo, si desea utilizar un nuevo usuario llamado `alaveteli` y el nombre de host
`alaveteli.127.0.0.1.xip.io`, creando un host virtual solamente para este nombre de host,
puede descargar y ejecutar el script con:

    sudo sh install-site.sh alaveteli alaveteli alaveteli.127.0.0.1.xip.io

([xip.io](http://xip.io/) es un dominio útil para desarrollo)

O, si desea configurarlo como el sitio por defecto en una implementación de EC2, puede
descargar el script, convertirlo en ejecutable y después invocarlo con:

    sudo ./install-site.sh --default alaveteli alaveteli

Si tiene problemas o consultas, pregunte en el [grupo de Google de 
	Alaveteli](https://groups.google.com/forum/#!forum/alaveteli-dev) o [informe de un
    problema](https://github.com/mysociety/alaveteli/issues?state=open).

## Qué hace el script de instalación

Una vez ha finalizado el script, debería disponer de una copia funcional del sitio web,
accesible a través del nombre de host suministrado al script. Por tanto, para este ejemplo, podrá acceder al sitio desde un navegador en `http://alaveteli.10.10.10.30.xip.io`. El sitio funciona utilizando el servidor de aplicaciones Thin y el servidor web Nginx. Por defecto Alaveteli se instalará en `/var/www/[HOST]` dentro del servidor.

El servidor también estará configurado para aceptar respuestas a correos de solicitud de información (simpre que el registro MX del dominio apunte al servidor). La gestión del correo entrante se configura utilizando Postfix como MTA.

##¿Qué hacer a continuación?

Consulte los [siguientes pasos]({{ page.baseurl }}/docs/installing/next_steps/).



