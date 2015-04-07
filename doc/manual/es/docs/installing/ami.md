---
layout: es/page
title: Instalación desde el AMI
---

# Instalación con EC2 de Amazon

<p class="lead">
  Hemos creado una Amazon Machine Image (AMI) para que pueda efectuar el despliegue
  rápidamente en EC2 de Amazon. Resulta práctico si, por ejemplo, solamente desea evaluar Alaveteli.
</p>

Existen [otras formas de instalar Alaveteli]({{ page.baseurl }}/docs/installing/).

## Instalación con nuestra AMI

Para ayudarle a probar Alaveteli, hemos creado una AMI con una instalación básica de
Alaveteli, que puede utilizar para crear un servidor funcional en una implementación de EC2
de Amazon. Se creará una implementación que funcionará como
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">servidor de desarrollo</a>.
Si desea crear un
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">servidor de producción</a>,
deberá
[modificar la configuración]({{ page.baseurl }}/docs/customising/config/#staging_site).

<div class="attention-box">
  <p>
    <strong>Qué incluye el AMI:</strong>
    El AMI le ofrece exactamente lo mismo que el
    <a href="{{ page.baseurl }}/docs/installing/script/">script de instalación</a>.
    Obtiene un sitio web basado en Alaveteli implementado con Rails en el servidor
    de aplicaciones Thin con Nginx, utilizando la base de datos PostgreSQL. Todo ello
    sobre los servidores EC2 de Amazon, listo para ser
    <a href="{{ page.baseurl }}/docs/customising/">configurado y personalizado</a>.
  </p>
</div>

Las implementaciones de Amazon se clasifican por tamaños. Lamentablemente la implementación *Micro*
no tiene memoria suficiente para que Alaveteli funcione y este es el único tamaño disponible
en Amazon para su uso gratuito. Necesitará la implementación *Small* o una superior, por la que
Amazon le facturará el importe correspondiente.

### Uso de los servicios web de Amazon

Para ello necesitará:

   * Una cuenta de Amazon
   * Un par de claves SSL (las pantallas del servicio web de Amazon le guiarán al respecto)

Si aún no dispone de estos elementos, deberá crearlos. Consulte la introducción de Amazon sobre el
[funcionamineto de un servidor virtual en AWS](http://docs.aws.amazon.com/gettingstarted/latest/awsgsg-intro/gsg-aws-virtual-server.html).

### Lance la implementación

Una vez haya iniciado sesión en el servicio de Amazon y haya navegado hasta la consola
**EC2 Management Console**, puede lanzar la implementación. Si prefiere hacerlo manualmente,
encontrará el AMI en la región «EU West (Ireland)» con el ID
`ami-baf351cd` y el nombre «Basic Alaveteli installation 2014-10-06».
Alternativamente puede utilizar este enlace:

<p class="action-buttons">
  <a href="https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-baf351cd" class="button">Lanzar
  implementación con AMI de instalación de Alaveteli</a> 
</p>

Cuando se lance la implementación, lo primero que deberá elegir es el *tipo* de implementación.
Recuerde que el tipo *Micro* no dispone de memoria suficiente para ejecutar
Alaveteli, así que deberá elegir al menos *Small* o *Medium*. Estos tipos no están
disponibles en Amazon para su uso gratuito.

Una vez creada la implementación, la interfaz de Amazon le ofrecerá numerosas opciones
de configuración. En general puede aceptar las opciones predeterminadas para todo,
excepto para los grupos de seguridad. Resulta seguro hacer clic en **Review and
Launch** directamente (más que configurar manualmente todos los detalles de la 
implementación) debido a que aún puede tener la oportunidad de configurar los grupos
de seguridad. Haga clic en **Edit Security Groups** en la página de resumen antes de
pulsar el gran botón **Launch**.

Deberá elegir grupos de seguridad que permitan al menos HTTP, HTTPS y SSH entrantes
y también SMTP, si desea probar el correo entrante. Los ajustes de Amazon disponibles
aquí le permiten especificar las direcciones IP desde las que su implementación aceptará
solicitudes. Es una buena práctica restringirlas (si duda, elija una fuente *Source*
de «My IP» para todas ellas, excepto para las conexiones HTTP entrantes, para las que
deberá definir *Source* como «Anywhere»). Puede modificar cualquiera de estas opciones más
adelante, si necesita hacerlo.

### Inicie sesión en el servidor (shell)

Necesitará acceso a la consola shell de línea de comando del servidor para controlar y
configurar su sitio basado en Alaveteli.

Para acceder al servidor, utilice `ssh` y el archivo `.pem` de su par de claves SSL.
Modifique el archivo `.pem` y el ID de implementación para que concuerden con los suyos en
este comando, que conecta con su servidor y le registra como el usuario llamado `ubuntu`. 
Utilice este comando desde su propio equipo para iniciar sesión en el servidor:

    ssh -i path-to/your-key-pair.pem ubuntu@instance-id.eu-west-1.compute.amazonaws.com

No se le solicitará ninguna contraseña porque el archivo `.pem` suministrado con la
opción `-i` contiene la autorización que concuerda con la ubicada en el otro extremo,
en el servidor. Iniciará sesión en el terminal shell de su nuevo servidor de Alaveteli
y podrá introducir comandos Unix en él.

### Prueba de humo: inice Alavateli

Debe configurar su sitio basado en Alavateli, pero si solo desea ver si su implementación
funciona correctamente, *puede* arrancarla directamente. Lo ideal sería omitir este
paso e ir directamente a la configuración... Pero sabemos que la mayoría de personas
prefieren ver algo en el navegador primero. ;-)

En el terminal shell de línea de comando, como usuario `ubuntu`, inicie Alaveteli ejecutando:

    sudo service alaveteli start

Encuentre la URL de «DNS público» en su implementación de EC2 desde la consola AWS y acceda a
ella en el navegador. Tendrá la forma
`http://your-ec2-hostname.eu-west-1.compute.amazonaws.com`. Aquí verá su sitio basado en
Alaveteli.

Su sitio aún no está configurado, así que *esto no es seguro* (por ejemplo, aún no ha
definido sus propias contraseñas para acceder a la interfaz de administración), así que, una vez
haya visto el sitio en funcionamiento, detenga el sitio basado en Alaveteli con:

    sudo service alaveteli stop


### Usuarios de shell: `ubuntu` y `alaveteli`

Cuando inicia sesión en la consola shell de línea de comando de su implementación, debe hacerlo
como usuario `ubuntu`. Este usuario puede utilizar los permisos `sudo` libremente para ejecutar comandos
como root. Sin embargo, el código en realidad es propiedad (y se ejecuta a través) del usuario `alaveteli`.

Necesitará
[personalizar la configuración del sitio]({{ page.baseurl }}/docs/customising/config/).
Para ello, inicie sesión en su servidor de EC2 y edite el archivo de configuración `general.yml`.

El archivo de configuración que necesita editar es
`/var/www/alaveteli/alaveteli/config/general.yml`. Por ejemplo, utilice el
editor `nano` (como usuario `alaveteli`) de este modo:

    ubuntu@ip-10-58-191-98:~$ sudo su - alaveteli
    alaveteli@ip-10-58-191-98:~$ cd alaveteli
    alaveteli@ip-10-58-191-98:~/alaveteli$ nano config/general.yml

Tras efectuar los cambios en este archivo, necesitará iniciar el servidor de aplicaciones
(utilice `restart` en lugar de `start` si ya se halla en funcionamiento):

    alaveteli@ip-10-58-191-98:~/alaveteli$ logout
    ubuntu@ip-10-58-191-98:~$ sudo service alaveteli start

Su sitio estará funcionando en la URL de nuevo, que tiene la forma
`http://your-ec2-hostname.eu-west-1.compute.amazonaws.com`.

Si tiene algún problema o alguna consulta, indíquelo en al [lista de correo de desarrollo de Alaveteli](https://groups.google.com/forum/#!forum/alaveteli-dev) o [informe de un error](https://github.com/mysociety/alaveteli/issues?state=open).


##¿Qué hacer ahora?

Consulte los [siguientes pasos]({{ page.baseurl }}/docs/installing/next_steps/).
