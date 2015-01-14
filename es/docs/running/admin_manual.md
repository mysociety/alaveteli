---
layout: es/page
title: Manual de administrador
---

# Manual de administrador de Alaveteli

<p class="lead">
  ¿Cómo se gestiona un sitio basado en Alaveteli? Esta guía explica qué puede esperar
  y los tipos de problemas que puede encontrar. Incluye ejemplos de cómo
  gestiona mySociety su propio sitio de <a href="{{ page.baseurl }}/docs/glossary/#foi"
  class="glossary__link">información pública</a>, <a
  href="https://www.whatdotheyknow.com">whatdotheyknow.com</a>.
</p>

Este manual incluye:

<ul class="toc">
  <li><a href="#cules-son-las-implicaciones">¿Cuáles son las implicaciones?</a></li>
  <li><a href="#soporte-al-usuario">Soporte al usuario</a>
    <ul>
      <li><a href="#gestionar-correos-que-no-llegan-a-la-autoridad">Gestionar correos que no llegan a la autoridad</a></li>
      <li><a href="#solicitudes-para-retirar-informacin">Solicitudes para retirar información</a></li>
      <li><a href="#direccin-incorrecta">Dirección incorrecta</a></li>
      <li><a href="#peticin-de-asesoramiento">Petición de asesoramiento</a></li>
      <li><a href="#soporte-general-requerido">Soporte general requerido</a></li>
      <li><a href="#usuarios-irritantes">Usuarios irritantes</a></li>
      <li><a href="#errores-de-importacin-de-correo">Errores de importación de correo</a></li>
    </ul>
  <li><a href="#mantenimiento">Mantenimiento</a></li>
    <ul>
      <li><a href="#permisos-de-administrador-y-acceso-a-la-interfaz-de-administracin">Permisos de administrador y acceso a la interfaz de administración</a></li>
      <li><a href="#eliminar-un-mensaje-de-la-sala-de-espera">Eliminar un mensaje de la sala de espera</a></li>
      <li><a href="#editar-y-cargar-direcciones-de-correo-de-organismos-pblicos">Editar y cargar direcciones de correo de organismos públicos</a></li>
      <li><a href="#bloquear-usuarios">Bloquear usuarios</a></li>
      <li><a href="#eliminar-una-solicitud">Eliminar una solicitud</a></li>
      <li><a href="#ocultar-una-solicitud">Ocultar una solicitud</a></li>
      <li><a href="#ocultar-un-mensaje-entrante-o-saliente">Ocultar un mensaje entrante o saliente</a></li>
      <li><a href="#editar-un-mensaje-saliente">Editar un mensaje saliente</a></li>
      <li><a href="#ocultar-texto-concreto-de-una-solicitud">Ocultar texto concreto de una solicitud</a></li>
    </ul>
  </li>
</ul>

## ¿Cuáles son las implicaciones?

El gasto general en la gestión de un sitio web de información pública exitoso es
bastante elevado. Richard, un voluntario, escribió una [publicación en el
blog](https://www.mysociety.org/2009/10/13/behind-whatdotheyknow/) sobre este tema en 2009.

WhatDoTheyKnow normalmente tiene 3 voluntarios activos en todo momento gestionando
el soporte, además de otras personas menos activas que ayudan en distintos momentos.

Las tareas de administración pueden dividirse en
[**mantenimiento**]({{ page.baseurl }}/docs/running/admin_manual/#mantenimiento) y
[**soporte al usuario**]({{ page.baseurl }}/docs/running/admin_manual/#soporte-al-usuario).
La frontera entre estas tareas es bastante difusa; la diferencia principal
consiste en que la primera se lleva a cabo exclusivamente a través de la interfaz de
administración, mientras que la segunda se gestiona por correo electrónico directamente
con usuarios finales (pero a menudo resulta en acciones llevadas a cabo a través de la
interfaz de administración).

En una semana de diciembre de 2010 escogida al azar, el equipo de soporte trabajó en 66
eventos diferentes, que comprendieron 44 correos de **soporte** al usuario y 22
tareas de **mantenimiento**.

La mayoría de los correos de soporte requieren algo de tiempo de investigación; algunos
(por ejemplo, los que tienen implicaciones legales) requieren gran cantidad de discusión sobre
políticas para conseguir gestionarlos. Las tareas de mantenimiento suelen ser bastante
más directas, aunque algunas veces requieren conocimientos expertos (por ejemplo, sobre
mensajes rebotados por el servidor de correo).

Durante esta semana, las tareas surgieron de la siguiente manera:

### Tareas comunes de mantenimiento

* 18 respuestas no entregadas o mal encaminadas (por ejemplo, recibidas en la sala de espera)
* 4 solicitudes no clasificadas 21 días después de la respuesta, a la espera de clasificación
* 2 solicitudes marcadas para revisión por parte de un administrador
* 2 ocurrencias marcadas como errores (mensajes rechazados por el servidor por spam, bandeja de entrada llena, etc.) pendientes de reparar

### Tareas de soporte al usuario

* 16 tareas administrativas generales cotidianas: por ejemplo, ocurrencias resultantes en acciones administrativas en el sitio
  (rebotes, respuestas mal encaminadas, etc.)
* 14 elementos gestionados de forma incorrecta (por ejemplo, enviados al equipo de soporte en lugar de a una autoridad)
* 6 usuarios en necesidad de soporte para utilizar el sitio web (problemas para encontrar autoridades o autoridades con problemas de seguimiento)
* 4 usuarios solicitando información sobre protección de datos o información pública
* 3 solicitudes para editar información personal
* 2 solicitudes para editar información difamatoria

## Soporte al usuario

A continuación se ofrece un desglose de los métodos más comunes de soporte al usuario,
a modo de guía sobre el tipo de políticas y formación que un equipo de soporte necesita
para su desarrollo.

### Gestionar correos que no llegan a la autoridad

Es posible que los correos no lleguen a la autoridad en primer lugar por una serie
de motivos:

* El dominio del destinatario ha marcado el correo como spam y no lo ha enviado.
* Se ha incluido en la carpeta de spam a causa de la configuración del cliente de correo.
* El destinatario cuenta con una configuración de filtros de correo que de algún modo omite la bandeja de entrada.

El primer motivo es el más común. La solución consiste en enviar un correo estándar
al departamento informático del destinatario para que añadan a la lista blanca los correos
de su servicio (y, por supuesto, enviar un mensaje al destinatario original sobre este tema).
La interfaz de administración de Alaveteli incluye una opción para reenviar cualquier mensaje.

Un administrador de Alaveteli solo detectará este problema cuando una solicitud haya superado
significativamente el tiempo de espera sin recibir ningún tipo de correspondencia por parte
de la autoridad. Algunas veces el servidor de correo de la autoridad rebotará el correo, en
cuyo caso aparecerá en la interfaz de administración a la espera de revisión por parte de un
administrador.

### Solicitudes para retirar información

#### Acciones legales

En este caso alguien nos indica que cierta información del sitio puede ser objeto de
acciones legales. El escenario variará en las distintas jurisdicciones legales.
En el Reino Unido este tipo de solicitud está habitualmente relacionada con la
difamación.

##### Acciones

* Reciba la notificación por correo en una dirección central de soporte para que
  quede constancia por escrito.
* Actúe de acuerdo a las medidas legales estándar (por ejemplo, es posible que deba retirar 
  temporalmente las solicitudes mientras evalúa el caso, incluso aunque considere que deberían
  seguir funcionando, o tal vez pueda editarlas temporalmente en lugar de retirarlas).
* Registre centralmente la conversación completa y las acciones que ha llevado a cabo.
* Obtenga asesoramiento legal adicional cuando lo necesite. Por ejemplo, puede obtener 
  una estimación de riesgos que sugiera que puede publicar de nuevo la solicitud o mostrarla
  con ediciones limitadas.

#### Derechos de autor/comerciales

A veces las autoridades públicas no acaban de entender que sus respuestas son
públicas y, al descubrirlo, no les gusta este tema, por lo que reclaman derechos de autor. 
Ocasionalmente también se efectúan otras reclamaciones de derechos de autor sobre el contenido, 
pero este caso es el más habitual. Los datos «comercialmente delicados» también pueden 
considerarse como datos personales.

##### Acciones

* En caso de recibir advertencias sobre acciones legales, consulte el punto anterior.
* En caso contrario, trate la reclamación en primer lugar como un caso de defensa basado en
  que las solicitudes de información pública pueden ser repetidas por cualquiera, en que
  los datos deberían ser públicos de todas maneras y en que su publicación en realidad
  evita gastos innecesarios a la autoridad.

##### Ejemplo de correo electrónico dirigido a la autoridad

> Como ya debe saber, nuestra ley de información pública es imparcial respecto a los solicitantes,
> así que cualquier persona del mundo puede solicitar el mismo documento y obtener una copia.
> Para ahorrar dinero a los contribuyentes evitando solicitudes duplicadas y para contar con 
> buenas relaciones públicas, le recomendamos que no solicite eliminar la información ni
> la aplicación de una licencia. También me gustaría destacar que &lt;nombre_autoridad&gt; 
> permite la reutilización de respuestas de información pública a través de nuestro sitio 
> desde el año pasado sin ninguna incidencia al respecto.


#### Datos personales

Aquí se incluyen desde datos personales revelados de forma inadvertida, como
información de identificación personal sobre personas que reclaman beneficios,
hasta el nombre de un usuario del sitio que más adelante no desea aparecer en 
los resultados de búsqueda de Google.

##### Acciones

* Evalúe la solicitud con referencia a las leyes locales de protección de datos. No 
  de por hecho automáticamente que debe retirar cierta información, valore la molestia
  y el daño causados al individuo que se sentiría aliviado al retirar el material
  frente al interés público en publicar o continuar publicando el material. Los datos 
  personales delicados requerirán normalmente un nivel de interés público mucho mayor.
* [WhatDoTheyKnow considera](https://www.whatdotheyknow.com/help/privacy#takedown) que
  existe un fuerte interés público en mantener los nombres de los oficiales o agentes
  de las autoridades públicas.
* Para usuarios que desean que se elimine su nombre totalmente del sitio, intente persuadirlos
  para no hacerlo:
* Averigüe por qué desean que su nombre se elimine.
* Explique que el sitio es un archivo permanente y que es complicado eliminar información
  de internet cuando ya se ha publicado.
* Encuentre ejemplos de solicitudes valiosas que han realizado para mostrar por qué 
  interesa mantenerlas.
* Explique las dificultades técnicas de la eliminación (si son relevantes).
* En las solicitudes persistentes, considere modificar el nombre de su cuenta o 
  abreviar su nombre con la primera inicial para evitar confundir en exceso las solicitudes
  existentes. En caso de verse afectada la seguridad personal, el nombre debe eliminarse y
  sustituirse por el correspondiente texto editado.
* En casos en que la edición resulte compleja (por ejemplo, la eliminación de una firma 
  escaneada en un archivo PDF), solicite que el usuario reenvíe la respuesta con la edición
  correspondiente incluida. Esta solución ofrece la ventaja de entrenar a los usuarios
  para que no repitan este comportamiento en el futuro.
* En caso de llevar a cabo ediciones, se recomienda añadir una nota en la solicitud.


### Dirección incorrecta

Correos que llegan a la dirección del equipo de soporte, pero que no deberían haberlo hecho.
Existen dos tipos principales:

* usuarios que creen que el sitio es un lugar donde contactar con agencias directamente (por ejemplo,
  personas en procesos de inmigración y asilo político que desean contactar con la oficina de aduanas)
* usuarios que envían correos a la dirección de soporte en lugar de utilizar el formulario en línea,
  normalmente porque han respondido a un correo del sistema en lugar de acceder al enlace incluido en el
  mensaje

#### Acciones

Responda al usuario y facilite la dirección correcta.

##### Mensaje de ejemplo:

> Me gustaría obtener información sobre mi solicitud EEA2 enviada en julio de
> 2010. Aún no tengo respuesta... Por favor, dígame qué debo hacer.

##### Respuesta de ejemplo:

> Ha escrito al equipo responsable del sitio web WhatDoTheyKnow.com.
> Nosotros solo gestionamos el sitio y no formamos parte del gobierno de Reino Unido.
>
> Está consultando sobre sus propias circunstancias personales, así que debe contactar
> con UKBA directamente; su información de contacto está disponible en:
>
> http://www.bia.homeoffice.gov.uk/contact/contactspage/
> http://www.ukba.homeoffice.gov.uk/contact/contactspage/contactcentres/
>
> También puede interesarle contactar con el miembro del parlamento de su localidad. Puede preguntar
> en el consejo o en la oficina de atención ciudadana si existe algún centro de soporte 
> de inmigración en su ubicación.

##### Mensaje de ejemplo:

>  ¿Se financia a sí misma la recogida de residuos vegetales? Sospecho por el
>  bajo número de residentes que la utilizan. ¿Cuál es el valor real de la recogida?
>  ¿Es probable que se descarte el programa?

##### Respuesta de ejemplo:

>  Ha escrito al equipo responsable del sitio web WhatDoTheyKnow.com, no a
> &lt;nombre_autoridad&gt;.
>
> Si desea efectuar una solicitud de información pública, puede hacerlo,
> de forma pública, en nuestro sitio. Para empezar, haga clic en «efectuar una nueva
> solicitud de información pública» en:
>
> https://www.whatdotheyknow.com/body/&lt;nombre_autoridad&gt;

### Petición de asesoramiento

Dos ejemplos típicos son:

* Un usuario no está seguro de adónde dirigir su solicitud.
* Desea saber la mejor forma de preguntar a una autoridad qué datos personales tiene sobre él.

##### Solicitud de ejemplo:

> Me gustaría saber en este punto, bajo la ley de información pública, si puedo
> pedir cierta información directamente a la embajada nacional o a la alta comisión de extranjería
> o si debo contactar con el Ministerio de Asuntos Exteriores a través de este sitio.

##### Respuesta de ejemplo:

> Le recomiendo que efectúe su solicitud directamente al Ministerio de Asuntos Exteriores, pues se trata del organismo
> técnicamente sujeto a la ley de información pública.
>
> Al realizar su solicitud, se enviará al equipo central de información pública del Ministerio de Asuntos Exteriores,
> que se encargará de coordinar la respuesta con las partes relevantes de su organización.


### Soporte general requerido

Puede deberse a numerosos motivos, por ejemplo:

* Alguien ha cancelado su solicitud y la autoridad ha respondido después,
  abriéndola de nuevo.
* Correcciones sugeridas para nombres de autoridades o detalles de usuarios
  y de autoridades.
* Se ha incluido una respuesta automática en la solicitud incorrecta.

### Usuarios irritantes

Algunos usuarios utilizan continuamente el sitio de forma incorrecta. Un sitio basado en Alaveteli 
debería contar con una política sobre el bloqueo de usuarios, por ejemplo, para darles un primer
aviso, informarles sobre la política de moderación, etc.

### Errores de importación de correo

Este tipo de errores se da actualmente en un índice de unos dos mensuales. A veces la causa
principal parece ser el bloqueo en la base de datos cuando se reciben dos correos a la vez
para la misma solicitud, mientras que otras veces se debe simplemente a la superación del tiempo
límite de entrada/salida si el servidor está ocupado. Cuando ocurre un error de importación de correo,
el gestor de correo (Exim) recibe un código de salida de 75 y debería intentar enviar el correo
de nuevo. Se envía un correo a la dirección de soporte del sitio indicando que se ha producido
un error, adjuntando el error y el correo entrante. Normalmente Exim reenviará el correo a la
aplicación. En las raras ocasiones en que no lo haga, puede importarlo manualmente situando el correo
de tipo raw (como el adjunto del error enviado a la dirección de soporte del sitio) en un archivo sin la
primera línea «De:» e incorporando el contenido de dicho archivo separado por barras verticales en
el script de gestión de correo, por ejemplo:
```cat missing_mail.txt | script/mailin```


## Mantenimiento

### Permisos de administrador y acceso a la interfaz de administración

La interfaz administrativa se halla en la URL `/admin`.

Solo los usuarios con nivel de administración `super` pueden acceder a la interfaz de administración.
Los usuarios crean sus propias cuentas de la forma habitual y los administradores pueden proporcionarles
permisos `super` de superusuario.

Exite una cuenta de usuario de emergencia, accesible mediante
`/admin?emergency=1`, utilizando las credenciales `ADMIN_USERNAME` y
`ADMIN_PASSWORD` definidas en `general.yml`. Para crear las primeras cuentas
de nivel `super` necesitará iniciar sesión como el usuario de emergencia.
Puede desactivar la cuenta del usuario de emergencia asignando a `DISABLE_EMERGENCY_USER`
el valor `true` en `general.yml`.

Los usuarios con permisos de superusuario también disponen de permisos adicionales
en la interfaz del sitio web para, por ejemplo, clasificar cualquier solicitud, visualizar
elementos que se han ocultado en las búsquedas y acceder a enlaces de administración
junto a los comentarios y solicitudes individuales en la interfaz de usuario.

Es posible anular completamente la autenticación de administrador asignando a
`SKIP_ADMIN_AUTH` el valor `true` en `general.yml`.

### Eliminar un mensaje de la sala de espera

Un mensaje se halla en la sala de espera porque no puede asociarse automáticamente con la solicitud a la que responde. El correo debe moverse de la sala de espera a la solicitud correspondiente.

En primer lugar, inicie sesión en la interfaz de administración ubicada en `/admin`. Verá mensajes ubicados en la sala de espera bajo el título «Put misdelivered responses with the right request». Haga clic en el chevrón para visualizar los mensajes individuales.

Si hace clic en un mensaje de la sala de espera, es posible que vea una estimación efectuada por Alaveteli sobre a qué solicitud pertenece el mensaje. Compruebe dicha solicitud. Si no es la correcta o si Alaveteli no ha hecho ninguna estimación, necesitará consultar la dirección del destinatario `To:` y el contenido del mensaje en el correo en formato raw para poder averiguar a qué solicitud pertenece. Puede navegar y buscar entre las solicitudes desde la interfaz de administración mediante el elemento «Requests» del menú.

Una vez identificada la solicitud a la que corresponde el mensaje, necesitará volver atrás a la página de la sala de espera. Pegue el `id` o el `url_title` de la solicitud en el cuadro situado debajo de «Actions» dentro de «Incoming Message». El `id` de la solicitud puede encontrarse en la URL de la solicitud desde la interfaz de administración; se trata de la parte mostrada después de `/show/`. En la URL `/admin/request/show/118` de administración de la solicitud, el `id` de dicha solicitud es `118`. El `url_title` puede verse en la URL de la solicitud ubicada en la interfaz principal; se trata de la parte situada después de `/request/`. En la URL `/request/documents_relating_to_meeting` corresponde a `documents_relating_to_meeting`. Después haga clic en la opción «Redeliver to another request».

Ahora el mensaje estará asociado al a solicitud correcta y aparecerá en la página pública de la solicitud.

### Editar y cargar direcciones de correo de organismos públicos



### Bloquear usuarios

Es posible que desee bloquear completamente a un usuario del sitio web (como un remitente de spam o un trol, por ejemplo). Necesitará iniciar sesión en la interfaz de administración ubicada en `/admin`. En la fila superior de enlaces, localice y haca clic en la opción «Users».

Encuentre al usuario que desea bloquear en el listado y haga clic sobre su nombre. Una vez se halle en la página del usuario, seleccione la opción «edit».

Introduzca algún texto en el cuadro «Ban text» para explicar por qué ha sido bloqueado. Tenga en cuenta que esta información es visible públicamente desde la cuenta del usuario. Después haga clic en el botón de guardado y el usuario será bloqueado.

### Eliminar una solicitud

Puede eliminar una solicitud completamente mediante la interfaz de administración. Principalmente solo necesitará hacer esto si alguien ha publicado información privada. Acceda a la página de administración para la solicitud buscándola o navegando en la sección «Requests» de la interfaz de administración. En el primer apartado, haga clic en el botón «Edit metadata». En la parte inferior de la página siguiente, haga clic en el botón rojo «Destroy request entirely».

### Ocultar una solicitud

Puede ocultar una solicitud completa desde la interfaz de administración. Inicie sesión en
la interfaz de administración ubicada en `/admin`. En la fila superior de enlaces, localice
y haga clic en «Requests». Busque o navegue para encontrar la página de administración 
correspondiente a la solicitud que desea ocultar. Puede acceder directamente a esta página
siguiendo un enlace «admin» desde la página pública de la solicitud. Puede ocultar la solicitud
de una de las siguientes dos maneras:

  * <strong>Ocultar una solicitud irritante o no relacionada con la información pública y
    notificar al solicitante:</strong>
    Desplácese hacia la sección «actions» de la página de administración 
    de la solicitud. Seleccione una de las opciones junto a «Hide the request and
    notify the user:» y personalice el texto del correo que se enviará al
    usuario para hacerle saber las acciones tomadas. Una vez esté preparado, 
    haga clic en el botón «Hide request».
  * <strong>Ocultar una solicitud o hacerla visible solamente para el solicitante
    sin notificar a dicho solicitante:</strong>
    En la sección «Request metadata» de la página de administración de la
    solicitud, haga clic en «Edit metadata». Asigne a «Prominence» el valor
    «requester_only» para permitir solo al solicitante la visualización de la
    solicitud o el valor «hidden» para ocultar la solicitud a todo el mundo, 
	excepto a los administradores del sitio. Cuando esté preparado, haga clic
    en el botón «Save changes» en la parte inferior del apartado «Edit
    metadata». No se enviará ningún correo al usuario para notificarle de
	las acciones realizadas.

### Ocultar un mensaje entrante o saliente

Es posible que necesite ocultar un mensaje entrante o saliente específico en
la página pública de una solicitud, tal vez porque alguien haya incluido datos
personales en él. Puede efectuar esta tarea desde la página de mensajes de la
interfaz de administración. Puede acceder a la página de administración de mensajes
siguiendo los enlaces de las secciones «Outgoing messages» o «Incoming messages» en
la página de administración de la solicitud, o directamente desde la página pública
de la solicitud, haciendo clic en el enlace «admin» de dicho mensaje. Una vez en la 
página de administración del mensaje, puede cambiar su relevancia. Asigne el valor
«hidden» para ocultarlo a todo el mundo, excepto a los administradores del sitio,
o el valor «requester_only» para que solo pueda verlo el solicitante (y los administradores
del sitio). Si es posible, añada un texto en el cuadro «Reason for prominence».
Este texto se mostrará como parte de la información en la página de la solicitud
donde se hallaba el mensaje, indicando la razón por la que se ha ocultado.

### Editar un mensaje saliente

Puede tener la necesidad de editar un mensaje saliente debido a que el solicitante haya incluido accidentalmente datos personales que no desea que se publiquen en el sitio. Puede seguir uno de los enlaces «admin» de la página pública de la solicitud en el sitio o buscar la solicitud desde la interfaz de administración, en la sección «Requests».

Desplácese hacia abajo, hasta el apartado «Outgoing Messages», y haga clic en «Edit».

En la siguiente página podrá editar el mensaje y guardarlo. La versión editada aparecerá en el sitio basado en Alaveteli, pero la versión sin editar se habrá enviado a la autoridad.


### Ocultar texto concreto de una solicitud

Pueden añadirse normas de censura a una solicitud o a un usuario. Estas normas definen
porciones que deben eliminarse, bien de la solicitud (y todos los archivos asociados, por ejemplo,
adjuntos en mensajes entrantes) o bien de todas las solicitudes asociadas a un usuario, y
un texto de sustitución. En los archivos binarios el texto de sustitución será siempre una serie
de «x» caracteres de longitud idéntica al texto sustituido para mantener la longitud del 
archivo. La censura de adjuntos no funciona de forma consistente, pues resulta complejo
redactar normas que coincidan con los contenidos exactos del archivo subyacente, así que
deberá comprobar siempre los resultados. Asegúrese también de añadir normas de censura
para el texto real y compruebe la opción «View as HTML»; esta opción es actualmente
(septiembre de 2013) generada a partir de archivos PDF u otros archivos binarios sin censura.

Puede hacer que una norma de censura se aplique como una [expresión
regular](http://en.wikipedia.org/wiki/Regular_expression) activando la casilla
«Is it regexp replacement?» en la interfaz de administración de normas de censura.
En caso contrario solo sustituirá literalmente las ocurrencias en el texto introducido.
Al igual que las normas de censura comunes basadas en texto regular, las normas basadas
en expresiones regulares se ejecutarán también en archivos binarios relacionados con la 
solicitud, así que una expresión regular algo ambigua puede resultar en consecuencias
inesperadas si también concuerda con la secuencia subyacente de caracteres de un archivo
binario. Además, las expresiones regulares complejas o ambiguas pueden tener un coste de
ejecución muy elevado (en algunos casos pueden congelar la aplicación por completo). 
Por tanto:

* Restrinja su uso a los casos que no puedan cubrirse con facilidad de otro modo.
* Manténgalas simples y específicas en la medida de lo posible.

<strong>Para añadir una norma de censura a una solicitud</strong>, acceda a la página de
administración de dicha solicitud, desplácese hacia la parte inferior de la página y haga
clic en el botón «New censor rule (for this request only)». En la página siguiente,
introduzca el texto que desea sustituir, por ejemplo, «información privada», el texto con el
que desea sustituirlo, por ejemplo, «[información privada oculta]», y un comentario indicando
a otros administradores por qué ha ocultado esta información.

<strong>Para añadir una norma de censura a un usuario</strong>, de forma que se aplique
a todas las solicitudes efectuadas por dicho usuario, acceda a la página del usuario en la 
interfaz de administración. Puede hacerlo mediante un clic en la sección «Users» y buscar
al usuario que desea o siguiendo el enlace «admin» de la interfaz pública del usuario. Una
vez se encuentre en la página de administración del usuario, desplácese hasta la parte inferior
de la página y haga clic en el botón «New censor rule». En la siguiente página, introduzca
el texto que desea sustituir, por ejemplo «mi nombre real es Bruce Wayne», el texto con el que
que desea sustituirlo, por ejemplo, «[información privada oculta]», y un comentario indicando
a otros administradores por qué ha ocultado esta información.


