---
layout: es/page
title: Siguientes pasos
---
# Siguientes pasos

<p class="lead">
    Bien, ha instalado una copia de Alaveteli y puede visualizar el sitio en un navegador. ¿Qué debe hacer ahora?
</p>

## Cree una cuenta de administrador superusuario

Alaveteli incluye un
<a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">usuario de emergencia</a>
que tiene acceso a la interfaz de administración. Así, cuando acabe de crear un sitio, deberá
registrarse para crear su propia cuenta y después iniciar sesión en la interfaz de administración
con el usuario de emergencia para ascender su nueva cuenta a administrador con permisos de *superusuario*.

Una vez hecho esto, desactive el usuario de emergencia, pues no necesitará utilizarlo más: lo habrá
reemplazado con su nueva cuenta de administrador.

Alaveteli incluye datos de muestra con un usuario administrador llamado «Joe
Admin». Si los datos de muestra se han cargado en la base de datos (depende del tipo
de instalación elegido), deberá revocar también los permisos de administrador de Joe, pues
utilizará su propia cuenta de administrador en su lugar.

### Paso a paso:

En primer lugar, en el navegador:

* Acceda a `/profile/sign_in` y cree un usuario siguiendo el proceso de registro.
* Consulte su correo y confirme su cuenta.
* Acceda a `/admin?emergency=1`, inicie sesión con el código de usuario y la contraseña
  que ha especificado en [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
  y [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password).
  Puede consultar estos ajustes en `config/general.yml`.
* Ahora se encontrará en la página de adminsitración de Alaveteli.
* Haga clic en **Users**  (en el menú de navegación superior de la página) y eliga
  su nombre en el listado de usuarios. En *esa* página,  haga clic en **Edit**.
* Modifique su *Admin level* a «super» y haga clic en **Save**.
* A partir de ahora, al iniciar sesión en su sitio basado en Alavateli, tendrá acceso
  a la interfaz de administración (en `/admin`). Es más, verá enlaces a páginas administrativas
  externas al sitio principal (que no son visibles para usuarios comunes).

Si su instalación ha cargado los datos de muestra, habrá un usuario de prueba en su base
de datos llamado «Joe Admin» también con permisos de administrador. Deberá eliminar estos
permisos para que no exista riesgo de que se utilice para acceder a la administración de su
sitio. Puede hacer esto mientras tiene la sesión iniciada como usuario de emergencia o más tarde,
iniciando su propia sesión:

* Acceda a `/admin/users` o haga clic en **Users** en el menú de navegación de la 
  página de administración.
* Busque «Joe Admin» en el listado de usuarios y haga clic en el nombre para ver los 
  detalles del usuario. En *esa* página,  haga clic en **Edit**.
* Modifique su *Admin level* de «super» a «none» y haga clic en **Save**.
* Joe Admin ya no tendrá permisos de administrador.

Ahora que su cuenta corresponde a un superusuario administrador, no necesita permitir el
acceso del usuario de emergencia a la interfaz de administración. En la línea de comando, edite
`/var/www/alaveteli/alaveteli/config/general.yml`:

* Es importante que modifique la contraseña del usuario de emergencia (e, idealmente,
  también el código de usuario) que se incluye en Alavateli, pues es públicos y
  consecuentemente no seguro. En `general.yml`, cambie
  [`ADMIN_PASSWORD`]({{ page.baseurl }}/docs/customising/config/#admin_password)
  (y tal vez [`ADMIN_USERNAME`]({{ page.baseurl }}/docs/customising/config/#admin_username)
  también) por un valor nuevo exclusivo.
* También puede desactivar totalmente el usuario de emergencia. En condiciones
  normales no lo necesitará, pues a partir de ahora utilizará el usuario administrador que
  acaba de crear.
  Asigne a [`DISABLE_EMERGENCY_USER`]({{ page.baseurl }}/docs/customising/config/#disable_emergency_user)
  el valor `true`.
* Para aplicar estos cambios, reinicie el servicio como usuario con permisos root:
  `sudo service alaveteli restart`

Puede utilizar el mismo proceso (con su sesión de administrador iniciada) para añadir o eliminar
permisos de superusuario administrador de cualquier usuario que añada en su sitio.
Si elimina accidentalmente los permisos de administrador de todas las cuentas (¡pero intente que
esto no ocurrra!), puede activar el usuario de emergencia editando el archivo `general.yml`
y reiniciando Alaveteli.

## Cargue los datos de muestra

Si desea tener algunos datos de muestra con los que probar, puede intentar cargar los elementos comunes que utiliza
la suite de pruebas en su base de datos de desarrollo. Como usuario `alaveteli`, ejecute:

    script/load-sample-data

Si los datos de muestra ya se han cargado en la base de datos, este comando no hará nada, sino que
<abbr title='PG::Error: ERROR:  permission denied: "RI_ConstraintTrigger_XXXXXX" is a system trigger'>generará un error</abbr>.

Si ha añadido los datos de muestra, actualice después el índice de búsqueda de Xapian:

    script/update-xapian-index

Recuerde que los datos de muestra incluyen un usuario con permisos de administrador en su sitio.
Debería revocar estos permisos para que no pueda utilizarse en el acceso a su sitio: siga
los pasos descritos en la sección anterior.

## Pruebe el proceso de solicitud

* Cree una nueva autoridad pública en la interfaz de administración, dele un nombre tal como
  «Autoridad de prueba». Defina el correo de solicitud con una dirección que le pertenezca.

* Desde la interfaz principal del sitio, efectúe una solicitud a la nueva autoridad.

* Debería recibir el correo de la solicitud, intente responder a él. Su correo de respuesta
  debería aparecer en Alaveteli. ¿No funciona? Consulte nuestros
  [consejos para la solución de problemas]({{ page.baseurl }}/docs/installing/manual_install/#solucin-de-problemas).
  Si no es suficiente, [póngase en contacto]({{ page.baseurl }}/community/) mediante
  la [lista de correo de desarrollo](https://groups.google.com/forum/#!forum/alaveteli-dev) o por [IRC](http://www.irc.mysociety.org/)
  para obtener ayuda.

## Importe las autoridades públicas

Alaveteli puede importar un listado de autoridades públicas y sus direcciones de correo de contacto desde un archivo CSV.

Encontrará el cargador en la pestaña «Authorities» de la sección de administración o accediendo directamente a `/admin/body/import_csv`.

## Empiece a pensar en la personalización de Alaveteli

Consulte [nuestro manual]({{ page.baseurl }}/docs/customising/).
