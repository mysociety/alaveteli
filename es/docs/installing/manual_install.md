---
layout: es/page
title: Instalación manual
---


# Instalación manual

<p class="lead">
    Las siguientes instrucciones describen el proceso paso a paso para la
    instalación de Alaveteli. <em>No es obligatorio hacerlo de este modo</em>,
	normalmente resulta más sencillo utilizar el
    <a href="{{ page.baseurl }}/docs/installing/script/">script de instalación</a>
    o el
    <a href="{{ page.baseurl }}/docs/installing/ami/">AMI EC2 de Amazon</a>.
</p>

Existen [otras maneras de instalar Alaveteli]({{ page.baseurl }}/docs/installing/).

<div class="attention-box">
  <ul>
    <li>Los comandos incluidos en este manual requieren permisos de usuario root.</li>
    <li>Los comandos deben ejecutarse en el terminal o mediante SSH.</li>
  </ul>
</div>

## Configuración el sistema operativo

### Sistema operativo objetivo

Estas instrucciones corresponden a una versión de 64 bits de Debian 6 (Wheezy), Debian 7 (Squeeze)
o Ubuntu 12.04 LTS (Precise). Debian es la plataforma de implementación con mejor soporte. También
tenemos instrucciones para la [instalación en MacOS]({{ page.baseurl }}/docs/installing/macos/).

### Defina la localización

**Debian Wheezy o Squeeze**

Siga el [manual de Debian](https://wiki.debian.org/Locale#Standard) para configurar la localización del sistema operativo.

Genere las localizaciones que desea tener disponibles. Cuando la pantalla interactiva solicite que escoja una localización predeterminada, elija «None», pues la sesión SSH proporcionará la localización requerida.

    dpkg-reconfigure locales

Inicie una nueva sesión SSH para utilizar su localización de SSH.

**Ubuntu Precise**

Desactive la localización predeterminada, ya que la sesión SSH debería proporcionar la localización requerida.

    update-locale LC_ALL=

Inicie una nueva sesión SSH para utilizar su localización de SSH.

### Actualice el sistema operativo

Actualice el sistema operativo con los últimos paquetes:

    apt-get update -y
    apt-get upgrade -y

`sudo` no está instalado de forma predeterminada en Debian. Instálelo junto con `git` (la herramienta de control de versiones que utilizaremos para obtener una copia del código de Alaveteli).

    apt-get install -y sudo git-core

### Prepare la instalación de dependencias del sistema utilizando paquetes del sistema operativo

Estos son paquetes de los que el software depende: software de terceros utilizado para 
analizar documentos, hospedar el sitio, etc. En el siguiente paso también hay paquetes que contienen
encabezados necesarios para compilar parte de las dependencias gem.

#### Utilice otros repositorios para obtener paquetes más recientes

Añada los siguientes repositorios a `/etc/apt/sources.list`:

**Debian Squeeze**

    cat > /etc/apt/sources.list.d/debian-extra.list <<EOF
    # Mirror de Debian que incluye contrib y non-free:
    deb http://the.earth.li/debian/ squeeze main contrib non-free
    deb-src http://the.earth.li/debian/ squeeze main contrib non-free

    # Actualizaciones de seguridad:
    deb http://security.debian.org/ squeeze/updates main non-free
    deb-src http://security.debian.org/ squeeze/updates main non-free

    # Backports de Debian
    deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
    deb-src http://backports.debian.org/debian-backports squeeze-backports main contrib non-free

    # Wheezy
    deb http://ftp.uk.debian.org/debian wheezy main contrib non-free
    EOF

El repositorio squeeze-backports proporciona una versión más reciente de RubyGems y el repositorio de Wheezy proporciona bundler. Debería configurar la opción package-pinning para reducir la prioridad del repositorio de Wheezy con el objetivo de evitar que se le soliciten otros paquetes.

    cat >> /etc/apt/preferences <<EOF

    Package: bundler
    Pin: release n=wheezy
    Pin-Priority: 990

    Package: *
    Pin: release n=wheezy
    Pin-Priority: 50
    EOF

**Debian Wheezy**

    cat > /etc/apt/sources.list.d/debian-extra.list <<EOF
    # Mirror de Debian que incluye contrib y non-free:
    deb http://the.earth.li/debian/ wheezy main contrib non-free
    deb-src http://the.earth.li/debian/ wheezy main contrib non-free

    # Actualizaciones de seguridad:
    deb http://security.debian.org/ wheezy/updates main non-free
    deb-src http://security.debian.org/ wheezy/updates main non-free
    EOF

**Ubuntu Precise**

    cat > /etc/apt/sources.list.d/ubuntu-extra.list <<EOF
    deb http://de.archive.ubuntu.com/ubuntu/ precise multiverse
    deb-src http://de.archive.ubuntu.com/ubuntu/ precise multiverse
    deb http://de.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    deb-src http://de.archive.ubuntu.com/ubuntu/ precise-updates multiverse
    deb http://de.archive.ubuntu.com/ubuntu/ trusty universe
    deb-src http://de.archive.ubuntu.com/ubuntu/ trusty universe
    EOF

Aquí se utiliza el repositorio trusty para obtener una versión más reciente de bundler. Debería configurar la opción package-pinning para reducir la prioridad del repositorio de Wheezy con el objetivo de evitar que se le soliciten otros paquetes.

    cat >> /etc/apt/preferences <<EOF

    Package: ruby-bundler
    Pin: release n=trusty
    Pin-Priority: 990

    Package: *
    Pin: release n=trusty
    Pin-Priority: 50
    EOF


#### Paquetes personalizados por mySociety

Si utiliza Debian o Ubuntu, debería añadir el archivo de Debian de mySociety a sus fuentes
apt. Los paquetes de mySociety actualmente solo se construyen para Debian de 64 bits.

**Debian Squeeze, Wheezy o Ubuntu Precise**

    cat > /etc/apt/sources.list.d/mysociety-debian.list <<EOF
    deb http://debian.mysociety.org squeeze main
    EOF

El repositorio anterior le permite instalar `wkhtmltopdf-static` y `pdftk` (para Squeeze) utilizando `apt`.

Añada la clave GPG del
[repositorio de paquetes de Debian de mySociety](http://debian.mysociety.org/):

    wget -O - https://debian.mysociety.org/debian.mysociety.org.gpg.key | apt-key add -

**Solamente para Ubuntu Precise**

    cat > /etc/apt/sources.list.d/mysociety-launchpad.list <<EOF
    deb http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
    deb-src http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
    EOF

El repositorio anterior le permite instalar una versión reciente de `pdftk` utilizando `apt`.

Añada la clave GPG del
[repositorio de paquetes de Ubuntu para Alaveteli de mySociety](https://launchpad.net/~mysociety/+archive/ubuntu/alaveteli).

    apt-get install -y python-software-properties
    add-apt-repository -y ppa:mysociety/alaveteli

**Debian Wheezy o Ubuntu Precise**

También debería configurar la opción package-pinning para reducir la prioridad del
repositorio de Debian de mySociety. Solo nos interesa obtener wkhtmltopdf-static
de mySociety.

    cat >> /etc/apt/preferences <<EOF

    Package: *
    Pin: origin debian.mysociety.org
    Pin-Priority: 50
    EOF

**Debian Squeeze**

No se requiere la adición de ningún paquete especial.

#### Otras plataformas
Si utiliza otra plataforma basada en Linux, puede instalar, opcionalmente,
estas dependencias de forma manual, como se describe a continuación:

1. Si desea que los usuarios puedan obtener archivos PDF agradables como parte del 
archivo comprimido descargable del historial de su solicitud, instale
[wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/downloads/list). 
Recomendamos descargar la última versión compilada estáticamente del sitio web
del proyecto, ya que permite su ejecución sin cabeceras (es decir, sin utilizar
una interfaz gráfica) en Linux. Si instala `wkhtmltopdf`, necesitará editar una opción
en el archivo de configuración para añadir el puntero correspondiente (encontrará más información a continuación).
Si no instala esta herramienta, todo funcionará correctamente, pero los usuarios 
obtendrán versiones poco atractivas en texto sin formato de sus solicitudes al descargarlas.

2. La versión 1.44 de `pdftk` contiene un error que causa un bucle infinito en ciertas
condiciones radicales. Este problema se soluciona en el paquete estándar 1.44.7, disponible en Wheezy (Debian) y Raring (Ubuntu).

Si no puede obtener una versión oficial con esta reparación para su sistema operativo, puede
tener la esperanza de que no se produzca el problema (bloquea un proceso de Rails de forma infinita
y es necesario matarlo), aplicar un parche por su cuenta o utilizar los paquetes de
[Debian](http://debian.mysociety.org/dists/squeeze/main/binary-amd64/)
o
[Ubuntu](https://launchpad.net/~mysociety/+archive/ubuntu/alaveteli/+packages)
compilados por mySociety.

#### Actualice las fuentes

Actualice las fuentes tras añadir los repositorios adicionales.

    apt-get -y update

### Cree un usuario de Alaveteli

Cree un nuevo usuario de Linux para ejecutar la aplicación de Alaveteli:

    adduser --quiet --disabled-password --gecos "Alaveteli" alaveteli

## Obtenga Alaveteli

Cree el directorio de destino y clone el código fuente de Alaveteli en este directorio:

    mkdir -p /var/www/alaveteli
    chown alaveteli:alaveteli /var/www
    chown alaveteli:alaveteli /var/www/alaveteli
    cd /home/alaveteli
    sudo -u alaveteli git clone --recursive \
      --branch master \
      https://github.com/mysociety/alaveteli.git /var/www/alaveteli

Estos comandos clonan la rama maestra, que siempre contiene la última versión estable. Si desea probar el código más reciente (con posibles errores), puede cambiar a la rama `rails-3-develop`.

    pushd /var/www/alaveteli
    sudo -u alaveteli git checkout rails-3-develop
    sudo -u alaveteli git submodule update
    popd

La opción `--recursive` instala las librerías comunes de mySociety requeridas para el funcionamiento de Alaveteli.

## Instale las dependencias

Instale los paquetes correspondientes para su sistema:

    # Debian Wheezy
    apt-get -y install $(cat /var/www/alaveteli/config/packages.debian-wheezy)

    # Debian Squeeze
    apt-get -y install $(cat /var/www/alaveteli/config/packages.debian-squeeze)

    # Ubuntu Precise
    apt-get -y install $(cat /var/www/alaveteli/config/packages.ubuntu-precise)

Algunos de los archivos también tienen un número de versión listado en config/packages, compruebe
que tiene instaladas las versiones correctas. Algunas también ofrecen una selección de paquetes
listados con «`|`».

<div class="attention-box">

<strong>Nota:</strong> Para instalar las dependencias de Ruby de Alaveteli, necesita instalar bundler. En
Debian y Ubuntu se proporciona como paquete (instalado como parte del proceso de
instalación de paquetes anterior). Para otros sistemas operativos, puede instalarlo también como gem:

   <pre><code> gem install bundler --no-rdoc --no-ri</code></pre>

</div>


## Configure la base de datos

Se ha trabajado para intentar conseguir que el código funcione con otras bases de datos
(por ejemplo, SQLite), pero la base de datos soportada actualmente es PostgreSQL
(«postgres»).

Cree un usuario `foi` desde la línea de comando, de este modo:

    sudo -u postgres createuser -s -P foi

_Nota:_ Dejar la contraseña en blanco puede causar gran confusión si no está familiarizado con
PostgreSQL.

Cree una plantilla para nuestras bases de datos de Alaveteli:

    sudo -u postgres createdb -T template0 -E UTF-8 template_utf8
    echo "update pg_database set datistemplate=true where datname='template_utf8';" > /tmp/update-template.sql
    sudo -u postgres psql -f /tmp/update-template.sql
    rm /tmp/update-template.sql

A continuación, cree las bases de datos:

    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_production
    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_test
    sudo -u postgres createdb -T template_utf8 -O foi alaveteli_development

## Configure el correo electrónico

Necesitará definir un servidor de correo (MTA) para enviar y recibir
correo electrónico.

La configuración completa de un MTA va más allá del alcance de este documento. Consulte el manual de [configuración de los servidores Exim4 y Postfix]({{ page.baseurl }}/docs/installing/email/).

En el modo de desarrollo el correo es gestionado por [`mailcatcher`](http://mailcatcher.me/) por defecto para
que pueda visualizar los correos en un navegador. Inicie mailcatcher ejecutando `bundle exec mailcatcher` en el directorio de aplicaciones.

## Configure Alaveteli

Alaveteli tiene tres archivos principales de configuración:

  - `config/database.yml`: configuración de la comunicación entre Alaveteli y la base de datos.
  - `config/general.yml`: ajustes generales de la aplicación de Alaveteli.
  - `config/newrelic.yml`: configuración del servicio de monitorización de [NewRelic](http://newrelic.com).

Copie los archivos de configuración y actualice sus permisos:

    cp /var/www/alaveteli/config/database.yml-example /var/www/alaveteli/config/database.yml
    cp /var/www/alaveteli/config/general.yml-example /var/www/alaveteli/config/general.yml
    cp /var/www/alaveteli/config/newrelic.yml-example /var/www/alaveteli/config/newrelic.yml
    chown alaveteli:alaveteli /var/www/alaveteli/config/{database,general,newrelic}.yml
    chmod 640 /var/www/alaveteli/config/{database,general,newrelic}.yml

### database.yml

Ahora necesitará definir el archivo de configuración de la base de datos para que la aplicación
pueda conectar con la base de datos de Postgres.

Edite cada sección para apuntar a la base de datos local de PostgreSQL correspondiente.

Sección `development` de ejemplo de `config/database.yml`:

    development:
      adapter: postgresql
      template: template_utf8
      database: alaveteli_development
      username: foi
      password: secure-password-here
      host: localhost
      port: 5432

Asegúrese de que el usuario especificado en `database.yml` existe y tiene permisos completos
en las bases de datos.

Como el usuario requiere la capacidad de desactivar restricciones durante la ejecución de las pruebas, necesita permisos de superusuario. Si no desea que el usuario de su base de datos tenga permisos de superusuario, puede añadir esta línea a la sección `test` de `database.yml` (como puede ver en `config/database.yml-example`):

    constraint_disabling: false

### general.yml

Tenemos un [manual completo de configuración de Alaveteli]({{ page.baseurl }}/docs/customising/config/), que abarca todas las opciones incluidas en `config/general.yml`.

_Nota:_ Si está configurando Alaveteli para su funcionamiento en producción, asigne a la variable [`STAGING_SITE`]({{ page.baseurl }}/docs/customising/config/#staging_site) el valor `0` en `/var/www/alaveteli/config/general.yml`.

    STAGING_SITE: 0

Los ajustes predeterminados para los ejemplos de páginas frontales están diseñados para trabajar con
los datos de muestra incluidos en Alaveteli; una vez disponga de datos reales, deberá editar estos ajustes.

El tema por defecto es el [tema «Alaveteli»](https://github.com/mysociety/alavetelitheme). Al ejecutar `rails-post-deploy` (consulte la información siguiente), este tema se instala automáticamente.

### newrelic.yml

Este archivo contiene información de configuración para el sistema de gestión
de mantenimiento de New Relic. La gestión es desactivada por defecto mediante la opción
`agent_enabled: false`. Consulte las instrucciones de [análisis de rendimiento remoto](https://github.com/newrelic/rpm) de New Relic para activarlo
para análisis locales y remotos.

## Implementación

Debería ejecutar el script `rails-post-deploy` después de cada actualización de software:

    sudo -u alaveteli RAILS_ENV=production \
      /var/www/alaveteli/script/rails-post-deploy

Este comando instala las dependencias de Ruby, instala/actualiza temas, efectúa migraciones
de bases de datos, actualiza directorios compartidos y lleva a cabo otras tareas necesarias
después de una actualización de software, como la precompilación de atributos estáticos
para una instalación en producción.

La primera ejecución de este script puede requerir *mucho* tiempo, ya que debe
compilar las dependencias nativas de `xapian-full`.

Cree el índice para el motor de búsqueda (Xapian):

    sudo -u alaveteli RAILS_ENV=production \
      /var/www/alaveteli/script/rebuild-xapian-index

Si esta acción falla, el sitio debería funcionar en gran parte, pero se trata de un componente principal,
así que debería hacer lo posible para que funcione.

<div class="attention-box">
  Hemos definido <code>RAILS_ENV=production</code>. Utilice
  <code>RAILS_ENV=development</code> si está instalando Alaveteli para
  efectuar cambios en el código.
</div>

## Configure el servidor de aplicaciones

Alaveteli puede funcionar con numerosos servidores de aplicaciones. mySociety recomienda
el uso de [Phusion Passenger](https://www.phusionpassenger.com) (alias
mod_rails) o [thin](http://code.macournoyer.com/thin).

### Con Phusion Passenger

Passenger es el servidor de aplicaciones recomendado, ya que se ha probado a conciencia
en entornos de producción. Está implementado como un módulo de Apache, así que no puede
ejecutarse de forma independiente.

    apt-get install -y libapache2-mod-passenger

Consulte más adelante en el manual cómo configurar el servidor web de Apache con Passenger.

### Con Thin

Thin es un servidor de aplicaciones más ligero que puede ejecutarse con independencia del
servidor web. Thin se instalará en el paquete de la aplicación y se utilizará para gestionar
Alaveteli por defecto.

Ejecute lo siguiente para poner el servidor en marcha:

    cd /var/www/alaveteli
    bundle exec thin \
      --environment=production \
      --user=alaveteli \
      --group=alaveteli \
      start

El servidor escucha todas las interfaces de forma predeterminada. Puede restringirlo a la interfaz de
localhost añadiendo `--address=127.0.0.1`.

El servidor debería haber indicado la dirección URL de acceso desde el navegador,
para que pueda observar el sitio en acción.

Puede demonizar el proceso iniciándolo con la opción `--daemonize`.

Más adelante en este manual crearemos un demonio SysVinit para gestionar la aplicación, así que puede detener todos los procesos thin que haya empezado a crear.

## Demonios y procesos cron

Los scripts crontab e init utilizan el formato de archivo `ugly`, que es un extraño formato
de plantillas utilizado por mySociety.

El formato `ugly` utiliza una sustitución simple de variables. Una variable tiene este
`!!(*= $aspecto *)!!`.

### Genere el archivo crontab

`config/crontab-example` contiene los procesos cron que se ejecutan en
Alaveteli. Escriba de nuevo el archivo de ejemplo para sustituir las variables
y después guárdelo en la carpeta `/etc/cron.d/` del servidor.

**Variables de la plantilla:**

* `vhost_dir`: ruta completa del directorio destino de Alaveteli.
  Por ejemplo, si la salida se halla en `/var/www/alaveteli`, indique `/var/www`.
* `vcspath`: nombre del directorio que contiene el código de Alaveteli.
  Por ejemplo, `alaveteli`.
* `user`: usuario con el que se ejecuta el software.
* `site`: cadena de texto que identifica su implementación de Alaveteli.
* `mailto`: dirección de correo electrónico o cuenta local a la que se enviará la salida cron. La configuración de una dirección de correo depende de que su MTA haya sido configurado para el envío remoto.

Existe una tarea rake que le ayudará a escribir de nuevo este archivo para que le resulte útil. 
Este ejemplo envía la salida cron al usuario local `alaveteli`. Modifique las variables para adaptarlas a su instalación.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      MAILTO=alaveteli \
      CRONTAB=/var/www/alaveteli/config/crontab-example > /etc/cron.d/alaveteli
    popd

    chown root:alaveteli /etc/cron.d/alaveteli
    chmod 754 /etc/cron.d/alaveteli

### Genere el demonio de la aplicación

Genere un demonio basado en el servidor de aplicaciones instalado. Este demonio permitirá utilizar
el comando `service` nativo para detener, iniciar y reiniciar la aplicación.

#### Passenger

**Variables de la plantilla:**

* `vhost_dir`: ruta completa del directorio destino de Alaveteli.
  Por ejemplo, si la salida se halla en `/var/www/alaveteli`, indique `/var/www`.
* `vcspath`: nombre del directorio que contiene el código de Alaveteli.
  Por ejemplo, `alaveteli`.
* `site`: cadena de texto que identifica su implementación de Alaveteli.
* `user`: usuario con el que se ejecuta el software.

Existe una tarea rake que le ayudará a escribir de nuevo este archivo para que le resulte útil. 
Este ejemplo envía la salida cron al usuario local `alaveteli`. Modifique las variables para adaptarlas a su instalación.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/sysvinit-passenger.example > /etc/init.d/alaveteli
    popd

    chown root:alaveteli /etc/init.d/alaveteli
    chmod 754 /etc/init.d/alaveteli

Inicie la aplicación:

    service alaveteli start

#### Thin

**Variables de la plantilla:**

* `vhost_dir`: ruta completa del directorio destino de Alaveteli.
  Por ejemplo, si la salida se halla en `/var/www/alaveteli`, indique `/var/www`.
* `vcspath`: nombre del directorio que contiene el código de Alaveteli.
  Por ejemplo, `alaveteli`.
* `site`: cadena de texto que identifica su implementación de Alaveteli.
* `user`: usuario con el que se ejecuta el software.

Existe una tarea rake que le ayudará a escribir de nuevo este archivo para que le resulte útil. 
Este ejemplo envía la salida cron al usuario local `alaveteli`. Modifique las variables para adaptarlas a su instalación.

    pushd /var/www/alaveteli
    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/sysvinit-thin.example > /etc/init.d/alaveteli
    popd

    chown root:alaveteli /etc/init.d/alaveteli
    chmod 754 /etc/init.d/alaveteli

Inicie la aplicación:

    service alaveteli start

### Genere el demonio de alerta

Uno de los procesos cron hace referencia a un script en `/etc/init.d/alaveteli-alert-tracks`. Se trata
de un script init, que puede generarse a partir de la plantilla
`config/alert-tracks-debian.example`. Este script envía correos a usuarios suscritos a actualizaciones del sitio, denominados [`tracks`]({{ page.baseurl }}/docs/installing/email/#correo-de-tracks), cuando existe algo nuevo que concuerda con sus intererses.

**Variables de la plantilla:**

* `daemon_name`: nombre del demonio, establecido por la tarea rake.
* `vhost_dir`: ruta completa del directorio destino de Alaveteli.
  Por ejemplo, si la salida se halla en `/var/www/alaveteli`, indique `/var/www`.
* `vcspath`: nombre del directorio que contiene el código de Alaveteli.
  Por ejemplo, `alaveteli`.
* `site`: cadena de texto que identifica su implementación de Alaveteli.
* `user`: usuario con el que se ejecuta el software.

Existe una tarea rake que le ayudará a escribir de nuevo este archivo para que le resulte útil. 
Este ejemplo envía la salida cron al usuario local `alaveteli`. Modifique las variables para adaptarlas a su instalación.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/alert-tracks-debian.example > /etc/init.d/alaveteli-alert-tracks
    popd

    chown root:alaveteli /etc/init.d/alaveteli-alert-tracks
    chmod 754 /etc/init.d/alaveteli-alert-tracks

Inicie el demonio de tracks de alerta:

    service alaveteli-alert-tracks start

### Genere el demonio de purga de Varnish

`config/purge-varnish-debian.example` es un script init similar, que es opcional
e innecesario si elige no ejecutar su sitio con Varnish (más información a continuación). Notifica a Varnish sobre páginas en caché que necesitan ser purgadas de la caché de Varnish. No funcionará si Varnish no está instalado.

**Variables de la plantilla:**

* `daemon_name`: nombre del demonio, establecido por la tarea rake.
* `vhost_dir`: ruta completa del directorio destino de Alaveteli.
  Por ejemplo, si la salida se halla en `/var/www/alaveteli`, indique `/var/www`.
* `vcspath`: nombre del directorio que contiene el código de Alaveteli.
  Por ejemplo, `alaveteli`.
* `site`: cadena de texto que identifica su implementación de Alaveteli.
* `user`: usuario con el que se ejecuta el software.

Existe una tarea rake que le ayudará a escribir de nuevo este archivo para que le resulte útil. 
Este ejemplo envía la salida cron al usuario local `alaveteli`. Modifique las variables para adaptarlas a su instalación.

    pushd /var/www/alaveteli
    bundle exec rake RAILS_ENV=production config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/var/www \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/var/www/alaveteli/config/purge-varnish-debian.example > /etc/init.d/alaveteli-purge-varnish
    popd

    chown root:alaveteli /etc/init.d/alaveteli-purge-varnish
    chmod 754 /etc/init.d/alaveteli-purge-varnish

Inicie el demonio de tracks de alerta:

    service alaveteli-purge-varnish start


## Configure el servidor web

En casi todos los escenarios recomendamos ejecutar la aplicación en Rails de Alaveteli
detrás de un servidor web. Así, el servidor web puede ofrecer contenido estático sin recorrer
la pila de Rails, proporcionando un mejor rendimiento.

Recomendamos dos combinaciones principales de aplicación y servidor web:

- Apache y Passenger
- Nginx y Thin

Hay formas de ejecutar Passenger con Nginx y, por supuesto, Thin con Apache, pero
no se tienen en cuenta en este manual. Si desea hacer algo que no está documentado aquí,
contacte con [alaveteli-dev](https://groups.google.com/forum/#!forum/alaveteli-dev) y
estaremos encantados de ayudarle en la puesta en marcha.

Si ha seguido este manual, ya debería tener instalado un servidor de aplicaciones, así que
ahora deberá eleigr el servidor web adecuado para configurarlo.

### Apache (con Passenger)

Instale Apache con el contenedor Suexec:

    apt-get install -y apache2
    apt-get install -y apache2-suexec

Active los módulos requeridos:

    a2enmod actions
    a2enmod expires
    a2enmod headers
    a2enmod passenger
    a2enmod proxy
    a2enmod proxy_http
    a2enmod rewrite
    a2enmod suexec

Cree un directorio para la configuración opcional de Alaveteli:

    mkdir -p /etc/apache2/vhost.d/alaveteli

Copie el ejemplo de archivo de configuración de VirtualHost. Necesitará modificar todas
las ocurrencias de `www.example.com` por su URL.

    cp /var/www/alaveteli/config/httpd.conf-example \
      /etc/apache2/sites-available/alaveteli

Desactive el sitio predeterminado y active el VirtualHost `alaveteli`:
  
    a2dissite default
    a2ensite alaveteli

Compruebe la configuración y solucione posibles problemas:

    apachectl configtest

Reinicie Apache para cargar una nueva configuración de Alaveteli:

    service apache2 graceful

Se recomienda encarecidamente que su sitio funcione con SSL. (Asigne a `FORCE_SSL` el
valor «true» en `config/general.yml`). Para ello necesitará un certificado SSL para su dominio.

Active el módulo SSL de Apache:

    a2enmod ssl

Copie la configuración SSL, cambiando de nuevo `www.example.com` por su dominio,
y active el VirtualHost:

    cp /var/www/alaveteli/config/httpd-ssl.conf.example \
      /etc/apache2/sites-available/alaveteli_https
    a2ensite alaveteli_https

Fuerce las solicitudes HTTPS desde el VirtualHost HTTP:

    cp /var/www/alaveteli/config/httpd-force-ssl.conf.example \
      /etc/apache2/vhost.d/alaveteli/force-ssl.conf

Si está probando Alaveteli o configurando un sitio interno de pruebas, genere
certificados SSL autofirmados. **No utilice certificados autofirmados para un
servidor de producción**. Sustituya `www.example.com` por su nombre de dominio.

    openssl genrsa -out /etc/ssl/private/www.example.com.key 2048
    chmod 640 /etc/ssl/private/www.example.com.key

    openssl req -new -x509 \
      -key /etc/ssl/private/www.example.com.key \
      -out /etc/ssl/certs/www.example.com.cert \
      -days 3650 \
      -subj /CN=www.example.com
    chmod 640 /etc/ssl/certs/www.example.com.cert

Compruebe la configuración y solucione posibles problemas:

    apachectl configtest

Reinicie Apache para cargar una nueva configuración de Alaveteli. También se reiniciará
Passenger (el servidor de la aplicación).

    service apache2 graceful

### Nginx (con Thin)

Instale Nginx:

    apt-get install -y nginx

#### Funcionamiento con SSL

Se recomienda encarecidamente que el sitio funcione con SSL. (Asigne a `FORCE_SSL` el valor
«true» en `config/general.yml`). Para ello necesitará un certificado SSL para su dominio.

Copie la configuración SSL, cambiando de nuevo `www.example.com` por su dominio,
active el servidor `alaveteli_https` y desactive el sitio predeterminado.

    cp /var/www/alaveteli/config/nginx-ssl.conf.example \
      /etc/nginx/sites-available/alaveteli_https
    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/alaveteli_https \
      /etc/nginx/sites-enabled/alaveteli_https

<div class="attention-box">
  <strong>Nota:</strong> Por motivos de historial, <code>nginx-ssl.conf.example</code> establece la ruta de Alaveteli como <code>/var/www/alaveteli/alaveteli</code>; necesitará modificarla manualmente a <code>/var/www/alaveteli</code> o a la raíz de su instalación de Alaveteli.
</div>

Si está probando Alaveteli o configurando un sitio interno de pruebas, genere
certificados SSL autofirmados. **No utilice certificados autofirmados para un
servidor de producción**. Sustituya `www.example.com` por su nombre de dominio.

    openssl genrsa -out /etc/ssl/private/www.example.com.key 2048
    chmod 640 /etc/ssl/private/www.example.com.key

    openssl req -new -x509 \
      -key /etc/ssl/private/www.example.com.key \
      -out /etc/ssl/certs/www.example.com.cert \
      -days 3650 \
      -subj /CN=www.example.com
    chmod 640 /etc/ssl/certs/www.example.com.cert

Compruebe la configuración y solucione posibles problemas:

    service nginx configtest

Cargue la nueva configuración de Nginx y reinicie la aplicación:

    service nginx reload
    service alaveteli restart

#### Funcionamiento sin SSL

Asigne a `FORCE_SSL` el valor
«false» en `config/general.yml`. Copie el ejemplo de configuración de Nginx:

    cp /var/www/alaveteli/config/nginx.conf.example \
      /etc/nginx/sites-available/alaveteli

<div class="attention-box">
  <strong>Nota:</strong> Por motivos de historial, <code>nginx.conf.example</code> establece la ruta de Alaveteli como <code>/var/www/alaveteli/alaveteli</code>; necesitará modificarla manualmente a <code>/var/www/alaveteli</code> o a la raíz de su instalación de Alaveteli.
</div>

Desactive el sitio por defecto y active el servidor `alaveteli`:

    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/alaveteli \
      /etc/nginx/sites-enabled/alaveteli

Compruebe la configuración y solucione posibles problemas:

    service nginx configtest

Inicie la aplicación de Rails con Thin (si aún no lo ha hecho).

    service alaveteli start

Cargue de nuevo la configuración de Nginx:

    service nginx reload


---

## Añada Varnish como acelerador HTTP

En todas las cargas, excepto las ligeras, se recomienda encarecidamente que el servidor funcione con
un acelerador HTTP, como Varnish. Se suministra un VCL de muestra de Varnish en
`conf/varnish-alaveteli.vcl`.

Si utiliza SSL necesitará configurar un terminador de SSL delante de
Varnish. Si ya utiliza Apache como servidor web, puede utilizarlo
también como terminador SSL.

Tenemos algunas [notas sobre buenas prácticas para el servidor
de producción]({{ page.baseurl }}/docs/running/server/).

## ¿Qué hacer ahora?

Consulte los [siguientes pasos]({{ page.baseurl }}/docs/installing/next_steps/).

## Solución de problemas

*   **Efectúe las pruebas**

    Asegúrese de que todo está bien. Como usuario de Alaveteli, ejecute:

        bundle exec rake spec

    Si se produce algún error, algo ha fallado en los pasos anteriores
    (consulte la próxima sección sobre problemas y soluciones comunes). Es posible que
    pueda avanzar a los [siguientes pasos]({{ page.baseurl }}/docs/installing/next_steps/), según la gravedad del problema,
    pero lo ideal sería que intentara averiguar la causa del error.


<div class="attention-box">
  <strong>Nota:</strong> Si ha configurado su instalación de Alaveteli para producción, necesitará eliminar temporalmente el archivo <code>config/rails_env.rb</code>, utilizado para forzar el entorno de rails en producción, y editar su archivo <code>.bundle/config</code> para eliminar la línea <code>BUNDLE_WITHOUT</code>, que excluye las dependencias de desarrollo. Una vez hecho esto, como usuario de Alaveteli, ejecute la instalación <code>bundle install</code>. También necesitará convertir Alaveteli en propietario de <code>/var/www/alaveteli/log/development.log</code> y llevar a cabo las migraciones de bases de datos.

    <pre><code>chown alaveteli:alaveteli /var/www/alaveteli/log/development.log
sudo -u alaveteli bundle exec rake db:migrate</code></pre>

Debería haber podido ejecutar las pruebas. No olvide restaurar <code>config/rails_env.rb</code> cuando haya terminado. Probablemente verá algunos errores de procesos cron, ya que se estarán ejecutando en el modo de desarrollo.

</div>


*   **No aparecen los correos entrantes en mi instalación de Alaveteli**

    Consulte el [manual general de solución de problemas de correo]({{ page.baseurl }}/docs/installing/email#solucin-de-problemas-generales-de-correo).

*   **Varias pruebas muestran el error «*Your PostgreSQL connection does not support
    unescape_bytea. Try upgrading to pg 0.9.0 or later*»**

    Tiene una versión antigua de `pg`, el controlador de Postgres de Ruby. En
    Ubuntu, por ejemplo, es proporcionado por el paquete `libdbd-pg-ruby`.

    Pruebe actualizando la instalación `pg` de su sistema o instalando el paquete gem pg
    con `gem install pg`

*   **Algunas de las pruebas relacionadas con el correo están fallando con mensajes tales como
    «*when using TMail should load an email with funny MIME settings'
    FAILED*»**

    Parece que las pruebas se están efectuando en el entorno `production`
    en lugar de en el entorno `test` por algún motivo.

*   **Los caracteres que no pertenecen al código ASCII se muestran como asteriscos en mis mensajes entrantes**

    Utilizamos `elinks` para convertir los correos HTML en texto sin formato.
    Normalmente la codificación debería funcionar, pero en algunas circunstancias parece que 
    `elinks` ignora los parámetros recibidos desde Alaveteli.

    Para forzar que `elinks` siempre trate las entradas como UTF8, añada lo siguiente
    a `/etc/elinks/elinks.conf`:

        set document.codepage.assume = "utf-8"
        set document.codepage.force_assumed = 1

    También debería comprobar que su localización está configurada correctamente. Consulte
    [esta publicación de seguimiento](https://github.com/mysociety/alaveteli/issues/128#issuecomment-1814845)
    para obtener más información.

*   **Recibo `rake: command not found` al ejecutar el script posterior a la instalación**

    El script utiliza `rake`.

    Es posible que las librerías binarias instaladas por bundler no se ubiquen en la
    ruta `PATH` del sistema; por tanto, para poder ejecutar `rake` (necesario para los
	despliegues), deberá utilizar un comando similar a este:

        ln -s /usr/lib/ruby/gems/1.8/bin/rake /usr/local/bin/



