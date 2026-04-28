---
layout: es/page
title: Instalación en MacOS X
---

# Instalación en MacOS X

<p class="lead">
  No recomendamos el uso de OS X en producción, pero si desea configurar
  Alaveteli en su Mac para su desarrollo, estas indicaciones le serán
  de ayuda.
</p>

Existen [otras formas de instalar Alaveteli]({{ page.baseurl }}/docs/installing/).

## MacOS X 10.7

Siga estas instrucciones para poner en marcha Alaveteli localmente en una máquina con OS X. Estas instrucciones se han probado con Xcode 4.1 en OS X Lion (10.7). No recomendamos el uso de OS X en producción.

**Nota:** Este manual está incompleto actualmente. Ayúdenos publicando problemas en [el grupo de Google alaveteli-dev](https://groups.google.com/group/alaveteli-dev) o enviando solicitudes pull.

## Xcode

Si utiliza OS X Lion, descargue *Command Line Tools for Xcode* de [Apple](https://developer.apple.com/downloads/index.action). Se trata de un nuevo paquete de Apple que proporciona las herramientas integradas de línea de comando independientemente del resto de Xcode. Necesitará registrar una cuenta gratuita de desarrollador de Apple.

**Nota:** En Xcode 4.2 ya no se incluye una versión de GCC sin LLVM. Homebrew ha actuado ante esta circunstancia [cambiando a Clang](https://github.com/mxcl/homebrew/issues/6852). Sin embargo, es posible que encuentre errores al instalar RVM. *Informe de ellos en la [lista de correo](https://groups.google.com/group/alaveteli-dev).* Las siguientes instrucciones se han probado con Xcode 4.1. En caso necesario, puede instalar GCC de Xcode 4.1 ejecutando:

    brew install https://github.com/adamv/homebrew-alt/raw/master/duplicates/apple-gcc42.rb

## Homebrew

Homebrew es un gestor de paquetes para OS X. Es el preferido frente a otras alternativas como MacPorts y Fink. Si todavía no tiene instalado Homebrew, ejecute el comando:

    ruby <(curl -fsSkL raw.github.com/mxcl/homebrew/go)

A continuación instale los paquetes requeridos por Alaveteli:

    brew install catdoc elinks gnuplot gs imagemagick libmagic libyaml links mutt poppler tnef wkhtmltopdf wv xapian unrtf


### Instale PostgreSQL

Alaveteli utiliza PostgreSQL por defecto. Si ha probado Alaveteli con MySQL o SQLite, infórmenos en el [grupo de Google alaveteli-dev](https://groups.google.com/group/alaveteli-dev).

    brew install postgresql
    initdb /usr/local/var/postgres
    mkdir -p ~/Library/LaunchAgents
    cp /usr/local/Cellar/postgresql/9.0.4/org.postgresql.postgres.plist ~/Library/LaunchAgents/
    launchctl load -w ~/Library/LaunchAgents/org.postgresql.postgres.plist

## PDF Toolkit

[Descargue el paquete de instalación](https://github.com/downloads/robinhouston/pdftk/pdftk.pkg) y ejecútelo.

## Ruby

### Instale RVM

RVM es la forma preferida de instalar numerosas versiones de Ruby en OS X. Alaveteli utiliza Ruby 1.8.7. Los siguientes comandos presuponen que está utilizando Bash.

    curl -L https://get.rvm.io | bash -s stable

Lea las notas `rvm notes` y los requisitos `rvm requirements` con cuidado para obtener más instrucciones. Después, instale Ruby:

    rvm install 1.8.7
    rvm install 1.9.3
    rvm use 1.9.3 --default

### Instale mahoro y pg con flags

Los paquetes gem `mahoro` y `pg` necesitas comandos de instalación especiales. Rubygems debe atrasarse a la versión 1.6.2 para evitar advertencias sobre funcionalidades obsoletas al efectuar las pruebas.

    rvm 1.8.7
    gem update --system 1.6.2
    gem install mahoro -- --with-ldflags="-L/usr/local/Cellar/libmagic/5.09/lib" --with-cppflags="-I/usr/local/Cellar/libmagic/5.09/include"
    env ARCHFLAGS="-arch x86_64" gem install pg

#### Actualización

Con fecha de 22 de agosto de 2012 o anterior, puede instalar `mahoro` en Ruby 1.9.3 en OS X 10.7 Lion mediante:

    brew install libmagic
    gem install mahoro

## Alaveteli

La siguiente información procede en gran parte del [proceso de instalación manual]({{ page.baseurl }}/docs/installing/manual_install).

### Configure la base de datos

Cree una base de datos para su usuario de Mac, ya que Homebrew no crea uno por defecto:

    createdb

Cree un usuario `foi` desde la línea de comando, de este modo:

    createuser -s -P foi

_Nota:_ Dejar la contraseña en blanco puede causar gran confusión si no está familiarizado con PostgreSQL.

Cree una plantilla para nuestras bases de datos de Alaveteli:

    createdb -T template0 -E UTF-8 template_utf8
    echo "update pg_database set datistemplate=true where datname='template_utf8';" | psql

A continuación, cree las bases de datos:

    createdb -T template_utf8 -O foi alaveteli_production
    createdb -T template_utf8 -O foi alaveteli_test
    createdb -T template_utf8 -O foi alaveteli_development

### Clone Alaveteli

No deseamos Rails comerciales porque causan problemas localmente.

    git clone https://github.com/mysociety/alaveteli.git
    cd alaveteli
    git submodule init

    sed -i~ 's/\\&#91;submodule "vendor\/rails"\\&#93;//' .git/config

    sed -i~ 's/url = git:\/\/github.com\/rails\/rails.git//' .git/config
    git submodule update

**Nota:** Debido a errores de Markdown, el primer comando `sed` anterior no se estará mostrando correctamente si aparece entre comillas.

### Configure Alaveteli

Copie los archivos de ejemplo de configuración y configure `database.yml`.

    cp -f config/general.yml-example config/general.yml
    cp -f config/memcached.yml-example config/memcached.yml
    cp -f config/database.yml-example config/database.yml
    sed -i~ 's/<username>/foi/' config/database.yml
    sed -i~ 's/<password>/foi/' config/database.yml
    sed -i~ 's/  port: 5432//' config/database.yml
    sed -i~ 's/ # PostgreSQL 8.1 pretty please//' config/database.yml

### Bundler

Instale los paquetes gem y finalice la configuración de Alaveteli.

    rvm 1.8.7
    bundle
    bundle exec rake db:create:all
    bundle exec rake db:migrate
    bundle exec rake db:test:prepare

## Solución de problemas

### Versión de Ruby

Asegúrese de estar utilizando la última versión de Ruby. Por ejemplo, algunas versiones de Ruby 1.8.7 fallarán en la segmentación, por ejemplo:

```
/Users/james/.rvm/gems/ruby-1.8.7-p357/gems/json-1.5.4/ext/json/ext/json/ext/parser.bundle: [BUG] Segmentation fault
ruby 1.8.7 (2011-12-28 patchlevel 357) [i686-darwin11.3.0]
```

La ejecución de `rvm install 1.8.7` debería instalar el último nivel de parche de Ruby 1.8.7. Recuerde cambiar a la última versión de Ruby antes de continuar.

### Tareas rake

Recuerde ejecutar las tareas rake con `bundle exec`. Para ello, por ejemplo, ejecute `bundle exec rake`.
