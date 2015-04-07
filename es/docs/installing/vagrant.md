---
layout: es/page
title: Vagrant
---
# Alaveteli con Vagrant

<p class="lead">
Vagrant proporciona un método sencillo para configurar entornos de desarrollo virutales; para
obtener más información, consulte <a href="http://www.vagrantup.com">el sitio web de Vagrant</a>.
Incluimos un archivo Vagrantfile de ejemplo en el repositorio, que ejecuta el
<a href="{{ page.baseurl }}/docs/installing/script/">script de instalación</a> automáticamente.
</p>

Esta es solo una de las [diversas maneras de instalar Alaveteli]({{ page.baseurl }}/docs/installing/).

Los pasos incluidos utilizarán Vagrant para crear un entorno de desarrollo
donde podrá poner en funcionamiento la suite de pruebas y el servidor de desarrollo, así
como modificar la base del código.

El proceso básico consiste en crear una máquina virtual de base y después proporcionarle
los paquetes de software y la configuración que necesita. Los
scripts suministrados crearán una máquina virtual de Vagrant basada en la edición de servidor de
Ubuntu 12.04 LTS que contiene todo lo necesario para trabajar con Alaveteli.

1.   Obtenga una copia de Alaveteli desde GitHub y cree la implementación de Vagrant.
  Esta acción abastecerá al sistema y puede necesitar cierto tiempo, normalmente un mínimo
  de 20 minutos.

            # en su máquina
            $ git clone git@github.com:mysociety/alaveteli.git
            $ cd alaveteli
            $ git submodule update --init
            $ vagrant --no-color up

2.   Ahora debería poder utilizar SSH en el sistema operativo invitado de Vagrant y arrancar
  la suite de pruebas:

            $ vagrant ssh

            # Ahora se halla en un terminal de la máquina virtual
            $ cd /home/vagrant/alaveteli
            $ bundle exec rake spec


3.   Ejecute el servidor de Rails y visite la aplicación en el navegador de su host, en
   http://10.10.10.30:3000

            # en el terminal de la máquina virtual
            bundle exec rails server

## ¿Qué hacer a continuación?

Consulte los [siguientes pasos]({{ page.baseurl }}/docs/installing/next_steps/).

## Personalice la implementación de Vagrant

El archivo Vagrantfile permite la personalización de algunos aspectos de la máquina virtual. Consulte las opciones de personalización en el archivo [`Vagrantfile`](https://github.com/mysociety/alaveteli/blob/master/Vagrantfile#L30) ubicado en el nivel superior del repositorio de Alaveteli.

Las opciones pueden configurarse bien indicando como prefijo el comando de Vagrant o bien
exportándolo al entorno.

     # Prefijo con el comando
     $ ALAVETELI_VAGRANT_MEMORY=2048 vagrant up

     # Exportación al entorno
     $ export ALAVETELI_VAGRANT_MEMORY=2048
     $ vagrant up

Ambos casos producen el mismo resultado, pero la exportación mantendrá la variable durante la duración completa de su sesión.

