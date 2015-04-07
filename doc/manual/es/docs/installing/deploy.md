---
layout: es/page
title: Despliegue
---

# Despliegue de Alaveteli

<p class="lead">
  A pesar de que puede instalar Alaveteli y simplemente modificar la plataforma cuando lo necesite,
  le recomendamos adoptar una forma de <strong>despliegue</strong> automático,
  especialmente en su
  <a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">servidor de producción</a>.
  Alaveteli proporciona un mecanismo de despliegue mediante el uso de Capistrano.
</p>

## ¿Por qué realizar un despliegue?

A pesar de que puede [instalar Alaveteli]({{ page.baseurl }}/docs/installing/) de diversas
maneras, una vez se halle en funcionamiento, tarde o temprano necesitará efectuar cambios
en el sitio. Un ejemplo común es la actualización del sitio cuando publicamos una nueva
versión.

El mecanismo de despliegue se encarga de situar todos los archivos necesarios en su lugar
correspondiente, de forma que cuando necesite publicar los cambios no corra el riesgo de
olvidar actualizar todos los archivos modificados ni de romper la configuración accidentalmente.
En su lugar, el despliegue hace todo esto de forma automática. También es más eficiente
debido a que resulta más rápido que llevar a cabo los cambios o la copia de archivos manualmente,
de forma que su sitio dejará de funcionar durante el menor tiempo posible.

Le **recomendamos encarecidamente** que utilice un mecanismo de despliegue para su
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">servidor de producción</a>
y, si utiliza uno, para su
<a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">servidor de pruebas</a> también.

## Capistrano

<a href="{{ page.baseurl }}/docs/glossary/#capistrano" class="glossary__link">Capistrano</a>
se incluye en Alaveteli como un sistema de despliegue estándar.

El principio básico de Capistrano consiste en ejecutar comandos `cap [do-something]`
en su equipo local y Capistrano se conecta con el servidor (mediante
`SSH`) y efectua en él la tarea correspondiente en su lugar.

### Configuración

Capistrano requiere la configuración de ciertos detalles en ambos extremos, es decir,
en el servidor donde desea que funcione Alaveteli y en su equipo local.

* *El servidor* es la máquina en la que se pondrá en funcionamiento la implementación de
  de Alaveteli que está desplegando.

* Su *equipo local* puede ser su portátil o un dispositivo similar, así como aquellos que
  pertenezcan a cualquier miembro de su equipo con permisos para realizar despliegues.

Para permitir que el mecanismo de despliegue de Capistrano funcione, necesitará configurar
el servidor de modo que la aplicación de Alaveteli reciba servicio desde un directorio llamado
`current`. Una vez hecho esto, desplegar una nueva versión consistirá esencialmente
en crear un directorio hermano con marca de tiempo respecto al directorio `current` y
cambiar el enlace simbólico `current` desde el antiguo directorio con marca de tiempo al nuevo.
Las opciones que deban persistir entre despliegues, como archivos de configuración, se mantendrán
en un directorio compartido `shared` ubicado en el mismo nivel y enlazado simbólicamente desde cada 
directorio de despliegue con marca de tiempo.

Estamos [trabajando para facilitar este proceso](https://github.com/mysociety/alaveteli/issues/1596),
pero de momento, este es el proceso manual que necesita seguir para configurar este mecanismo de
despliegue. Recuerde que solo debe hacer esto una vez para configurarlo y que después podrá
efectuar despliegues con gran facilidad (consulte el [uso a continuación](#uso)).

En primer lugar, en el servidor:

* [Instale Alaveteli]({{ page.baseurl }}/docs/installing/).
* Otorgue al usuario de Unix que ejecuta Alaveteli la capacidad de conectar a su servidor por SSH. Puede darle una contraseña o, preferentemente, definir claves SSH para que pueda acceder mediante SSH desde su equipo local al servidor:
   * Para proporcionarle una contraseña (si aún no dispone de una): `sudo passwd [UNIX-USER]`. Almacene esta contraseña de forma segura en su equipo local, por ejemplo, en un gestor de contraseñas.
   * Para definir claves SSH, siga las instrucciones de la [documentación de Capistrano](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/). No hay necesidad de configurar claves SSH para el repositorio de git, ya que es público.
* Asegúrse de que el usuario de Unix que pone en funcionamiento Alaveteli tiene permisos de escritura en el directorio raíz de su aplicación Alaveteli.
* Mueva la aplicación Alaveteli a un lugar temporal del servidor, como su directorio de inicio
  (temporalmente su sitio no será accesible hasta que el despliegue ubique los nuevos archivos
  en su lugar correspondiente).

A continuación, en su equipo local:

* Instale Capistrano:
   * Capistrano requiere Ruby 1.9 o superior y puede instalarse con RubyGems.
   * Ejecute `gem install capistrano`.
* Instale bundler si aún no lo ha hecho. Para ello ejecute: `gem install bundler`.
* Compruebe el [repositorio de Alaveteli](https://github.com/mysociety/alaveteli/) 
  (necesita algunos de los archivos disponibles localmente, incluso aunque no ejecute
  Alaveteli en esta máquina).
* Copie el archivo de ejemplo `config/deploy.yml.example` a `config/deploy.yml`.
* Ahora personalice las opciones de despliegue en dicho archivo: edite
  `config/deploy.yml` adecuadamente, por ejemplo, editando el nombre del
  servidor. Modifique también `deploy_to` para que coincida con la ruta actual de
  instalación de Alaveteli en el servidor. Si ha utilizado el script de instalación,
  será `/var/www/[HOST or alaveteli]/alaveteli`. Si utiliza el servidor de
  aplicaciones Thin en lugar de Passenger (así será si ha ejecutado el script
  de instalación), necesitará configurar `rails_app_server` como `thin` y 
  `rails_app_port` como el puerto en el que esté funcionando. Si ha utilizado el
  script, será 3300.


* Cambie con el comando `cd` al repositorio de Alaveteli de destino (en caso contrario, los comandos `cap` que ejecutará
  ahora no funcionarán).
* Aún en su equipo local, ejecute `cap -S stage=staging deploy:setup` para configurar Capistrano en el servidor.

Si obtiene un error `SSH::AuthenticationFailed` y no se le solicita la contraseña del usuario de despliegue, puede tratarse de [un error](http://stackoverflow.com/questions/21560297/capistrano-sshauthenticationfailed-not-prompting-for-password) en la versión del paquete gem net-ssh 2.8.0.
Pruebe a instalar la versión 2.7.0 en su lugar:

    gem uninstall net-ssh

    gem install net-ssh -v 2.7.0

De vuelta en el servidor:

* Copie los siguientes archivos de configuración desde la copia temporal de Alaveteli efectuada
  al principio (tal vez en su directorio de inicio) al directorio `shared` que
  Capistrano acaba de crear en el servidor:
   * `general.yml`
   * `database.yml`
   * `rails_env.rb`
   * `newrelic.yml`
   * `aliases` &larr; si está utilizando Exim como MTA
* Si utiliza Exim como MTA, edite el archivo de alias `aliases` que acaba de copiar
  para que la ruta hacia Alaveteli incluya el elemento `current`. Si es, por ejemplo,
  `/var/www/alaveteli/alaveteli/script/mailin`, ahora deberá ser
  `/var/www/alaveteli/alaveteli/current/script/mailin`.
* Copie los siguientes directorios desde su copia temporal de Alaveteli al directorio
  `shared` creado por Capistrano en el servidor:
   * `cache/`
   * `files/`
   * `lib/acts_as_xapian/xapiandbs` (copie este directorio directamente en `shared` de forma que se convierta en `shared/xapiandbs`)
   * `log/`

Ahora, de vuelta en su equipo local:

* Asegúrese de que aún se halla en el repositorio de Alaveteli (si no es así, vuelva a él con el comando `cd`).
* Ejecute `cap -S stage=staging  deploy:update_code` para obtener la salida del código en el servidor.
* Cree un directorio de despliegue en el servidor ejecutando *uno* de estos comandos:
   * `cap deploy` si está desplegando un <a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">servidor de pruebas</a>.
   * `cap -S stage=production deploy` para <a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">producción</a>.

De vuelta en el servidor:

* Actualice la configuración del servidor web (con Apache o Nginx) para añadir el elemento `current`
  a la ruta desde la que está sirviendo a Alaveteli. Si ha efectuado la instalación utilizando el
  script, esta acción consistirá en sustituir `/var/www/alaveteli/alaveteli/` por
  `/var/www/alaveteli/alaveteli/current` en `/etc/nginx/sites-available/default`.
* Edite el archivo crontab del servidor para que las rutas que apuntan a los procesos cron también incluyan el 
  elemento `current`. Si ha utilizado el script de instalación, el archivo crontab se hallará en
  `etc/cron.d/alaveteli`.
* Acutalice la configuración del MTA para que incluya el elemento `current` en las rutas que utiliza.
  Si ha utilizado el script de instalación, el MTA será Postfix y deberá editar 
  `/etc/postfix/master.cf` para sustituir `argv=/var/www/alaveteli/alaveteli/script/mailin` por
  `argv=/var/www/alaveteli/alaveteli/current/script/mailin`.
  Si utiliza Exim como MTA, edite `etc/exim4/conf.d/04_alaveteli_options`
  y actualice la variable `ALAVETELI_HOME` con la nueva ruta de Alaveteli. 
  Reinicie el MTA después de efectuar los cambios.

* También necesitará actualizar la ruta hacia Alaveteli en sus [scripts init]({{ page.baseurl }}/docs/installing/manual_install/#demonios-y-procesos-cron).
  Debería tener un script para ejecutar los tracks de alerta
  (`/etc/init.d/foi-alert-tracks`) y, posiblemente, scripts para purgar
  la caché de Varnish (`/etc/init.d/foi-purge-varnish`) y reiniciar el
  servidor de aplicaciones (`/etc/init.d/alaveteli`).

¡Buf, hemos terminado!

Ahora puede eliminar la copia temporal de Alaveteli (tal vez ubicada en su directorio de inicio).

### Uso

Antes de lanzar ningún comando de Capistrano, cambie con el comando `cd` al destino del repositorio de
Alaveteli en su equipo local (porque buscará en él la configuración que ha definido).

Asegúrese de que dispone de un archivo `config/deploy.yml` con los ajustes correctos para su
sitio. Si hay otras personas en su equipo que necesiten efectuar un despliegue, deberá 
compartirlo con ellas también. Puede ser una buena idea mantener la última versión en un
[Gist](http://gist.github.com/).

* Para efectuar un despliegue en un servidor de pruebas, ejecute sencillamente `cap deploy`.
* Para efectuar un despliegue en producción, ejecute `cap -S stage=production deploy`.

Es posible que, después del despliegue, vea que el antiguo directorio de despliegue sigue ahí,
es decir, el que era `current` antes de sustituirlo por el nuevo. Por defecto el mecanismo
de despliegue guarda los cinco últimos despliegues. Ejecute
`cap deploy:cleanup` para eliminar versiones antiguas.

Para obtener instrucciones de uso adicionales, consulte el [sitio web
de Capistrano](http://capistranorb.com/).

### Esto no es lo que esperaba

Si un despliegue falla o si descubre después de efectuarlo que en realidad la última versión
no estaba lista, ¡que no surja el pánico! Ejecute `cap deploy:rollback`
y devolverá `current` al despliegue anterior.

