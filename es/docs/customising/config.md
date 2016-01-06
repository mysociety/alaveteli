---
layout: es/page
title: Configuración
---

# Configuración de Alaveteli

<p class="lead">
    Puede controlar numerosos detalles sobre el aspecto y el comportamiento de Alaveteli con tan solo
    modificar los ajustes de configuración.
</p>

## Archivo de configuración general

El código de Alaveteli incluye un ejemplo de archivo de configuración: `config/general.yml-example`.

Como parte del [proceso de instalación]({{ page.baseurl }}/docs/installing/ ), el
archivo de ejemplo se copia en `config/general.yml`. **Debe** editar este archivo para
adaptarlo a sus necesidades.

Los ajustes predeterminados para los ejemplos de páginas frontales están diseñados para trabajar con
los datos de prueba incluidos en Alaveteli. Al disponer de datos reales debe editarlos.

También existen [otros archivos de configuración](#other-config) para aspectos específicos de Alaveteli.


## Ajustes de configuración por tema

Los siguientes ajustes de configuración pueden modificarse en `config/general.yml`.
Al editar este archivo, recuerde que debe hacerlo con la <a href="http://yaml.org">sintaxis de YAML</a>.
No es complicado, pero (especialmente al editar un listado) debe prestar atención en mantener el
sangrado de texto correcto. Si tiene dudas, consulte los ejemplos que se hallan en el archivo
y no utilice tabulaciones.

### Apariencia y comportamiento general del sitio:

<code><a href="#site_name">SITE_NAME</a></code>
<br> <code><a href="#domain">DOMAIN</a></code>
<br> <code><a href="#force_ssl">FORCE_SSL</a></code>
<br> <code><a href="#force_registration_on_new_request">FORCE_REGISTRATION_ON_NEW_REQUEST</a></code>
<br> <code><a href="#theme_urls">THEME_URLS</a></code>
<br> <code><a href="#theme_branch">THEME_BRANCH</a></code>
<br> <code><a href="#frontpage_publicbody_examples">FRONTPAGE_PUBLICBODY_EXAMPLES</a></code>
<br> <code><a href="#public_body_statistics_page">PUBLIC_BODY_STATISTICS_PAGE</a></code>
<br> <code><a href="#minimum_requests_for_statistics">MINIMUM_REQUESTS_FOR_STATISTICS</a></code>
<br> <code><a href="#responsive_styling">RESPONSIVE_STYLING</a></code>

### Estado del sitio:

<code><a href="#read_only">READ_ONLY</a></code>
<br> <code><a href="#staging_site">STAGING_SITE</a></code>

### Localización e internacionalización:

<code><a href="#iso_country_code">ISO_COUNTRY_CODE</a></code>
<br> <code><a href="#time_zone">TIME_ZONE</a></code>
<br> <code><a href="#available_locales">AVAILABLE_LOCALES</a></code>
<br> <code><a href="#default_locale">DEFAULT_LOCALE</a></code>
<br> <code><a href="#use_default_browser_language">USE_DEFAULT_BROWSER_LANGUAGE</a></code>
<br> <code><a href="#include_default_locale_in_urls">INCLUDE_DEFAULT_LOCALE_IN_URLS</a></code>

### Definición de «late» (fuera de plazo):

<code><a href="#reply_late_after_days">REPLY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#reply_very_late_after_days">REPLY_VERY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#working_or_calendar_days">WORKING_OR_CALENDAR_DAYS</a></code>

### Acceso a la interfaz de administración:

<code><a href="#admin_username">ADMIN_USERNAME</a></code>
<br> <code><a href="#admin_password">ADMIN_PASSWORD</a></code>
<br> <code><a href="#disable_emergency_user">DISABLE_EMERGENCY_USER</a></code>
<br> <code><a href="#skip_admin_auth">SKIP_ADMIN_AUTH</a></code>

### Gestión del correo electrónico:

<code><a href="#incoming_email_domain">INCOMING_EMAIL_DOMAIN</a></code>
<br> <code><a href="#incoming_email_prefix">INCOMING_EMAIL_PREFIX</a></code>
<br> <code><a href="#incoming_email_secret">INCOMING_EMAIL_SECRET</a></code>
<br> <code><a href="#blackhole_prefix">BLACKHOLE_PREFIX</a></code>
<br> <code><a href="#contact_email">CONTACT_EMAIL</a></code>
<br> <code><a href="#contact_name">CONTACT_NAME</a></code>
<br> <code><a href="#track_sender_email">TRACK_SENDER_EMAIL</a></code>
<br> <code><a href="#track_sender_name">TRACK_SENDER_NAME</a></code>
<br> <code><a href="#raw_emails_location">RAW_EMAILS_LOCATION</a></code>
<br> <code><a href="#exception_notifications_from">EXCEPTION_NOTIFICATIONS_FROM</a></code>
<br> <code><a href="#exception_notifications_to">EXCEPTION_NOTIFICATIONS_TO</a></code>
<br> <code><a href="#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a></code>
<br> <code><a href="#mta_log_path">MTA_LOG_PATH</a></code>
<br> <code><a href="#mta_log_type">MTA_LOG_TYPE</a></code>

### Administración general (claves, rutas, servicios de soporte del sistema):

<code><a href="#cookie_store_session_secret">COOKIE_STORE_SESSION_SECRET</a></code>
<br> <code><a href="#recaptcha_public_key">RECAPTCHA_PUBLIC_KEY</a></code>
<br> <code><a href="#recaptcha_private_key">RECAPTCHA_PRIVATE_KEY</a></code>
<br> <code><a href="#gaze_url">GAZE_URL</a></code>
<br> <code><a href="#ga_code">GA_CODE</a></code> (GA=Google Analytics)
<br> <code><a href="#utility_search_path">UTILITY_SEARCH_PATH</a></code>
<br> <code><a href="#shared_files_path">SHARED_FILES_PATH</a></code>
<br> <code><a href="#shared_files">SHARED_FILES</a></code>
<br> <code><a href="#shared_directories">SHARED_DIRECTORIES</a></code>

### Disparadores y ajustes de comportamiento:

<code><a href="#new_response_reminder_after_days">NEW_RESPONSE_REMINDER_AFTER_DAYS</a></code>
<br> <code><a href="#max_requests_per_user_per_day">MAX_REQUESTS_PER_USER_PER_DAY</a></code>
<br> <code><a href="#override_all_public_body_request_emails">OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS</a></code>
<br> <code><a href="#allow_batch_requests">ALLOW_BATCH_REQUESTS</a></code>
<br> <code><a href="#public_body_list_fallback_to_default_locale">PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE</a></code>
<br> <code><a href="#cache_fragments">CACHE_FRAGMENTS</a></code>

### Servicios públicos externos:

<code><a href="#blog_feed">BLOG_FEED</a></code>
<br> <code><a href="#twitter_username">TWITTER_USERNAME</a></code>
<br> <code><a href="#twitter_widget_id">TWITTER_WIDGET_ID</a></code>
<br> <code><a href="#donation_url">DONATION_URL</a></code>

### Casos especiales o trabajo de desarrollo:

<code><a href="#debug_record_memory">DEBUG_RECORD_MEMORY</a></code>
<br> <code><a href="#varnish_host">VARNISH_HOST</a></code>
<br> <code><a href="#use_mailcatcher_in_development">USE_MAILCATCHER_IN_DEVELOPMENT</a></code>
<br> <code><a href="#use_ghostscript_compression">USE_GHOSTSCRIPT_COMPRESSION</a></code>
<br> <code><a href="#html_to_pdf_command">HTML_TO_PDF_COMMAND</a></code>


---

## Todos los ajustes generales


<dl class="glossary">

  <dt>
    <a name="site_name"><code>SITE_NAME</code></a>
  </dt>
  <dd>
    <strong>SITE_NAME</strong> aparece en diversos lugares del sitio.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>SITE_NAME: 'Alaveteli'</code>
        </li>
        <li>
            <code>SITE_NAME: 'WhatDoTheyKnow'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="domain"><code>DOMAIN</code></a>
  </dt>
  <dd>
      Dominio utilizado en direcciones URL generadas por scripts (por ejemplo, para incluirse en algunos correos).
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>DOMAIN: '127.0.0.1:3000'</code>
        </li>
        <li>
            <code>DOMAIN: 'www.ejemplo.com'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="force_ssl"><code>FORCE_SSL</code></a>
  </dt>
  <dd>
      Si tiene asignado el valor «true», fuerza a todo el mundo (dentro del entorno de producción) a utilizar conexiones cifradas
      (https), redirigiendo las conexiones sin cifrado. Esta característia está <strong>altamente
      recomendada</strong> para que las credenciales no puedan ser interceptadas por personas malintencionadas.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>FORCE_SSL: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="iso_country_code"><code>ISO_COUNTRY_CODE</code></a>
  </dt>
  <dd>
    <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">Código ISO nacional</a>
    del país donde se implementa su sitio basado en Alaveteli.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>ISO_COUNTRY_CODE: GB</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="time_zone"><code>TIME_ZONE</code></a>
  </dt>
  <dd>
   Esta es la <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">zona horaria</a>
   que utiliza Alaveteli para mostrar la fecha y la hora.
   Si no se configura, utiliza UTC por defecto.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>TIME_ZONE: Australia/Sydney</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blog_feed"><code>BLOG_FEED</code></a>
  </dt>
  <dd>
    Estas transmisiones se muestran consecuentemente en la página del blog de Alaveteli: <!-- TODO -->
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>BLOG_FEED: 'https://www.mysociety.org/category/projects/whatdotheyknow/feed/'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="twitter_username"><code>TWITTER_USERNAME</code></a>
    <a name="twitter_widget_id"><code>TWITTER_WIDGET_ID</code></a>
  </dt>
  <dd>
    Si desea mostrar las novedades de Twitter en la página del blog, introduzca el identificador y el código de usuario para el widget.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>TWITTER_USERNAME: WhatDoTheyKnow</code>
        </li>
        <li>
            <code>TWITTER_WIDGET_ID: '833549204689320031'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="available_locales"><code>AVAILABLE_LOCALES</code></a> y
    <a name="default_locale"><code>DEFAULT_LOCALE</code></a>
  </dt>
  <dd>
    <strong>AVAILABLE_LOCALES</strong> lista todas las localizaciones que desea soportar en su sitio.
    Si hay más de una, utilice espacios para separar las entradas.
    Defina una de las localizaciones como predeterminada con la variable <strong>DEFAULT_LOCALE</strong>.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>AVAILABLE_LOCALES: 'en es'</code>
        </li>
        <li>
            <code>DEFAULT_LOCALE: 'en'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="use_default_browser_language"><code>USE_DEFAULT_BROWSER_LANGUAGE</code></a>
  </dt>
  <dd>
      ¿Desea que Alaveteli intente utiliza el idioma predeterminado del navegador del usuario?
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>USE_DEFAULT_BROWSER_LANGUAGE: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="include_default_locale_in_urls"><code>INCLUDE_DEFAULT_LOCALE_IN_URLS</code></a>
  </dt>
  <dd>
    Normalmente Alaveteli incluirá la localización en sus direcciones URL, de este modo:
    <code>www.ejemplo.com/en/body/list/all</code>. Si no desea este comportamiento
    cuando se trate de la localización por defecto, asigne a
    <strong>INCLUDE_DEFAULT_LOCALE_IN_URLS</strong> el valor «false».
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>INCLUDE_DEFAULT_LOCALE_IN_URLS: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="reply_late_after_days"><code>REPLY_LATE_AFTER_DAYS</code></a><br>
    <a name="reply_very_late_after_days"><code>REPLY_VERY_LATE_AFTER_DAYS</code></a><br>
    <a name="working_or_calendar_days"><code>WORKING_OR_CALENDAR_DAYS</code></a>
  </dt>
  <dd>
        Las variables <strong>REPLY...AFTER_DAYS</strong> definen cuántos días deben pasar
        antes de que la respuesta a una solicitud se considere oficialmente <em>late</em> (fuera de plazo).
        La variable <strong>WORKING_OR_CALENDAR_DAYS</strong> puede contener los valores «working» (predeterminado)
        o «calendar», que determinan qué días se incluyen en el contador.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>REPLY_LATE_AFTER_DAYS: 20</code>
        </li>
        <li>
            <code>REPLY_VERY_LATE_AFTER_DAYS: 40</code>
        </li>
        <li>
          <code>WORKING_OR_CALENDAR_DAYS: working</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="frontpage_publicbody_examples"><code>FRONTPAGE_PUBLICBODY_EXAMPLES</code></a>
  </dt>
  <dd>
    Especifique qué organismos públicos desea listar como ejemplo en la página de inicio
    utilizando su nombre corto, <code>short_name</code>.
    Si desea mostrar más de uno, sepárelos por punto y coma.
    Comente este apartado si desea que se genere de forma automática.
    <p>
      <strong>Advertencia</strong>: esta opción es lenta, ¡no la utilice en producción!
    </p>
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>FRONTPAGE_PUBLICBODY_EXAMPLES: 'tgq'</code>
        </li>
        <li>
            <code>FRONTPAGE_PUBLICBODY_EXAMPLES: 'tgq;foo;bar'</code>
        </li>
        <li>
            <code># FRONTPAGE_PUBLICBODY_EXAMPLES: </code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_urls"><code>THEME_URLS</code></a>
  </dt>
  <dd>
    Direcciones URL de <a href="{{ page.baseurl }}/docs/customising/themes/">temas</a> para descargar y utilizar
    (al ejecutar el script <code>rails-post-deploy</code>). Las primeras plantillas de la lista tienen
    mayor prioridad que las siguientes.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <pre>
THEME_URLS:
 - 'git://github.com/mysociety/alavetelitheme.git'
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_branch"><code>THEME_BRANCH</code></a>
  </dt>
  <dd>
    Cuando el script <code>rails-post-deploy</code> instale los <a href="{{ page.baseurl }}/docs/customising/themes/">temas</a>,
    probará primero la rama de temas, pero solo si ha asignado a <code>THEME_BRANCH</code>
    el valor «true». Si la rama no existe, retornará al uso de una versión etiquetada específica
    en su versión instalada de Alaveteli y, en caso de que no exista ninguna, retornará a
    la maestra, <code>master</code>.
    <p>
        El tema por defecto es el denominado «Alaveteli». Se instala automáticamente cuando se ejecuta
        <code>rails-post-deploy</code>.
    </p>
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>THEME_BRANCH: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="force_registration_on_new_request"><code>FORCE_REGISTRATION_ON_NEW_REQUEST</code></a>
  </dt>
  <dd>
    ¿Necesitan los usuarios iniciar sesión para comenzar un nuevo proceso de solicitud?
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>FORCE_REGISTRATION_ON_NEW_REQUEST: false</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="incoming_email_domain"><code>INCOMING_EMAIL_DOMAIN</code></a>
  </dt>
  <dd>
    Su dominio de correo electrónico para recibir correo entrante. Consulte también la <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">gestión de correo de Alaveteli</a>.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_DOMAIN: 'localhost'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_DOMAIN: 'foifa.com'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a>
  </dt>
  <dd>
      Un prefijo opcional para ayudarle a distinguir las solicitudes de información pública. Consulte también la <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">gestión de correo de Alaveteli</a>.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_PREFIX: ''</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_PREFIX: 'foi+'</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="incoming_email_secret"><code>INCOMING_EMAIL_SECRET</code></a>
  </dt>
  <dd>
     Utilizada para almacenar el código hash en la dirección de correo de la solicitud.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_SECRET: '11ae 4e3b 70ff c001 3682 4a51 e86d ef5f'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blackhole_prefix"><code>BLACKHOLE_PREFIX</code></a>
  </dt>
  <dd>
      Utilizada como campo remitente «from» en el dominio de correo entrante para casos en que no se tienen en cuenta los posibles errores.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>BLACKHOLE_PREFIX: 'do-not-reply-to-this-address'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="admin_username"><code>ADMIN_USERNAME</code></a>
    y
    <a name="admin_password"><code>ADMIN_PASSWORD</code></a>
    <br>
    <a name="disable_emergency_user"><code>DISABLE_EMERGENCY_USER</code></a>
  </dt>
  <dd>
      Detalles sobre el
      <a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">usuario de emergencia</a>.
      <p>
        Estas opciones resultan útiles para crear los usuarios administradores iniciales de su sitio:
        <ul>
          <li>Cree un nuevo usuario (mediante el registro común del sitio).</li>
          <li>Inicie sesión con el usuario de emergencia.</li>
          <li>Ascienda la nueva cuenta a administrador.</li>
          <li>Deshabilite el usuario de emergencia.</li>
        </ul>
      </p>
      <p>
        Para obtener detalles sobre este proceso, consulte la
        <a href="{{ page.baseurl }}/docs/installing/next_steps/#cree-una-cuenta-de-administrador-superusuario">creación
          de cuentas de superusuario</a>.
      </p>
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>ADMIN_USERNAME: 'adminxxxx'</code>
        </li>
        <li>
            <code>ADMIN_PASSWORD: 'passwordx'</code>
        </li>
        <li>
            <code>DISABLE_EMERGENCY_USER: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="skip_admin_auth"><code>SKIP_ADMIN_AUTH</code></a>
  </dt>
  <dd>
      Asigne a esta variable el valor «true» para que la interfaz de administración sea accesible para usuarios anónimos.
      Evidentemente, esta opción no debe activarse en entornos de producción.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>SKIP_ADMIN_AUTH: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="contact_email"><code>CONTACT_EMAIL</code></a>
      y
    <a name="contact_name"><code>CONTACT_NAME</code></a>
  </dt>
  <dd>
      Detalles del campo del remitente «from» en el correo electrónico. Consulte también la <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">gestión de correo de Alaveteli</a>.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>CONTACT_EMAIL: 'team@example.com'</code>
        </li>
        <li>
            <code>CONTACT_NAME: 'Alaveteli Webmaster'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="track_sender_email"><code>TRACK_SENDER_EMAIL</code></a> y
    <a name="track_sender_name"><code>TRACK_SENDER_NAME</code></a>
  </dt>
  <dd>
      Detalles del campo del remitente «from» para mensajes de seguimiento. Consulte también la <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">gestión de correo de Alaveteli</a>.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>TRACK_SENDER_EMAIL: 'alaveteli@ejemplo.com'</code>
        </li>
        <li>
            <code>TRACK_SENDER_NAME: 'Alaveteli Webmaster'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="raw_emails_location"><code>RAW_EMAILS_LOCATION</code></a>
  </dt>
  <dd>
      Lugar donde se almacenan los datos de tipo raw del correo entrante.
      <strong>¡Asegúrese de hacer copias de seguridad de estos datos!</strong>
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>RAW_EMAILS_LOCATION: 'files/raw_emails'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="cookie_store_session_secret"><code>COOKIE_STORE_SESSION_SECRET</code></a>
  </dt>
  <dd>
     Clave secreta para firmar sesiones cookie_store. Debe ser larga y aleatoria.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>COOKIE_STORE_SESSION_SECRET: 'uIngVC238Jn9NsaQizMNf89pliYmDBFugPjHS2JJmzOp8'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="read_only"><code>READ_ONLY</code></a>
  </dt>
  <dd>
      Si está presente, <strong>READ_ONLY</strong> aplica el modo de solo lectura al sitio
      y utiliza el texto como razón (el párrafo completo). Utilice un usuario de solo lectura
      también en la base de datos, pues solo se verifica en unos pocos lugares evidentes.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            Normalmente <strong>no</strong> deseará que su sitio funcione en
            modo de solo lectura, por lo que deberá dejar <strong>READ_ONLY</strong>
            en blanco.
            <br>
            <code>
                READ_ONLY: ''
            </code>
        </li>
        <li>
            <code>
                READ_ONLY: 'Actualmente el sitio no acepta solicitudes porque estamos trasladando el servidor.'
            </code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="staging_site"><code>STAGING_SITE</code></a>
  </dt>
  <dd>
     ¿Es este un servidor de
     <a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">pruebas</a> o de
     <a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">desarrollo</a>?
     Si no es así, se trata de un servidor real de <a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">producción</a>.
	 Esta opción controla si el script <code>rails-post-deploy</code>
     debe o no crear el archivo <code>config/rails_env.rb</code> para forzar
     Rails en el entorno de producción.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            Para servidores de pruebas o de desarrollo:
            <p>
              <code>STAGING_SITE: 1</code>
            </p>
        </li>
        <li>
            Para producción:
            <p>
              <code>STAGING_SITE: 0</code>
            </p>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
      <a name="recaptcha_public_key"><code>RECAPTCHA_PUBLIC_KEY</code></a> y
      <a name="recaptcha_private_key"><code>RECAPTCHA_PRIVATE_KEY</code></a>
  </dt>
  <dd>
     Recaptcha, para la detección de humanos. Obtenga aquí las claves:
     <a href="http://recaptcha.net/whyrecaptcha.html">http://recaptcha.net/whyrecaptcha.html</a>

    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>RECAPTCHA_PUBLIC_KEY: '7HoPjGBBBBBBBBBkmj78HF9PjjaisQ893'</code>
        </li>
        <li>
            <code>RECAPTCHA_PRIVATE_KEY: '7HjPjGBBBBBCBBBpuTy8a33sgnGG7A'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="new_response_reminder_after_days"><code>NEW_RESPONSE_REMINDER_AFTER_DAYS</code></a>
  </dt>
  <dd>
       Número de días tras los cuales se enviará un recordatorio de respuesta «new response reminder».
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>NEW_RESPONSE_REMINDER_AFTER_DAYS: [3, 10, 24]</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="debug_record_memory"><code>DEBUG_RECORD_MEMORY</code></a>
  </dt>
  <dd>
     Para depurar problemas de memoria. Si se le asigna el valor «true», Alaveteli registra
     los aumentos de uso de memoria del proceso de Ruby debido a la
     solicitud (solamente en Linux).  Como Ruby nunca devuelve memoria al sistema operativo,
     si el proceso existente había dado servicio previamente a una solicitud de mayor tamaño,
     no se mostrará ningún consumo para la siguiente.

    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>DEBUG_RECORD_MEMORY: false</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="use_ghostscript_compression"><code>USE_GHOSTSCRIPT_COMPRESSION</code></a>
  </dt>
  <dd>
    Actualmente predeterminamos el uso de pdftk para comprimir archivos en formato PDF.
    Opcionalmente, puede probar Ghostscript, que debería llevar a cabo un mejor trabajo
    de compresión. Algunas versiones de pdftk generan errores respecto a la compresión,
    en cuyo caso Alaveteli no recomprime los archivos PDF
    y registra un mensaje de advertencia, «Unable to compress PDF», un motivo más
    para probar esta opción.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>USE_GHOSTSCRIPT_COMPRESSION: true</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="gaze_url"><code>GAZE_URL</code></a>
  </dt>
  <dd>
      Alateveli utiliza el servicio geográfico de mySociety para determinar el país de la dirección
      IP recibida (así podemos sugerir un sitio basado en Alaveteli del país correspondiente, si existe alguno).
      Normalmente no es necesario modificar esta opción.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>GAZE_URL: http://gaze.mysociety.org</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="forward_nonbounce_responses_to"><code>FORWARD_NONBOUNCE_RESPONSES_TO</code></a>
  </dt>
  <dd>
     Dirección de correo electrónico a la que se dirigen las respuestas no rebotadas. Consulte también la <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">gestión de correo de Alaveteli</a>.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>FORWARD_NONBOUNCE_RESPONSES_TO: soporte-usuario@ejemplo.com</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="html_to_pdf_command"><code>HTML_TO_PDF_COMMAND</code></a>
  </dt>
  <dd>
    Ruta hacia un programa que convierte una página HTML de un archivo a PDF. Debería
    recibir dos parámetros: la dirección URL y la ruta del archivo de salida.
    Se recomienda una version binaria estática de <a href="http://wkhtmltopdf.org">wkhtmltopdf</a>.
    Si el comando no está presente, se generará en su lugar una versión de texto.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>HTML_TO_PDF_COMMAND: /usr/local/bin/wkhtmltopdf-amd64</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="exception_notifications_from"><code>EXCEPTION_NOTIFICATIONS_FROM</code></a> y
    <a name="exception_notifications_to"><code>EXCEPTION_NOTIFICATIONS_TO</code></a>
  </dt>
  <dd>
      Direcciones de correo utilizadas para enviar notificaciones de excepciones.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <pre>
EXCEPTION_NOTIFICATIONS_FROM: no-responda-a-esta-direccion@ejemplo.com

EXCEPTION_NOTIFICATIONS_TO:
 - robin@ejemplo.com
 - seb@ejemplo.com
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="max_requests_per_user_per_day"><code>MAX_REQUESTS_PER_USER_PER_DAY</code></a>
  </dt>
  <dd>
      Este límite puede desactivarse por usuario a través de la interfaz de administración.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>MAX_REQUESTS_PER_USER_PER_DAY: 6</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="varnish_host"><code>VARNISH_HOST</code></a>
  </dt>
  <dd>
      Si su sitio funciona con Varnish,
	  puede activar esta opción para
	  averiguar dónde enviar las solicitudes
	  de purga. En caso contrario, no
	  la configure.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>VARNISH_HOST: null</code>
        </li>
        <li>
            <code>VARNISH_HOST: localhost</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="ga_code"><code>GA_CODE</code> (GA=Google Analytics)</a>
  </dt>
  <dd>
      Añadir aquí un valor activará Google Analytics en todas las páginas que no pertenezcan a la administración para todos los usuarios que no sean administradores.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>GA_CODE: ''</code>
        </li>
        <li>
            <code>GA_CODE: 'AB-8222142-14'</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="override_all_public_body_request_emails"><code>OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS</code></a>
  </dt>
  <dd>
    Utilice esta opción si desea sobrescribir <strong>todas</strong> las direcciones de correo de solicitudes para organismos públicos
    con su propia dirección de correo, para que los mensajes de solicitudes que normalmente se dirigirían a los organismos
    públicos se dirijan a usted en su lugar.
    Esta opción resulta práctica en el servidor de pruebas para poder reproducir el proceso completo de envío de solicitudes
    si remitir correos a ninguna autoridad real.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <code>OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS: test-email@foo.com</code>
        </li>
        <li>
            Si no le interesa este comportamiento, comente la opción:
            <br>
            <code># OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS:</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="utility_search_path"><code>UTILITY_SEARCH_PATH</code></a>
  </dt>
  <dd>
      Ruta de búsqueda para utilidades externas de línea de comando (como pdftohtml, pdftk y unrtf).
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>UTILITY_SEARCH_PATH: ["/usr/bin", "/usr/local/bin"]</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="mta_log_path"><code>MTA_LOG_PATH</code></a>
  </dt>
  <dd>
      Ruta hacia sus archivos de registro de exim o postfix que serán absorbidos por
      <code>script/load-mail-server-logs</code>.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>MTA_LOG_PATH: '/var/log/exim4/exim-mainlog-*'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta_log_type"><code>MTA_LOG_TYPE</code></a>
  </dt>
  <dd>
      ¿Utiliza «exim» o «postfix» para su servidor de correo (MTA)?

    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>MTA_LOG_TYPE: "exim"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="donation_url"><code>DONATION_URL</code></a>
  </dt>
  <dd>
      URL donde las personas pueden donar dinero a la organización que gestiona el sitio. Si se configura,
      se incluirá en el mensaje que ven los usuarios cuando su solicitud tiene resultados satisfactorios.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>DONATION_URL: "https://www.mysociety.org/donate/"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="public_body_statistics_page"><code>PUBLIC_BODY_STATISTICS_PAGE</code></a> y
    <a name="minimum_requests_for_statistics"><code>MINIMUM_REQUESTS_FOR_STATISTICS</code></a>
  </dt>
  <dd>
      Si a <strong>PUBLIC_BODY_STATISTICS_PAGE</strong> se le asigna el valor «true», Alaveteli creará
      una página de estadísticas sobre el comportamiento de los organismos públicos (que puede consultar en
      <code>/body_statistics</code>).
      La página solo considerará los organismos públicos que hayan recibido al menos el número de solicitudes
      definido en <strong>MINIMUM_REQUESTS_FOR_STATISTICS</strong>.

    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>PUBLIC_BODY_STATISTICS_PAGE: false</code>
        </li>
        <li>
            <code>MINIMUM_REQUESTS_FOR_STATISTICS: 50</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="public_body_list_fallback_to_default_locale"><code>PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE</code></a>
  </dt>
  <dd>
     Si desea que la página del listado de organismos públicos incluya autoridades que no disponen de traducción
     para la localización actual (pero que sí disponen de traducción para la localización predeterminada), asigne el valor «true» a esta variable.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE: false</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="use_mailcatcher_in_development"><code>USE_MAILCATCHER_IN_DEVELOPMENT</code></a>
  </dt>
  <dd>
      <!-- TODO check mailcatcher URL -->
     Si se el asigna el valor «true», durante la fase de desarrollo, intente enviar correo por SMTP al puerto
     1025 (puerto predeterminado de escucha de <a href="http://mailcatcher.me">mailcatcher</a>):
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>USE_MAILCATCHER_IN_DEVELOPMENT: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="cache_fragments"><code>CACHE_FRAGMENTS</code></a>
  </dt>
  <dd>
      Utilice memcached para almacenar en caché fragmentos de HTML con la finalidad.
      de obtener un mejor rendimiento. Solo tendrá efecto en entornos en los que se
      asigne a <code>config.action_controller.perform_caching</code> el valor «true».

    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>CACHE_FRAGMENTS: true</code>
        </li>
      </ul>
    </div>
  </dd>



  <dt>
    <a name="shared_files_path"><code>SHARED_FILES_PATH</code></a>
  </dt>
  <dd>
     En algunas implementaciones de Alaveteli tal vez desee instalar cada nueva versión
     implementada junto con las anteriores, en cuyo caso ciertos archivos y recursos
     se compartirán entre las diferentes instalaciones.
     Por ejemplo, el directorio de archivos, <code>files</code>, el directorio <code>cache</code>
     y los gráficos generados, tales como <code>public/foi-live-creation.png</code>. Si
     instala Alaveteli con este tipo de configuración, asigne a <strong>SHARED_FILES_PATH</strong>
     el directorio en el que almacena estos archivos. En caso contrario, déjela en blanco.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>SHARED_FILES_PATH: ''</code> <!-- TODO specific example -->
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="shared_files"><code>SHARED_FILES</code></a> y
    <a name="shared_directories"><code>SHARED_DIRECTORIES</code></a>
  </dt>
  <dd>
     Si tiene configurada la variable <strong>SHARED_FILES_PATH</strong>, estas opciones listan
     los archivos y directorios que se comparten, por ejemplo, aquellos hacia los que los scripts
     de despliegue crean enlaces simbólicos desde el repositorio.
    <div class="more-info">
      <p>Ejemplos:</p>
      <ul class="examples">
        <li>
            <pre>
SHARED_FILES:
 - config/database.yml
 - config/general.yml
 - config/rails_env.rb
 - config/newrelic.yml
 - config/httpd.conf
 - public/foi-live-creation.png
 - public/foi-user-use.png
 - config/aliases
            </pre>
        </li>
        <li>
            <pre>
SHARED_DIRECTORIES:
 - files/
 - cache/
 - lib/acts_as_xapian/xapiandbs/
 - vendor/bundle
 - public/assets
            </pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="allow_batch_requests"><code>ALLOW_BATCH_REQUESTS</code></a>
  </dt>
  <dd>
     Permita que algunos usuarios realicen solicitudes en bloque a múltiples autoridades. Una vez
     asignado el valor «true» a esta variable, puede activar las solicitudes en bloque para usuarios
     individuales a través de la página de administración de cada usuario.
    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>ALLOW_BATCH_REQUESTS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="responsive_styling"><code>RESPONSIVE_STYLING</code></a>
  </dt>
  <dd>

     Utilice las plantillas y hojas de estilo de diseño web adaptable en lugar de
     aquellas que solo muestran el sitio con una anchura determinada. Estas hojas
     de estilo son experimentales actualmente, pero se predeterminarán en el futuro.
     Permiten que el sitio se muestre correctamente en dispositivos móviles, así
     como en pantallas de mayor tamaño. Actualmente las hojas de estilos de anchura
     fija se utilizan por defecto.

    <div class="more-info">
      <p>Ejemplo:</p>
      <ul class="examples">
        <li>
            <code>RESPONSIVE_STYLING: true</code>
        </li>
      </ul>
    </div>
  </dd>

</dl>

<a name="other-config"> </a>

## Otros archivos de configuración

Existen otros archivos de configuración para Alaveteli, que puede encontrar en el
directorio `config`. Se presentan en el repositorio de git como archivos `*-example`,
que puede copiar en su correspondiente ubicación.

<dl>
  <dt>
    <strong>database.yml</strong>
  </dt>
  <dd>
    ajustes de base de datos (para Rails)
  </dd>
  <dt>
    <strong>deploy.yml</strong>
  </dt>
  <dd>
    especificaciones de implementación utilizadas por Capistrano
  </dd>
  <dt>
    <strong>httpd.conf, nginx.conf</strong>
  </dt>
  <dd>
    sugerencias de configuración de Apache y Nginx
  </dd>
  <dt>
    <strong>newrelic.yml</strong>
  </dt>
  <dd>
    configuración de análisis
  </dd>
</dl>
