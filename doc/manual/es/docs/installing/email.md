---
layout: es/page
title: Instalación del MTA
---

# Instalación del MTA

<p class="lead">
  Alaveteli envía y recibe correo. Necesitará configurar su servidor
  de correo (MTA) para gestionarlo adecuadamente. Aquí ofrecemos ejemplos
  para Postfix y Exim4, dos de los MTA más populares.
</p>

## Cómo gestiona el correo Alaveteli

### Correo de solicitud

Cuando alguien realiza una solicitud de información pública a una autoridad a través de
Alaveteli, la aplicación envía un correo con la solicitud a la autoridad.

La dirección `reply-to` del correo es un campo especial que indica que toda respuesta
debe dirigirse automáticamente de vuelta a Alaveteli, para que Alaveteli pueda
distinguir en qué solicitud debe mostrarse la respuesta recibida. Este comportamiento
requiere cierta configuración del MTA en el servidor donde se halla Alaveteli para
encaminar todos los correos a esta dirección especial con el objetivo de que Alaveteli
los gestione mediante su script `script/mailin`. Las direcciones especiales tienen
la siguiente estructura:

    <foi+request-3-691c8388@example.com>

Partes de esta dirección son controladas con opciones incluidas en
`config/general.yml`:

    INCOMING_EMAIL_PREFIX = 'foi+'
    INCOMING_EMAIL_DOMAIN = 'example.com'

Si se produce algún error en Rails durante el procesamiento del correo, el script `script/mailin` devuelve un código de salida `75` al MTA. Postfix y Exim (y tal vez otros) entienden esta acción como una señal para que el MTA lo vuelva a intentar más tarde. Además, se envía por correo el rastro de pila a `CONTACT_EMAIL`.

Las instalaciones de [producción]({{ page.baseurl }}/docs/glossary/#production) de Alaveteli deberían realizar copias de seguridad de los correos enviados a direcciones especiales. Puede configurar su MTA para realizar estas copias en un buzón de correo independiente.

### Correo transaccional

Alaveteli también envía correos a usuarios sobre sus solicitudes, para informarles cuando alguien ha respondido o solicitarles que realicen alguna acción.

Configure la dirección desde la que se envían estos mensajes en la opción [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) de `config/general.yml`:

    CONTACT_EMAIL = 'team@example.com'

La dirección contenida en [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) también es visible en varios lugares del sitio para que los usuarios puedan ponerse en contacto con el equipo que gestiona el sitio web.

Debe configurar su MTA de forma que entregue el correo enviado a estas direcciones a los administradores del sitio para que puedan responder en consecuencia.

### Correo de tracks

Los usuarios suscritos a las actualizaciones del sitio, denominadas `tracks`, reciben correos cuando hay novedades que pueden interesarles.

Configure la dirección desde la que se envían estos mensajes en la opción [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) ubicada en `config/general.yml`:

    TRACK_SENDER_EMAIL = 'track@example.com'

### Gestión de rebotado automático (opcional)

Debido a que [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) y [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) aparecen en la cabecera `From:` de los correos enviados desde Alaveteli, a veces reciben correos de respuesta, incluidos <a href="{{ page.baseurl }}/docs/glossary/#bounce-message">mensajes rebotados</a> y notificaciones de tipo «fuera de oficina».

Alaveteli proporciona un script (`script/handle-mail-replies`) que gestiona los mensajes rebotados y las notificaciones de tipo «fuera de oficina» y reenvía los correos genuinos a los administradores.

También evita que se sigan enviando correos de tracks a direcciones de correo de usuarios que parezcan tener problemas permanentes de entrega.

Para utilizar la gestión automática de mensajes rebotados, asigne a [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) y a [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) una dirección que filtrará a través de `script/handle-mail-replies`. Los mensajes que no sean de rebote o «fuera de oficina» se reenviarán a  [`FORWARD_NONBOUNCE_RESPONSES_TO`]({{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to), opción en la que debe definir un alias de correo que apunte a la lista de administradores del sitio.

Consulte las indicaciones específicas para su MTA sobre cómo llevar esto a cabo con [Exim]({{ page.baseurl }}/docs/installing/email#filtre-los-mensajes-entrantes-hacia-direcciones-de-administracin) y [Postfix]({{ page.baseurl }}/docs/installing/email#filtre-mensajes-entrantes-en-las-direcciones-de-administracin-del-sitio).

_Nota:_ La gestión de rebotado no se aplica a los [correos de solicitud]({{ page.baseurl }}/docs/installing/email#correo-de-solicitud). Los mensajes rebotados de autoridades se añaden a la página de la solicitud para que el usuario pueda ver lo ocurrido. Los usuarios pueden pedir ayuda a los administradores del sitio para que se vuelva a enviar la solicitud, si es necesario.


---

<div class="attention-box">
 <ul>
 <li>Los comandos incluidos en este manual requieren permisos de usuario root.</li>
 <li>Los comandos deben ejecutarse en el terminal o mediante SSH.</li>
 </ul>
</div>

Asegúrese de seguir las indicaciones correctas para el MTA específico que utilice:

* [Postfix](#configuracin-de-ejemplo-con-postfix)
* [Exim4](#configuracin-de-ejemplo-con-exim4)

## Configuración de ejemplo con Postfix

Esta sección muestra un ejemplo de configuración de su MTA con
**Postfix**. Si utiliza Exim4 en lugar de Postfix, consulte la
[configuración de ejemplo con Exim4](#configuracin-de-ejemplo-con-exim4).

### Instale Postfix

    # Instale debconf para poder configurar de forma no interactiva
    apt-get -qq install -y debconf >/dev/null

    # Establezca la configuración predeterminada «Internet Site»
    echo postfix postfix/main_mailer_type select 'Internet Site' | debconf-set-selections

    # Defina el nombre de host (sustituya example.com por su nombre de host)
    echo postfix postfix/mail_name string "example.com" | debconf-set-selections

    # Instale Postfix
    DEBIAN_FRONTEND=noninteractive apt-get -qq -y install postfix >/dev/null

### Configure Postfix


#### Redirija el correo entrante de solicitudes en Alaveteli

Si el usuario de Unix que va a poner el sitio en funcionamiento
es `alaveteli` y el directorio donde está instalado Alaveteli es
`/var/www/alaveteli`, cree una ruta para la recepción de correos
de solicitudes:

    cat >> /etc/postfix/master.cf <<EOF
    alaveteli unix  - n n - 50 pipe
      flags=R user=alaveteli argv=/var/www/alaveteli/script/mailin
    EOF

El usuario de Unix debe tener permisos de escritura en el directorio de instalación de Alaveteli.

Configure Postfix para que acepte mensajes de entrega local cuando los destinatarios sean:

  - definidos por una expresión regular en `/etc/postfix/transports`
  - cuentas locales de UNIX
  - alias locales especificados como expresiones regulares en `/etc/postfix/recipients`

<!-- Comment to enable markdown to render code fence under list -->

    cat >> /etc/postfix/main.cf <<EOF
    transport_maps = regexp:/etc/postfix/transports
    local_recipient_maps = proxy:unix:passwd.byname regexp:/etc/postfix/recipients
    EOF

Actualice la línea `mydestination` ubicada en `/etc/postfix/main.cf` (encargada de definir a qué dominios se efectuarán entregas locales). Añada su dominio, no `example.com`, al principio de la lista:

    mydestination = example.com, localhost.localdomain, localhost

<div class="attention-box">
Este manual presupone que ha definido <a href="{{ page.baseurl }}/docs/customising/config/#incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a> como <code>foi+</code> en <code>config/general.yml</code>
</div>

Redirija todo el correo entrante cuya dirección `To:` empiece por `foi+` hacia la ruta de `alaveteli` (`/var/www/alaveteli/script/mailin`, como se especifica en `/etc/postfix/master.cf` en el inicio de esta sección):

    cat > /etc/postfix/transports <<EOF
    /^foi.*/                alaveteli
    EOF

#### Realice copias de seguridad de los correos de solicitudes

Puede copiar todo el correo entrante de Alaveteli en una cuenta para copias de seguridad ubicada en un buzón independiente, por si se produce algún problema.

Cree un usuario de Unix `backupfoi`:

    adduser --quiet --disabled-password \
      --gecos "Alaveteli Mail Backup" backupfoi

Añada la siguiente línea a `/etc/postfix/main.cf`:

    recipient_bcc_maps = regexp:/etc/postfix/recipient_bcc

Configure el correo enviado a una dirección con el prefijo `foi+` para que se envíe al usuario de la copia de seguridad:

    cat > /etc/postfix/recipient_bcc <<EOF
    /^foi.*/                backupfoi
    EOF


#### Defina los destinatarios válidos para su dominio

Cree `/etc/postfix/recipients` con el siguiente comando:

    cat > /etc/postfix/recipients <<EOF
    /^foi.*/                this-is-ignored
    /^postmaster@/          this-is-ignored
    /^user-support@/        this-is-ignored
    /^team@/                this-is-ignored
    EOF

La columna de la izquierda de este archivo especifica las expresiones regulares que 
definen direcciones para las que se aceptará correo. Los valores de la parte derecha 
son ignorados por Postfix. Aquí permitimos que Postfix acepte correos hacia
direcciones especiales de Alaveteli y hacia `postmaster@example.com`,
`user-support@example.com` y `team@example.com`.

El dominio `@example.com` se define en `mydestination`, como se ha mostrado anteriormente. Esta variable debería incluir su propio dominio.

#### Defina grupos de destinatarios de correo de contacto 

Para definir los grupos de destinatarios de las direcciones de correo `postmaster@`, `team@` y `user-support@` en su dominio, añada registros de alias para ellos en `/etc/aliases`:

    cat >> /etc/aliases <<EOF
    team: user@example.com, otheruser@example.com
    user-support: team
    EOF

#### Descarte correo entrante no deseado

Configure Postfix para que descarte los mensajes enviados a la dirección [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix), cuyo valor por defecto es `do-not-reply-to-this-address`:

    cat >> /etc/aliases <<EOF
    # Utilizamos esta opción como campo remitente para algunos mensajes 
    # en los que no nos interesa la confirmación de entrega
    do-not-reply-to-this-address:        /dev/null
    EOF

Si dispone de una dirección [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix), sustituya `do-not-reply-to-this-address` con la dirección que ha configurado.

#### Filtre mensajes entrantes en las direcciones de administración del sitio

Puede utilizar la [gestión automática de rebotado]({{ page.baseurl }}/docs/installing/email/#gestin-de-rebotado-automtico-opcional) de Alaveteli para filtrar mensajes rebotados enviados a [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email)
y a [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email).


<div class="attention-box">
Este manual presupone que ha configurado las opciones siguientes en <code>config/general.yml</code>:

  <ul>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#track_sender_email">TRACK_SENDER_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a>: <code>team@example.com</code></li>
  </ul>

Modifique los siguientes ejemplos con las direcciones que ha configurado:
</div>

Cree un nuevo flujo de gestión de respuestas:

    cat >> /etc/postfix/master.cf <<EOF
    alaveteli_replies unix  - n n - 50 pipe
      flags=R user=alaveteli argv=/var/www/alaveteli/script/handle-mail-replies
    EOF

_Nota:_ Sustituya `/var/www/alaveteli` con la ruta correcta de Alaveteli, si es necesario.

Redirija el correo enviado a `user-support@example.com` hacia `alaveteli_replies`:

    cat >> /etc/postfix/transports <<EOF
    /^user-support@*/                alaveteli_replies
    EOF

Finalmente, edite `/etc/aliases` para eliminar `user-support`:

    team: user@example.com, otheruser@example.com

#### Registro

Para que los registros de Postfix sean leídos correctamente desde
`script/load-mail-server-logs`, necesita aplicarles la función logrotate con una fecha
en el nombre de archivo. Como esta acción creará numerosos archivos de tipo logrotate (uno por día),
se recomienda almacenarlos en un directorio específico para ellos.

También necesitará indicarle a Alaveteli dónde se almacenan los archivos de registro y que se hallan en formato 
Postfix. Actualice
[`MTA_LOG_PATH`]({{ page.baseurl }}/docs/customising/config/#mta_log_path) y
[`MTA_LOG_TYPE`]({{ page.baseurl }}/docs/customising/config/#mta_log_type) en `config/general.yml`:

    MTA_LOG_PATH: '/var/log/mail/mail.log-*'
    MTA_LOG_TYPE: "postfix"

Configure Postfix para que efectúe los registros en su propio directorio:

##### Debian

En `/etc/rsyslog.conf`, defina:

    mail.*                  -/var/log/mail/mail.log


##### Ubuntu

En `/etc/rsyslog.d/50-default.conf`, defina:

    mail.*                  -/var/log/mail/mail.log

##### Configure logrotate

Configure logrotate para que rote los archivos de registro en el formato requerido:

    cat >> /etc/logrotate.d/rsyslog <<EOF
    /var/log/mail/mail.log
    {
          rotate 30
          daily
          dateext
          missingok
          notifempty
          compress
          delaycompress
          sharedscripts
          postrotate
                  reload rsyslog >/dev/null 2>&1 || true
          endscript
    }
    EOF

#### Aplique los cambios

Como usuario root, aplique todos estos cambios con los siguientes comandos:

    service rsyslog restart

    newaliases
    postmap /etc/postfix/transports
    postmap /etc/postfix/recipients
    postmap /etc/postfix/recipient_bcc
    postfix reload

#### Solución de problemas (Postfix)

Para probar la entrega de correo, ejecute:

    $ /usr/sbin/sendmail -bv foi+request-1234@example.com

Asegúrese de sustituir `example.com` por su dominio. Este comando indica
si el envío de correo a `foi\+.*example.com` y a la cuenta de la copia de seguridad
funciona (no envía ningún correo para probarlo). Si funciona, debería recibir
un correo de informe de entrega con un texto similar a:

    <foi+request-1234@example.com>: delivery via alaveteli:
    delivers to command: /var/www/alaveteli/script/mailin
    <backupfoi@local.machine.name>: delivery via local: delivers to mailbox

También puede probar otros alias que haya configurado para su dominio en
esta sección, con el objetivo de comprobar si entregarán el correo tal como espera. Por
ejemplo, puede probar el redireccionamiento de mensajes rebotados del mismo modo. El texto
de este informe de entrega debería ser similar a:

    <user-support@example.com>: delivery via alaveteli_replies: delivers to command: /var/www/alaveteli/script/handle-mail-replies


Es posible que necesite instalar el paquete `mailutils` para leer el informe
de entrega utilizando el comando `mail` en un nuevo servidor:

    apt-get install mailutils

Si los correos no son recibidos por su instalación de Alaveteli, encontrará más consejos 
sobre errores de correo entrante en el apartado de [solución de problemas generales de correo]({{ page.baseurl }}/docs/installing/email#solucin-de-problemas-generales-de-correo).



## Configuración de ejemplo con Exim4

Esta sección muestra un ejemplo de configuración de su MTA con
**Exim4**. Si utiliza Postfix en lugar de Exim4, consulte la
[configuración de ejemplo con Postfix](#configuracin-de-ejemplo-con-postfix).


### Instale Exim4

Instale Exim4:

     apt-get install exim4


### Configure Exim4

#### Configure Exim para que reciba correo desde otros servidores

Edite `/etc/exim4/update-exim4.conf.conf`. Defina las siguientes opciones (utilice su nombre de host, no `example.com`):

    dc_eximconfig_configtype='internet'
    dc_other_hostnames='example.com'
    dc_local_interfaces='0.0.0.0 ; ::1'
    dc_use_split_config='true'

Esta última línea indica a Exim que utilice los archivos de `/etc/exim4/conf.d` para configurarse a sí mismo.

#### Defina las variables generales y las opciones de registro

Cree `/etc/exim4/conf.d/main/04_alaveteli_options` con el comando:

    cat > /etc/exim4/conf.d/main/04_alaveteli_options <<'EOF'
    ALAVETELI_HOME=/var/www/alaveteli
    ALAVETELI_USER=alaveteli
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer
    extract_addresses_remove_arguments=false
    EOF

Esta acción configura `ALAVETELI_HOME` y `ALAVETELI_USER` para su uso en otros archivos de configuración y define las opciones de registro.

- **`ALAVETELI_HOME`:** define el directorio de instalación de Alaveteli.
- **`ALAVETELI_USER`:** debería ser el usuario de Unix que va a poner en funcionamiento su sitio. Debe tener permisos de escritura en `ALAVETELI_HOME`.
- **`log_file_path`:** El nombre y la ubicación de los archivos de registro creados por Exim deben coincidir con los esperados por el script `load-mail-server-logs`.
- **`MAIN_LOG_SELECTOR`:** El script `check-recent-requests-sent` espera que los registros contengan la información de remitente `from=<...>`, por lo que aumentamos la minuciosidad de los registros.
- **`extract_addresses_remove_arguments`:** si se le asigna el valor `false`, cuando el paquete gem `mail` utilice la opción de línea de comando `-t` para especificar las direcciones de entrega, Exim interpretará que dichas direcciones deben añadirse, no eliminarse. Consulte [esta publicación de `mail`](https://github.com/mikel/mail/issues/70) para obtener más información.

<div class="attention-box">
Nota: Si está editando una configuración existente de Exim en lugar de crear una nueva, compruebe la opción <code>untrusted_set_sender</code> en <code>/etc/exim4/conf.d/main/02_exim4-config_options</code>. Por defecto, los usuarios que no son de confianza en Exim solo pueden definir una dirección de remitente vacía para declarar que un mensaje no debe generar nunca ningún rebote. <code>untrusted_set_sender</code> puede definirse como una lista de patrones de dirección, de forma que los usuarios que no sean de confianza puedan definir direcciones de remitente que concuerden con alguno de los patrones listados. Si especifica una lista de patrones, también necesitará añadir <code>ALAVETELI_USER</code> a la lista <code>MAIN_TRUSTED_USERS</code> para permitir que se defina la ruta de retorno del correo saliente. Esta opción también se encuentra en <code>/etc/exim4/conf.d/main/02_exim4-config_options</code> en una configuración dividida. Busque la línea que empieza por <code>MAIN_TRUSTED_USERS</code>, similar a:

    <pre><code>MAIN_TRUSTED_USERS = uucp</code></pre>

y añada el usuario de Alaveteli:

    <pre><code>MAIN_TRUSTED_USERS = uucp : alaveteli</code></pre>

 Si <code>untrusted_set_sender</code> está definido como <code>*</code>, los usuarios que no sean de confianza podrán establecer direcciones de remitente sin restricciones, así que no será necesario añadir <code>ALAVETELI_USER</code> a la lista <code>MAIN_TRUSTED_USERS</code>.
</div>


#### Redirija el correo entrante de solicitudes desde Exim hacia Alaveteli

En esta sección añadiremos una configuración al flujo de correo entrante para direcciones
especiales de Alaveteli hacia Alaveteli y también las enviaremos al buzón local de la copia de
seguridad.

Cree el usuario de Unix `backupfoi`:

    adduser --quiet --disabled-password \
      --gecos "Alaveteli Mail Backup" backupfoi

Especifique un `router` de Exim para las direcciones especiales de Alaveteli, que redirigirá los mensajes hacia Alaveteli mediante una ruta de transporte local:

    cat > /etc/exim4/conf.d/router/04_alaveteli <<'EOF'
    alaveteli_request:
       debug_print = "R: alaveteli for $local_part@$domain"
       driver = redirect
       data = ${lookup{$local_part}wildlsearch{ALAVETELI_HOME/config/aliases}}
       pipe_transport = alaveteli_mailin_transport
    EOF

Cree `/etc/exim4/conf.d/transport/04_alaveteli`, que define las propiedades de la rita de transporte `transport` que entregará el correo a Alaveteli:

    cat > /etc/exim4/conf.d/transport/04_alaveteli <<'EOF'
    alaveteli_mailin_transport:
       driver = pipe
       command = $address_pipe ${lc:$local_part}
       current_directory = ALAVETELI_HOME
       home_directory = ALAVETELI_HOME
       user = ALAVETELI_USER
       group = ALAVETELI_USER
    EOF


<div class="attention-box">
  Este manual presupone que ha definido <a href="/docs/customising/config/#incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a> como <code>foi+</code> en <code>config/general.yml</code>.
</div>

Cree el archivo `config/aliases` que el `router` `alaveteli_request` de Exim obtendrá. Este archivo redirige el correo desde direcciones especiales a `script/mailin` y al usuario `backupfoi`.

    cat > /var/www/alaveteli/config/aliases <<'EOF'
    ^foi\\+.*: "|/var/www/alaveteli/script/mailin", backupfoi
    EOF

_Nota:_ Sustituya `/var/www/alaveteli` con la ruta correcta de Alaveteli, si es necesario.

#### Defina sus grupos de correo de destinatarios de contacto

Para definir grupos de destinatarios de las direcciones de correo `team@` y `user-support@` de su dominio, añada registros de alias para ellos en `/var/www/alaveteli/config/aliases`:

    cat >> /var/www/alaveteli/config/aliases <<EOF
    team: user@example.com, otheruser@example.com
    user-support: team
    EOF

#### Descarte correo entrante no deseado

Configure Exim para que descarte todos los mensajes enviados a la dirección [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix), cuyo valor predeterminado es `do-not-reply-to-this-address`.

    cat >> /var/www/alaveteli/config/aliases <<EOF
    # Utilizamos esta opción como campo remitente para algunos mensajes 
	# en los que no nos interesa la confirmación de entrega
    do-not-reply-to-this-address:        :blackhole:
    EOF

_Nota:_ Sustituya `/var/www/alaveteli` con la ruta correcta de Alaveteli, si es necesario.

#### Filtre los mensajes entrantes hacia direcciones de administración

Puede utilizar la [gestión de rebotado automática]({{ page.baseurl }}/docs/installing/email/#gestin-de-rebotado-automtico-opcional) de Alaveteli para filtrar mensajes rebotados enviados a [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email)
y a [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email).

<div class="attention-box">
Este manual presupone que ha configurado lo siguiente en <code>config/general.yml</code>:

  <ul>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#track_sender_email">TRACK_SENDER_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a>: <code>team@example.com</code></li>
  </ul>

Modifique los siguientes ejemplos con las direcciones que haya configurado.
</div>

Modifique la línea `user-support` ubicada en `/var/www/alaveteli/config/aliases`:

    user-support:     |/var/www/alaveteli/script/handle-mail-replies

#### Registro

Deberá indicar a Alaveteli dónde se almacenan los archivos de registro y que se hallan en formato Exim. Actualice [`MTA_LOG_PATH`]({{ page.baseurl }}/docs/customising/config/#mta_log_path) y [`MTA_LOG_TYPE`]({{ page.baseurl }}/docs/customising/config/#mta_log_type) en `config/general.yml`:

    MTA_LOG_PATH: '/var/log/exim4/exim-mainlog-*'
    MTA_LOG_TYPE: 'exim'


#### Aplique los cambios en Exim

Finalmente, ejecute los comandos:

    update-exim4.conf
    service exim4 restart

Si existe el archivo `/etc/exim4/exim4.conf`, `update-exim4.conf`
silenciosamente no hará nada. Algunas distribuciones incluyen este archivo. Si
es su caso, necesitará eliminarlo o renombrarlo antes de ejecutar `update-exim4.conf`.


#### Solución de problemas (Exim)

Para probar la entrega de correo, ejecute como usuario con permisos (sustituyendo `example.com` por su nombre de dominio):

    exim4 -bt foi+request-1234@example.com

Este comando debería indicarle qué routers están siendo procesados. Debería mostrarse algo similar a:

    $ exim4 -bt foi+request-1234@example.com
    R: alaveteli for foi+request-1234@example.com
    foi+request-1234@example.com -> |/var/www/alaveteli/script/mailin
      transport = alaveteli_mailin_transport
    R: alaveteli for backupfoi@your.machine.name
    R: system_aliases for backupfoi@your.machine.name
    R: userforward for backupfoi@your.machine.name
    R: procmail for backupfoi@your.machine.name
    R: maildrop for backupfoi@your.machine.name
    R: lowuid_aliases for backupfoi@your.machine.name (UID 1001)
    R: local_user for backupfoi@your.machine.name
    backupfoi@your.machine.name
        <-- foi+request-1234@example.com
      router = local_user, transport = mail_spool

Esta información indica que la parte encargada del redireccionamiento (que hace que los correos hacia
`foi\+.*@example.com` se reenvíen al script `mailin` de Alaveteli y a la cuenta
local de copia de seguridad) está funcionando. Puede probar el redireccionamiento
de los mensajes rebotados del mismo modo:

    exim4 -bt user-support@example.com
    R: alaveteli for user-support@example.com
    user-support@example.com -> |/var/www/alaveteli/script/handle-mail-replies
      transport = alaveteli_mailin_transport

Si los correos no son recibidos por su instalación de Alaveteli, encontrará más consejos sobre
errores de correo entrante en la siguiente sección. También existe una
fantástica [hoja de referencia de Exim](http://bradthemad.org/tech/notes/exim_cheatsheet.php) 
en línea, que puede resultarle útil.

## Solución de problemas generales de correo

Primero necesita comprobar si su MTA está entregando los correos entrantes
correspondientes al comando `script/mailin`. Existen varios formas de
configurar su MTA para que lo haga. Hemos documentado una forma de hacerlo
[en Exim]({{ page.baseurl }}/docs/installing/email/#configuracin-de-ejemplo-con-exim4), incluyendo [un comando que puede utilizar]({{ page.baseurl }}/docs/installing/email/#solucin-de-problemas-exim) 
para comprobar que el redireccionamiento del correo está configurado correctamente. 
También hemos documentado una forma de configurar [Postfix]({{ page.baseurl }}/docs/installing/email/#configuracin-de-ejemplo-con-postfix), con un [comando de depuración]({{ page.baseurl }}/docs/installing/email/#solucin-de-problemas-postfix) similar.

En segundo lugar necesitará probar que el propio script de correo está funcionando
correctamente mediante su ejecución desde la línea de comando. Para ello, encuentre
una dirección "To" válida para una solicitud en su sistema. Puede hacer esto a través
de la interfaz de administración de su sitio o desde la línea de comando, de este modo:

    $ ./script/console
    Loading development environment (Rails 2.3.14)
    >> InfoRequest.find_by_url_title("why_do_you_have_such_a_fancy_dog").incoming_email
    => "request-101-50929748@localhost"

Ahora tome el origen de un correo válido (hay algunos correos de muestra en
`spec/fixtures/files/`), edite la cabecera `To:` para que concuerde con dicha dirección
y después rediríjalo a través del script de correo. Un código de salida distinto de 
cero significa que se ha producido un error. Por ejemplo:

    $ cp spec/fixtures/files/incoming-request-plain.email /tmp/
    $ perl -pi -e 's/^To:.*/To: <request-101-50929748@localhost>/' /tmp/incoming-request-plain.email
    $ ./script/mailin < /tmp/incoming-request-plain.email
    $ echo $?
    75

El script `mailin` envía por correo los detalles de todo error a
`CONTACT_EMAIL` (definido en el archivo `general.yml`). Un problema común
consiste en que el usuario que ejecuta el MTA to tiene permisos de escritura en
`files/raw_emails/`.

Si todo parece correcto a nivel local, deberá comprobar también desde otro ordenador
conectado a internet que el servidor DNS para su dominio indica que su servidor
de Alaveteli está gestionando el correo y que su servidor está recibiendo correo
en el puerto 25. El siguiente comando es una consulta para preguntar qué servidor
está gestionando el correo para el dominio `example.com`, que recibe como respuesta 
`mail.example.com`.

    $ host -t mx example.com
    example.com mail is handled by 5 mail.example.com.

Este comando siguiente prueba la conexión con el puerto 25, el puerto SMTP
estándar, en `mail.example.com`, y es rechazada.

    $ telnet mail.example.com 25
    Trying 10.10.10.30...
    telnet: connect to address 10.10.10.30: Connection refused

La siguiente transcripción muestra una conexión satisfactoria en la que el servidor
acepta el correo para su entrega (los comandos que debe introducir se indican con
el carácter `$`):

    $ telnet 10.10.10.30 25
    Trying 10.10.10.30...
    Connected to 10.10.10.30.
    Escape character is '^]'.
    220 mail.example.com ESMTP Exim 4.80 Tue, 12 Aug 2014 11:10:39 +0000
    $ HELO X
    250 mail.example.com Hello X [10.10.10.1]
    $ MAIL FROM: <test@local.domain>
    250 OK
    $ RCPT TO:<foi+request-1234@example.com>
    250 Accepted
    $ DATA
    354 Enter message, ending with "." on a line by itself
    $ Subject: Test
    $
    $ Este es un correo de prueba.
    $ .
    250 OK id=1XHA03-0001Vx-Qn
    QUIT

