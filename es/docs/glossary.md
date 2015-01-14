---
layout: es/page
title: Glosario
---

Glosario
====================

<p class="lead">
  Glosario de términos de Alaveteli, la plataforma de información pública de mySociety.
</p>

Definiciones
-----------

<ul class="definitions">
  <li><a href="#alaveteli">Alaveteli</a></li>
  <li><a href="#agnostic">imparcial respecto al solicitante</a></li>
  <li><a href="#authority">autoridad</a></li>
  <li><a href="#blackhole">agujero negro</a></li>
  <li><a href="#bounce-message">mensaje rebotado</a></li>
  <li><a href="#capistrano">Capistrano</a></li>
  <li><a href="#censor-rule">norma de censura</a></li>
  <li><a href="#development">servidor de desarrollo</a></li>
  <li><a href="#emergency">usuario de emergencia</a></li>
  <li><a href="#foi">información pública</a></li>
  <li><a href="#git">git</a></li>
  <li><a href="#holding_pen">sala de espera</a></li>
  <li><a href="#newrelic">New Relic</a></li>
  <li><a href="#mta">MTA</a></li>
  <li><a href="#po">archivos .po</a></li>
  <li><a href="#production">servidor de producción</a></li>
  <li><a href="#publish">publicar</a></li>
  <li><a href="#recaptcha">recaptcha</a></li>
  <li><a href="#redact">editar</a></li>
  <li><a href="#regexp">expresión regular</a></li>
  <li><a href="#request">solicitud</a></li>
  <li><a href="#release">actualización</a></li>
  <li><a href="#response">respuesta</a></li>
  <li><a href="#rails">Ruby on Rails</a></li>
  <li><a href="#sass">Sass</a></li>
  <li><a href="#staging">servidor de pruebas</a></li>
  <li><a href="#state">estado</a></li>
  <li><a href="#theme">tema</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="alaveteli">Alaveteli</a>
  </dt>
  <dd>
    <strong>Alaveteli</strong> es el nombre de la plataforma de software de código abierto creada
    por <a href="https://www.mysociety.org">mySociety</a> para enviar,
    gestionar y archivar solicitudes de información pública.
    <p>
      Se construyó a partir del exitoso proyecto de información pública de Reino Unido
      <a href="https://www.whatdotheyknow.com">WhatDoTheyKnow</a>.
      Utilizamos el nombre <em>Alaveteli</em> para distinguir el software
      que sustenta la plataforma respecto de cualquier sitio web específico que la utilice.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          El sitio web de Alaveteli se halla en <a href="http://www.alaveteli.org">www.alaveteli.org</a>.
        </li>
        <li>
          El nombre «Alaveteli» proviene de
          <a href="http://en.wikipedia.org/wiki/Alaveteli,_Finland">Alaveteli, Finlandia,</a>
          donde una vez trabajó
          <a href="http://en.wikipedia.org/wiki/Anders_Chydenius">un antiguo defensor de la información pública</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="agnostic">imparcial respecto al solicitante</a>
  </dt>
  <dd>
    La ley de <a href="#foi" class="glossary__link">información pública</a> normalmente considera que
    las <a href="#response" class="glossary__link">respuestas</a> ofrecidas por las
    <a href="#authority" class="glossary__link">autoridades</a> son <strong>imparciales respecto al solicitante</strong>. Esto significa
    que la respuesta no debería cambiar en nada en relación a <em>quién</em> haya solicitado
    la información. Como consecuencia, la respuesta
    puede <a href="#publish" class="glossary__link">publicarse</a>, ya que en teoría <em>todo el mundo</em>
    podría preguntar lo mismo y, por ley, debería recibir la misma información.
    <p>
      A pesar de ello, sigue siendo bastante común a nivel mundial que las autoridades respondan
      a las solicitudes de información pública de forma privada, en lugar de publicar ellas mismas sus respuestas. Por tanto, una de las
      funciones de Alaveteli consiste en actuar como repositorio público de las respuestas recibidas.
      Esto también sirve para reducir solicitudes duplicadas, pues la respuesta es pública y evita que la pregunta 
      se tenga que repetir de nuevo.
    </p>
  </dd>

  <dt>
    <a name="authority">autoridad</a>
  </dt>
  <dd>
    Llamamos <strong>autoridad</strong> a cualquier organismo, organización,
    departamento o compañía a los que los usuarios pueden enviar <a href="#request" class="glossary__link">solicitudes</a>.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Un administrador puede añadir, editar o eliminar autoridades en el apartado de administración.
        </li>
        <li>
          Las autoridades son habitualmente, aunque no siempre, organismos públicos obligados a responder por la ley local de
          <a href="#foi" class="glossary__link">información pública</a>. A veces se establece un sitio basado en
          Alaveteli en una jurisdicción que aún no cuenta con una ley de información pública. En el Reino Unido
          hemos añadido a nuestro sitio <a href="https://www.whatdotheyknow.com">WhaDoTheyKnow</a> algunas autoridades
          que no están sujetas a la ley de información pública, pero que se han sometido a ella de forma voluntaria
          o creemos que deberían tenerse en cuenta en este ámbito.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blackhole">agujero negro</a>
  </dt>
  <dd>
    Un <strong>agujero negro</strong> es una dirección de correo electrónico que acepta y destruye
    todos los mensajes de correo que recibe. Alaveteli lo utiliza para los mensajes de correo que no 
	admiten respuestas, normalmente generados de forma automática por sistemas de correo.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Utilice la opción de configuración
          <code><a href="{{ page.baseurl }}/docs/customising/config/#blackhole_prefix">BLACKHOLE_PREFIX</a></code>
          para especificar el aspecto de esta dirección de correo.
        </li>
        <li>
          Por otra parte, revise
          <code><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a></code>
          para especificar la dirección que recibirá mensajes de correo de los usuarios (por ejemplo, solicitudes
          de soporte).
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="bounce-message">mensaje rebotado</a>
  </dt>
  <dd>
    Un <strong>mensaje rebotado</strong> es generado automáticamente por un sistema de correo para informar
	al remitente de un mensaje sobre problemas ocurridos en la entrega de dicho mensaje.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          <a href="{{ page.baseurl }}/docs/installing/email">Cómo gestiona el correo Alaveteli</a>.
        </li>
        <li>Página de wikipedia sobre <a href="http://en.wikipedia.org/wiki/Bounce_message">mensajes rebotados</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="capistrano">Capistrano</a>
  </dt>
  <dd>
    <strong>Capistrano</strong> es una herramienta de implementación y automatización en un servidor remoto escrita en Ruby,
    utilizada por el mecanismo opcional de implementación de Alaveteli.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Cómo <a href="{{ page.baseurl }}/docs/installing/deploy/">implementar Alaveteli</a> (y por qué es una buena idea).
        </li>
        <li>
         El <a href="http://capistranorb.com/">sitio web de Capistrano</a> dispone de documentación minuciosa
         sobre esta herramienta.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="censor-rule">norma de censura</a>
  </dt>
  <dd>
    Los administradores de Alaveteli pueden definir <strong>normas de censura</strong> para identificar
    qué partes de las respuestas deberían ser
    <a href="#redact" class="glossary__link">editadas</a>.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte el
          <a href="{{ page.baseurl }}/docs/running/admin_manual/">manual de administrador</a>
          para obtener más información sobre las normas de censura.
        </li>
        <li>
          Las normas de censura pueden simplemente editar texto que concuerde exactamente con
          una frase u oración en particular, así como utilizar
          <a href="#regexp">expresiones regulares</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="development">servidor de desarrollo</a>
  </dt>
  <dd>
    Un <strong>servidor de desarrollo</strong> soporta la ejecución de su sitio basado en Alaveteli 
    para que pueda <a href="{{ page.baseurl }}/docs/customising/">personalizarlo</a>, experimentar
    con distintas opciones y ponerlo a prueba hasta conseguir que desempeñe las funciones deseadas.
    Es diferente de un
    <a href="#production" class="glossary__link">servidor de producción</a>, que es
    visitado por usuarios auténticos y funciona con datos reales, así como de un
    <a href="#staging" class="glossary__link">servidor de pruebas</a>,
    utilizado para probar el código antes de publicarlo.
    <p>
      En el servidor de desarrollo debe asignar a
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      el valor <code>1</code>.
    </p>
  </dd>

  <dt>
    <a name="emergency">usuario de emergencia</a>
  </dt>
  <dd>
    Alaveteli incluye la configuración de un <strong>usuario de emergencia</strong>.
    Esta configuración ofrece un código de usuario y una contraseña para acceder a la página de administración, incluso
    si el usuario no aparece en la base de datos.
    <p>
      Cuando el sistema ha sido arrancado (es decir, cuando se ha utilizado el usuario de emergencia para
      proporcionar a una cuenta de usuario permisos totales de <em>superusuario</em>), el usuario de emergencia
      debe deshabilitarse.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          El código de usuario y la contraseña están definidos en los ajustes de configuración
          <code><a href="{{ page.baseurl }}/docs/customising/config/#admin_username">ADMIN_USERNAME</a></code>
          y 
          <code><a href="{{ page.baseurl }}/docs/customising/config/#admin_password">ADMIN_PASSWORD</a></code>.
        </li>
        <li>
          Si desea consultar un ejemplo de usuario de emergencia, acceda a la
          <a href="{{ page.baseurl }}/docs/installing/next_steps/#cree-una-cuenta-de-administrador-superusuario">creación
            de una cuenta de superusuario</a>.
        </li>
        <li>
          Para desactivar el usuario de emergencia, configure la opción
          <code><a href="{{site.baseurl}}docs/customising/config/#disable_emergency_user">DISABLE_EMERGENCY_USER:</a> true</code>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="foi">Información pública</a>
  </dt>
  <dd>
    Las leyes de <strong>información pública</strong> permiten al público acceder a datos
    almacenados por los gobiernos nacionales. Establecen un proceso legal para el derecho a saber,
    que permite solicitar información guardada por los gobiernos y recibirla de forma
    gratuita por un mínimo coste, salvo excepciones estándar.
    <br>
    <em>[Wikipedia]</em>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Resumen de Wikipedia sobre <a href="http://en.wikipedia.org/wiki/Freedom_of_information_laws_by_country">las leyes de información pública por países</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="git">git</a> (también llamado «github» o «repositorio git»)
  </dt>
  <dd>
    Utilizamos un popular sistema de control de código fuente llamado <strong>git</strong>. Este sistema
    nos ayuda a monitorizar los cambios realizados en el código y también facilita a otras personas
    la duplicación de nuestro software y la colaboración en su elaboración.
    <p>
      El sitio web <a href="https://github.com/mysociety">github.com</a> es un lugar público central 
	  donde está disponible nuestro software. Debido a que se trata de código abierto, puede
      revisarlo (Alaveteli está en su mayoría escrito en el lenguaje de programación
      Ruby) e informar de errores, así como sugerir funcionalidades y otras numerosas características prácticas.
    </p>
    <p>
      El conjunto completo de archivos que forman la plataforma Alaveteli se denomina
      <strong>repositorio git</strong>. Al
      instalar Alaveteli, está clonando nuestro repositorio en su propio
      equipo.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte las <a href="{{ page.baseurl }}/docs/installing/">instrucciones de instalación</a> que clonarán
          el repositorio de Alaveteli.
        </li>
        <li>
          Todo sobre git en el <a
          href="http://git-scm.com">sitio web oficial</a>.
        </li>
        <li>
          Consulte <a href="https://github.com/mysociety">los proyectos de mySociety en
          github</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="holding_pen">sala de espera</a>
  </dt>
  <dd>
    La <strong>sala de espera</strong> es un lugar conceptual donde se almacenan los mensajes
    que no se han podido entregar y necesitan ser revisados por un administrador.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte la información incluida en el <a href="{{ page.baseurl }}/docs/running/admin_manual/">manual de administrador</a>
          sobre cómo gestionar los mensajes de correo ubicados en la sala de espera.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta">MTA</a> (servidor de correo)
  </dt>
  <dd>
    Un <strong>servidor de correo</strong> es un programa que envía y recibe
    correo electrónico. Alaveteli envía correo a nombre de sus usuarios y procesa
    las <a href="#response" class="glossary__link">respuestas</a> que recibe.
    Todos los mensajes pasan por el servidor de correo, que constituye un servicio
	independiente de su sistema.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte estas instrucciones para <a href="{{ page.baseurl }}/docs/installing/email/">configurar su MTA</a>
          (incluye ejemplos para exim4 y postfix, dos de los más comunes)
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="newrelic">New Relic</a>
  </dt>
  <dd>
    Alaveteli puede utilizar la herramienta de monitorización de aplicaciones de <strong>New Relic</strong> para revisar el
    rendimiento de su <a href="#production" class="glossary__link">servidor de producción</a>. Si se halla activado,
    el sitio web de New Relic recopila datos sobre su aplicación, que puede inspeccionar gracias a
    sus herramientas visuales. Sus funcionalidades básicas son gratuitas.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Utilice la opción <code>agent_enabled:</code> del
          archivo de configuración <code>newrelic.yml</code> para activar el análisis de New Relic.
          Consulte las instrucciones de <a href="{{ page.baseurl }}/docs/installing/manual_install/">instalación manual</a>.
        </li>
        <li>
          Consulte también el <a href="https://github.com/newrelic/rpm">repositorio de github</a> y la
          <a href="https://docs.newrelic.com/docs/ruby/">documentación</a> sobre el agente Ruby de New Relic.
        </li>
        <li>
          <a href="http://newrelic.com">Sitio web de New Relic</a>: si tiene este servicio activado,
          puede iniciar sesión para revisar los análisis de rendimiento.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="po">archivo <code>.po</code></a> (y archivo <code>.pot</code>)
  </dt>
  <dd>
    Estos son los archivos requeridos por el mecanismo <em>gettext</em> que Alaveteli utiliza para
    la localización. Un archivo <code>.pot</code> contiene una lista con todas las cadenas
    de texto propias de la aplicación que necesitan ser traducidas. Cada archivo <code>.po</code>
    contiene la correspondencia entre estas cadenas, utilizadas como claves, y sus
    traducciones para un idioma en concreto. La clave se denomina
    <em>msgid</em> y su correspondiente traducción, <em>msgstr</em>.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte la <a href="{{ page.baseurl }}/docs/customising/translation/">traducción de
          Alaveteli</a> para obtener una visión general desde el punto de vista de un traductor.
        </li>
        <li>
          Consulte la <a href="{{ page.baseurl }}/docs/developers/i18n/">internacionalización de
          Alaveteli</a> para acceder a detalles más técnicos.
        </li>
        <li>
          Alaveteli se halla en el sitio web  <a href="https://www.transifex.net/projects/p/alaveteli/">Transifex</a>,
          que permite a los traductores trabajar con Alaveteli en un navegador, sin necesidad de
          preocuparse por su estructura subyacente.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="production">servidor de producción</a>
  </dt>
  <dd>
    Un <strong>servidor de producción</strong> es aquel donde se mantiene en funcionamiento su sitio web basado en Alaveteli
    para usuarios auténticos con datos reales. Es diferente de un
    <a href="#development" class="glossary__link">servidor de desarrollo</a>, que se utiliza para llevar a cabo
    modificaciones de entorno y personalización e intentar que todo funcione correctamente, así como de un
    <a href="#staging" class="glossary__link">servidor de pruebas</a>, utilizado para probar y configurar
    el código ya finalizado antes de su publicación.
    <p>
      Su servidor de producción debe configurarse para funcionar de la forma más eficiente posible. Por
      ejemplo, con la memoria caché activada y la depuración desactivada.
      <a href="#rails" class="glossary__link">Rails</a> cuenta con un «modo de producción», que se encarga de
      ello, solo debe asignar a
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      el valor <code>0</code>. Tenga en cuenta que si <em>modifica</em> esta opción después de la
      implementación, el archivo <code>rails_env.rb</code>, que permite el modo de producción de Rails,
      no se creará hasta que ejecute <code>rails-post-deploy</code>.
    <p>
      Si dispone de un servidor de pruebas, los entornos de sistema de sus servidores de pruebas y de
      producción deberían ser idénticos.
    </p>
    <p>
      En ningún caso debería necesitar editar código directamente en su servidor de producción.
      Le recomendamos encarecidamente el uso del
      <a href="{{ page.baseurl }}/docs/installing/deploy/">mecanismo de implementación</a> de Alaveteli
      (mediante Capistrano) para efectuar cambios en su servidor de producción.
    </p>
  </dd>

  <dt>
    <a name="publish">publicar</a>
  </dt>
  <dd>
    Alaveteli trabaja mediante la <strong>publicación</strong> de las
    <a href="#response" class="glossary__link">respuestas</a> que recibe para las
    <a href="#request" class="glossary__link">solicitudes</a> de
	<a href="#foi" class="glossary__link">información pública</a> enviadas por sus usuarios.
    Para ello procesa los correos electrónicos recibidos y los presenta como páginas
    (una por solicitud) en el sitio. Esto facilita que la gente encuentre, lea, enlace
    y comparta la solicitud y la información proporcionada como respuesta.
  </dd>

  <dt>
    <a name="recaptcha">recaptcha</a>
  </dt>
  <dd>
    El mecanismo <strong>recaptcha</strong> permite detectar a usuarios no humanos,
    como robots automatizados, para evitar que envíen solicitudes de forma automática.
    Requiere que el usuario (humano) identifique un patrón de letras mostrado
    en una imagen, una tarea prácticamente imposible para los robots no humanos.
    Alaveteli utiliza esta herramienta para evitar recibir spam.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Utilice las opciones de configuración
          <code><a href="{{ page.baseurl }}/docs/customising/config/#recaptcha_public_key">RECAPTCHA_PUBLIC_KEY</a></code>
          y
          <code><a href="{{ page.baseurl }}/docs/customising/config/#recaptcha_private_key">RECAPTCHA_PRIVATE_KEY</a></code>
          para configurarlo.
        </li>
        <li>
          Consulte el <a href="http://www.google.com/recaptcha/">sitio de recaptcha</a> para obtener más información.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="redact">editar</a> (o edición)
  </dt>
  <dd>
    Al <strong>editar</strong> se elimina u oculta parte de un mensaje
    para que no pueda leerse, se retira parte de un documento del sitio web.
    <p>
      Esta tarea puede ser necesaria por diversas razones. Por ejemplo, es posible que
      un usuario incluya por error información personal en su solicitud o que una autoridad
      la incluya en su respuesta. También es posible que necesite editar partes de
      solicitudes y respuestas que resulten difamatorias o puedan herir la sensibilidad.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Consulte el
          <a href="{{ page.baseurl }}/docs/running/admin_manual/">manual de administrador</a>
          para obtener más detalles sobre cómo y cuándo es posible que necesite editar información.
        </li>
        <li>
          Puede llevar a cabo la edición exclusivamente de texto con las
          <a href="#censor-rule" class="glossary__link">normas de censura</a> de Alaveteli.
        </li>
        <li>
          Algunos temas son más sencillos de editar que otros (en particular, los archivos PDF
          pueden contener firmas o imágenes difíciles de eliminar de forma parcial).
          El tal caso es posible que necesite eliminar el documento en su totalidad.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="regexp">expresión regular</a>
  </dt>
  <dd>
    Una <strong>expresión regular</strong> es una forma concisa de describir un
    patrón o secuencia de caracteres, letras o palabras. Un administrador encontrará
    prácticas las expresiones regulares cuando necesite definir <a
    href="#censor-rule" class="glossary__link">normas de censura</a>. Por ejemplo, en lugar
    de <a href="#redact" class="glossary__link">editar</a> solamente una frase específica,
    puede describir un conjunto completo de frases <em>similares</em> con una sola
    expresión regular.
    <p>
      Las expresiones regulares pueden resultar complejas, pero también potentes. Si no está
      familiarizado con su uso, es fácil cometer errores. ¡Úselas con precaución!
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Por ejemplo, la expresión regular
          <code>Jo(e|ey|seph)\s+Blogg?s</code> incluiría
          «<code>Joe Bloggs</code>», «<code>Joey Bloggs</code>» y
          «<code>Joseph Bloggs</code>», pero no
          «<code>John Bloggs</code>».
        </li>
        <li>
          Consulte las <a href="http://en.wikibooks.org/wiki/Regular_Expressions"><em>expresiones 
          regulares</em> en wikibooks</a> para obtener más información
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="release">actualización</a> (o gestor de actualizaciones)
  </dt>
  <dd>
    Publicamos nuevas <strong>actualizaciones</strong> de código para Alaveteli siempre que se
    añaden trabajos importantes (nuevas funcionalidades, mejoras, soluciones de errores, etc.) al
    código principal. Las actualizaciones se identifican con una etiqueta, que incluye dos o tres
    números: mayor, menor y, en caso necesario, el número de parche.
    Le recomendamos utilizar siempre la última versión. El proceso es supervisado por el
    <strong>gestor de actualizaciones</strong> de Alaveteli, encargado de decidir qué
    cambios deben incluirse en la actualización actual y la fecha límite del trabajo.
    Actualmente se trata del desarrollador principal de Alaveteli en mySociety.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          La última actualización estable se halla en la
          <a href="https://github.com/mysociety/alaveteli/tree/master">rama maestra</a>.
        </li>
        <li>
          Consulte la <a href="https://github.com/mysociety/alaveteli/releases">lista de actualizaciones</a>
          y sus etiquetas específicas.
        </li>
        <li>
          También intentamos coordinar las actualizaciones con todos los trabajos activos de traducción.
          Consulte la <a href="{{ page.baseurl }}//docs/customising/translation/">traducción de
          Alaveteli</a> para obtener más información.
        </li>
        <li>
          Le animamos a utilizar el <a href="{{ page.baseurl }}/docs/installing/deploy/">mecanismo de
          implementación</a>, que permite mantener actualizado el servidor de producción con facilidad.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="request">solicitud</a>
  </dt>
  <dd>
    En Alaveteli se denomina <strong>solicitud</strong> a la petición de
    <a href="#foi" class="glossary__link">información pública</a> que un 
    usuario envía y que el sitio manda por correo electrónico a la
    <a href="#authority" class="glossary__link">autoridad</a> correspondiente.
    Alaveteli <a href="#publish" class="glossary__link">publica</a> automáticamente
    las <a href="#response" class="glossary__link">respuestas</a>
    a todas las solicitudes enviadas.
  </dd>

  <dt>
    <a name="response">respuesta</a>
  </dt>
  <dd>
    Se denomina <strong>respuesta</strong> al correo electrónico enviado por una
     <a href="#authority" class="glossary__link">autoridad</a> como contestación a
     la <a href="#request" class="glossary__link">solicitud</a> de un usuario.
  </dd>

  <dt>
    <a name="rails">Ruby on Rails</a> (también llamado «Rails»)
  </dt>
  <dd>
    Alaveteli está escrito en el lenguaje de programación Ruby mediante la
    estructura de aplicación web «Ruby on Rails».
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          Sitio web de <a href="http://rubyonrails.org/">Ruby on Rails</a>.
        </li>
        <li>
          La <a href="{{ page.baseurl }}/docs/developers/directory_structure/">estructura de directorios</a> de
          Alaveteli recibe influencias del uso de Ruby on Rails.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="sass">Sass</a> (para la generación de CSS)
  </dt>
  <dd>
    Las hojas de estilo en cascada (CSS) de Alaveteli controlan la apariencia de las páginas y
    se definen utilizando <strong>Sass</strong>. Técnicamente se trata de una extensión del lenguaje CSS
    y lo utilizamos porque resulta más sencillo que el uso directo de CSS
    (por ejemplo, Sass permite realizar un solo cambio y que este se aplique a numerosos
    elementos ubicados en todo el sitio).
    <a href="#rails" class="glossary__link">Rails</a> detecta los cambios realizados
    en cualquier archivo Sass y genera de nuevo automáticamente los archivos CSS utilizados por el sitio.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          <a href="http://sass-lang.com">Sitio web de Sass</a>.
        </li>
        <li>
          Más detalles sobre <a href="{{ page.baseurl }}/docs/customising/themes/#modificar-el-esquema-de-colores">la modificación
          de su esquema de colores</a>, que utiliza Sass.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="staging">servidor de pruebas</a>
  </dt>
  <dd>
    Un <strong>servidor de pruebas</strong> se utiliza para probar el código o la configuración
    antes de publicar el sitio. Es diferente de un <a href="#development"
    class="glossary__link">servidor de desarrollo</a>, donde se modifican el código y las opciones 
    para conseguir que todo funcione, así como de un
    <a href="#production" class="glossary__link">servidor de producción</a>, que es el lugar
    visitado por los usuarios donde se hallan los datos reales.
    <p>
      En el servidor de pruebas debe asignar a
      <code><a href="{{ page.baseurl }}/docs/customising/config/#staging_site">STAGING_SITE</a></code>
      el valor <code>1</code>.
    </p>
    <p>
      Si dispone de un servidor de pruebas, los entornos de sistema de sus servidores de pruebas y de
      producción deberían ser idénticos.
    </p>
    <p>
      En ningún caso debería necesitar editar código directamente en sus servidores de producción y de pruebas.
      Le recomendamos encarecidamente el uso del
      <a href="{{ page.baseurl }}/docs/installing/deploy/">mecanismo de implementación</a> de Alaveteli
      (mediante Capistrano) para efectuar cambios en ellos.
    </p>
  </dd>

  <dt>
    <a name="state">estado</a>
  </dt>
  <dd>
    Cada <a href="#request" class="glossary__link">solicitud</a> pasa por distintos
    <strong>estados</strong> a medida que progresa a través del sistema.
    Los estados ayudan a los administradores de Alaveteli, así como al público,
    a comprender la situación actual respecto a cualquier solicitud y a saber qué
    acción se requiere en cada momento.
    <p>
      Los estados disponibles pueden personalizarse dentro del
      <a href="#theme" class="glossary__link">tema</a> de su sitio.
    </p>
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
          <a href="{{ page.baseurl }}/docs/customising/states/">Estados de ejemplo de WhatDoTheyKnow</a>
          (sitio basado en Alaveteli en funcionamiento en el Reino Unido).
        </li>
        <li>
          Como comparación, consulte los <a href="{{ page.baseurl }}/docs/customising/states_informatazyrtare/">estados de ejemplo de InformataZyrtare</a>
          (sitio basado en Alaveteli en funcionamiento en Kosovo).
        </li>
        <li>
          Para personalizar o añadir sus propios estados, consulte la <a href="{{ page.baseurl }}/docs/customising/themes/#personalizar-los-estados-de-solicitud">personalización de los estados de solicitud</a>.
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme">tema</a>
  </dt>
  <dd>
    Se denomina <strong>tema</strong> al conjunto de modificaciones realizadas en las plantillas
    y en el código que proporcionan al sitio un aspecto o un comportamiento distintos
    al predeterminado. Normalmente necesitará un tema para que Alaveteli muestre su propia marca.
    <div class="more-info">
      <p>Más información:</p>
      <ul>
        <li>
      <a href="{{ page.baseurl }}/docs/customising/themes/">Información sobre los temas</a>.
        </li>
      </ul>
    </div>
  </dd>

</dl>
