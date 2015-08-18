---
layout: es/page
title: Primeros pasos
---

# Primeros pasos con Alaveteli

<p class="lead">
  Esta guía está dirigida a personas que tienen en mente implementar su propio
  sitio web basado en Alaveteli en una nueva jurisdicción.
</p>

Como inspiración, puede consultar algunos de los sitios existentes basados en Alaveteli:
[tuderechoasaber.es](http://tuderechoasaber.es) (España),
[AskTheEU](http://www.asktheeu.org) (Unión Europea) y
[WhatDoTheyKnow](https://www.whatdotheyknow.com) (Reino Unido). Estos sitios utilizan
el software Alaveteli, además de sus propios temas personalizados instalados sobre la plataforma
para darle un aspecto diferente.

Ni siquiera necesita elaborar un tema personalizado para empezar. Puede tener un
sitio web con el aspecto del [sitio de demostración](http://demo.alaveteli.org) y
añadir tan solo su propio logotipo.

El proceso de implementación de su propio sitio web basado en Alaveteli puede durar
desde un solo día hasta tres meses, dependiendo de su nivel de ambición respecto a
la personalización del software, su acceso a habilidades técnicas y su tiempo disponible.

Puede hacerse una idea de cómo saldrán las cosas leyendo [cómo se implementó un sitio
Alaveteli en España](https://www.mysociety.org/2012/04/16/a-right-to-know-site-for-spain/)
(tenga en cuenta que se llevó a cabo con un desarrollador experto al mando). También
necesitará pensar sobre cómo gestionará el sitio; un sitio basado en Alaveteli
requiere una gran cantidad de esfuerzo constante en su moderación y publicidad 
(consulte los pasos 6 y 7 a continuación).

Le recomendamos que siga estos pasos en el orden indicado para empezar:

* [Paso cero: reúna a su equipo inicial](#step-0)
* [Paso uno: ponga una versión no personalizada en funcionamiento](#step-1)
* [Paso dos: empiece a recopilar información sobre autoridades públicas](#step-2)
* [Paso tres: personalice el sitio](#step-3)
* [Paso cuatro: traduzca toda la información](#step-4)
* [Paso cinco: pruebe el sitio](#step-5)
* [Paso seis: promocione el sitio en el mercado](#step-6)
* [Paso siete: mantenga el sitio](#step-7)


<a name="step-0"> </a>

## Paso cero: reúna a su equipo inicial

Es improbable que consiga realizar mucho trabajo en solitario. Necesitará
traductores, personas que obtengan direcciones de correo electrónico de las autoridades y
posiblemente un diseñador, preferentemente un experto técnico que le ayude en la personalización.
Lea primero esta guía y valore qué habilidades necesitará para lanzar y mantener el sitio
de forma satisfactoria.

Se necesitaron unas [diez personas (traductores incluidos) trabajando durante tres
días](http://groups.google.com/group/alaveteli-dev/msg/1bd4afd3091f8b4f) para
lanzar [Queremos Saber](http://queremossaber.org.br/), una versión brasileña de
Alaveteli.

> Fue genial implementar este sitio. A pesar de algunos problemas menores
> (la mayoría relacionados con el hecho de que no teníamos a nadie experto en
> Ruby on Rails y Postfix), fue bastante rápido y en menos de una semana
> obtuvimos un sitio web totalmente funcional.
>
> -- _Pedro Markun, Queremos Saber_

[AskTheEU](http://www.asktheeu.org), una versión mucho más completa y refinada con
un tema personalizado y otras modificaciones, necesitó un equipo de 2 o 3 personas
durante unos 3 meses (a tiempo parcial) para completarse.

Pida a los miembros de su equipo que se unan a una de las listas de correo. Si tiene
alguna consulta, estos son los primeros lugares donde preguntar.
[alaveteli-users](http://groups.google.com/group/alaveteli-users) es una lista de
correo para usuarios no técnicos del software. Publique mensajes aquí para solicitar
asistencia sobre cómo iniciar su proyecto, preguntar cómo utilizan los demás el
software y realizar otras consultas.
[alaveteli-dev](http://groups.google.com/group/alaveteli-dev) es el lugar donde
consultar cuestiones técnicas, como problemas de instalación de Alaveteli.

<a name="step-1"> </a>

## Paso uno: ponga una versión no personalizada en funcionamiento

Dispone de dos opciones: instalar su propia copia o solicitar al equipo de Alaveteli
que le proporcione una versión hospedada.

En caso de instalar su propia copia, tendrá el control completo sobre el sitio web,
su rendimiento, la frecuencia de actualización y otros aspectos. Consideramos que esta
es la mejor opción, pero necesitará disponer de algunos recursos para elegirla.

Alternativamente tenemos una capacidad muy limitada para gestionar un grupo reducido de sitios
basados en Alaveteli para voluntarios. Deseamos aprender más sobre cómo podemos
apoyar a empresas externas y, por tanto, estamos contentos de ayudar a hospedar sitios de 
pequeña envergadura para dos o tres socios. Sin embargo, no ofrecemos ningún acuerdo de servicio,
ninguna garantía ni ninguna disposición específica de nuestro tiempo: si el sitio sufre
una caída mientras estamos de vacaciones, ¡deberá esperar hasta que volvamos! Si desea probar
esta opción, [contacte con nosotros](mailto:international@mysociety.org) para averiguar si contamos
con espacio disponible.

### Instale su propia copia

Necesitará encontrar a un técnico con conocimientos sobre el hospedaje de sitios web
mediante Apache y Linux. No es necesario tener experiencia en Ruby on Rails,
aunque representa una gran ventaja.

También necesitará un servidor de recursos. Debería solicitar ayuda a su asistente técnico
para obtenerlo. Los requisitos mínimos para el funcionamiento de un sitio con poco tráfico son
512 MB de memoria RAM y un disco de 20 GB, aunque lo ideal son 2 GB de memoria RAM. Recomendamos
el último Debian Wheezy (7) de 64 bits o Ubuntu precise (12.04)
como sistema operativo. Rackspace ofrece servidores adecuados en la nube desde unos
25 dólares al mes. Una vez adquirido el servidor, su asistente técnico debería seguir la
[documentación de instalación]({{ page.baseurl }}/docs/installing/).

Alternativamente puede utilizar los servicios web Amazon Web Services, que cuentan con la
ventaja adicional de que puede utilizar nuestra [AMI EC2 de Alaveteli]({{ page.baseurl }}/docs/installing/ami/)
preconfigurada para una puesta a punto casi instantánea. Sin embargo, este servicio es más caro que Rackspace,
especialmente si desea disponer de mayor memoria RAM.

### Juegue con ella

Necesitará entender cómo funciona el sitio web. Mientras su propia copia no esté
disponible, puede probar la copia en funcionamiento en el [servidor de 
demostración](http://demo.alaveteli.org) (tenga en cuenta que no garantizamos que
se halle disponible ni en ejecución).

Ahora mismo no disponemos de una guía, así que debe explorarse libremente.

Cuando disponga de su propia versión en funcionamiento, pruebe a iniciar sesión en la 
interfaz de administración añadiendo `/admin` al final del nombre de su dominio.
Esta ruta le conducirá a la interfaz administrativa. Es muy sencilla y funcional.
Por ejemplo, pruebe añadiendo nuevas autoridades, tal vez con su propia dirección de correo,
de forma que pueda ver qué aspecto tienen las solicitudes recibidas por dichas autoridades.

Al probar las cosas debe representar varios papeles: el de administrador del sitio, el de 
usuario común y el de autoridad pública. Esto puede resultar confuso con varias
direcciones de correo, por lo que un método rápido y sencillo de gestión consiste en el 
uso de un servicio de correo de usar y tirar como [Mailinator](http://mailinator.com).

<a name="step-2"> </a>

## Paso dos: empiece a recopilar información sobre autoridades públicas

Uno de los requisitos más importantes antes del lanzamiento consiste en la elaboración 
de una lista con todos los organismos a quienes desea dirigir solicitudes de información
pública.

Es una buena idea crear una hoja de cálculo compartida para solicitar a sus colaboradores que 
le ayuden a elaborar el listado. Una plantilla como [esta hoja de cálculo de 
Google](https://docs.google.com/spreadsheet/ccc?key=0AgIAm6PdQexvdDJKdzlNdXEtdjBETi1SLVhoUy1QM3c&hl=en_US) resulta ideal.

Si escribe por correo electrónico a posibles colaboradores para solicitar su ayuda, además de 
facilitar su trabajo, también podrá identificar a personas dispuestas que puedan estar interesadas
en ayudarle a mantener y gestionar el sitio web. Hemos redactado [una publicación en nuestro blog
sobre este tema](https://www.mysociety.org/2011/07/29/you-need-volunteers-to-make-your-website-work/).

La interfaz de administración incluye una página donde puede cargar un archivo en formato CSV (este tipo de archivo
contiene valores separados por comas) para crear o editar autoridades. El formato CSV resulta práctico 
(por ejemplo, es sencillo guardar datos de una hoja de cálculo en un archivo CSV).

<a name="step-3"> </a>

## Paso tres: personalice el sitio

### Nombre y medios sociales

Evidentemente querrá incluir su propio diseño visual en el sitio. Una vez cuente
con un nombre para su proyecto (como WhatDoTheyKnow en el Reino Unido, AskTheEU en la
Unión Europea o InformateZyrtare en Kosovo), registre un código de usuario de Twitter
y un nombre de dominio. Alaveteli confía en que mantenga un blog para su sección de «Noticias»,
así que es posible que desee crear un blog gratuito en http://wordpress.com o
http://blogger.com para anunciar su proyecto en una nueva publicación.

### Marcas y temas

A continuación medite sobre la identidad visual. Probablemente debería al menos
sustituir el logotipo predeterminado de Alaveteli que puede verse en la parte superior 
izquierda de <http://demo.alaveteli.org>. También resulta sencillo modificar el
esquema de colores.

Si dispone de algo más de tiempo y presupuesto, puede editar en mayor profundidad el diseño,
añadiendo una página de inicio personalizada, distintas fuentes, etc., pero cuanto más personalice
el sitio, más difícil resultará actualizarlo en el futuro y necesitará un desarrollador
y/o un diseñador que le ayude a personalizarlo. Denominamos «tema» al conjunto personalizado de colores,
fuentes, logotipos, etc.; encontrará varias notas para desarrolladores 
sobre la [creación de temas]({{ page.baseurl }}/docs/customising/themes/). Es posible que invierta
entre 1 y 15 días en estas funciones.

### Diferencias legislativas

Contamos con los usuarios para que ayuden a identificar la categoría de sus propias solicitudes
(por ejemplo, como «satisfactoria» o «rechazada»). A estas categorías las denominamos «estados».
La mayoría de las leyes sobre información pública a nivel mundial son tan similares que probablemente
pueda utilizar los estados de Alaveteli tal como se ofrecen, sin necesidad de modificarlos.

Además, hemos descubierto que en general no es buena idea intentar implementar las leyes 
de forma exacta en la interfaz de usuario, pues a menudo resultan complicadas y confusas para 
los usuarios. Debido a que el concepto de Alaveteli consiste en facilitar el ejercicio del
derecho a saber, consideramos mejor implementar el proceso de información pública como *debería*
ser, en lugar de como *es actualmente*.

Sin embargo, si realmente siente la necesidad de alterar los estados en los que puede hallarse una 
solicitud, es posible hacerlo hasta cierto nivel dentro de su tema. Medite sobre qué
se requiere y después envíe un mensaje a la lista de correo de Alaveteli para obtener
comentarios y valorar sus ideas. Necesitará solicitar a su desarrollador que implemente
los estados nuevos. Esto no suele requerir más de un par de días de trabajo, a menudo menos,
pero los flujos de trabajo complejos pueden necesitar un tiempo mayor.

### Redacte las páginas de ayuda

Las páginas de ayuda predeterminadas en Alaveteli proceden de WhatDoTheyKnow y, por tanto,
solo son relevantes en el Reino Unido. Puede utilizar estas páginas como inspiración, pero
debería revisar su contenido basándose en su jurisdicción. Las páginas importantes que deben
traducirse son:

* [Información](https://github.com/mysociety/alaveteli/blob/master/app/views/help/about.rhtml): por qué existe el sitio web, por qué funciona, etc.
* [Contacto](https://github.com/mysociety/alaveteli/blob/master/app/views/help/contact.rhtml): formas de ponerse en contacto.
* [Créditos](https://github.com/mysociety/alaveteli/blob/master/app/views/help/credits.rhtml): quién participa en el sitio. Incluye una sección importante sobre cómo pueden los usuarios colaborar en el proyecto.
* [Agentes](https://github.com/mysociety/alaveteli/blob/master/app/views/help/officers.rhtml): información para los agentes que tratan con la información pública en los distintos organismos. Reciben un enlace que conduce a esta página en los correos que el sitio les envía.
* [Privacidad](https://github.com/mysociety/alaveteli/blob/master/app/views/help/privacy.rhtml): política de privacidad e información que aclara que las solicitudes aparecerán en internet. Informe a los usuarios  de que pueden utilizar seudónimos en su jurisdicción.
* [Solicitudes](https://github.com/mysociety/alaveteli/blob/master/app/views/help/requesting.rhtml): la página de ayuda principal para realizar solicitudes. Cómo funciona, cómo decidir a quién escribir, qué se puede esperar en cuanto a respuestas se refiere, cómo efectuar reclamaciones, etc.
* [Descontento](https://github.com/mysociety/alaveteli/blob/master/app/views/help/unhappy.rhtml): los usuarios son dirigidos a esta página cuando una solicitud no ha sido satisfactoria (por ejemplo, si la solicitud ha sido rechazada o cuando el organismo insiste en recibir una solicitud por correo postal). La página debería animarles a continuar intentándolo, por ejemplo, iniciando una nueva solicitud o dirigiéndola a otro organismo.
* [Motivos para utilizar el correo](https://github.com/mysociety/alaveteli/blob/master/app/views/help/_why_they_should_reply_by_email.rhtml): un breve texto informativo que explica a los usuarios por qué deberían insistir en obtener respuestas por correo electrónico. Se muestra junto a las solicitudes que han «pasado al correo postal».

Las páginas de ayuda contienen código HTML. Su asistente técnico debería poder darle soporte al respecto.

Una vez redactadas las páginas, solicite a su asistente técnico que las añada a su tema.

Este es también un buen momento para empezar a pensar sobre algunos de los correos estándar
que enviará como respuesta a consultas comunes de usuarios y tareas administrativas, por
ejemplo, un correo electrónico que se envía a los departamentos informáticos para solicitarles
que añadan a la lista blanca los correos de su sitio web basado en Alaveteli (en caso de que
dichos correos sean marcados como spam o correo no deseado). Consulte el
[manual de administrador]({{ page.baseurl }}/docs/running/admin_manual/) para conocer los detalles
sobre algunas tareas administrativas habituales. Existe una lista de los correos estándar 
utilizados por WhatDoTheyKnow en el sitio web de
[FOI Wiki](http://foiwiki.com/foiwiki/index.php/Common_WhatDoTheyKnow_support_responses).

### Otras personalizaciones de software

Tal vez le interese una nueva funcionalidad relacionada con la usabilidad que aún no se
encuentra en Alaveteli, como la detección automática del idioma para sitios web multilingües
o la integración con Facebook o con una aplicación para iPhone.

Tal vez haya encontrado un área relacionada con las traducciones que Alaveteli aún no soporta
en su totalidad (por ejemplo, aún no hemos necesitado implementar un sitio web en un idioma
escrito de derecha a izquierda).

Tal vez su jurisdicción *requiera* una nueva característica que no se encuentra en Alaveteli,
por ejemplo, el envío de información adicional por parte de los usuarios en sus solicitudes.

En estos casos necesitará que su asistente técnico (o algún desarrollador de software)
lleve a cabo estas modificaciones. Estas tareas pueden consumir mucho tiempo, pues el desarrollo
de software nuevo, sus pruebas y su despliegue suelen ser complejos. Debería consultar con un
experto sobre la cantidad de tiempo requerido para ello. Normalmente este tipo de cambios pueden
ocupar entre uno y tres meses de la planificación del proyecto.

<a name="step-4"> </a>

## Paso cuatro: traduzca toda la información

¡Este es un trabajo potencialmente grande!

Si necesita soportar múltiples idiomas en su jurisdicción, deberá traducir:

* nombres de autoridades públicas, notas, etc.
* organismos públicos
* páginas de ayuda
* todas las indicaciones de la interfaz web en el software

Resulta algo más sencillo si solo necesita soportar un idioma en su
jurisdicción, pues ya habrá redactado la ayuda y la información sobre autoridades
públicas, por lo que solo necesitará traducir la interfaz web.

Los nombres de autoridades públicas pueden editarse a través de la interfaz de administración
o cargando una hoja de cálculo. Las páginas de ayuda necesitan una copia guardada para cada idioma,
su asistente técnico las situará en el lugar correspondiente.

Las traducciones de la interfaz web se gestionan mediante la colaboración de un sitio web
llamado Transifex. Dicho sitio permite que equipos de traducción colaboren en un solo lugar,
utilizando una interfaz sencilla y segura.

La página de Alaveteli en Transifex se halla en
<https://www.transifex.com/projects/p/alaveteli/>; todas las traducciones se encuentran en
un único archivo de traducción llamado
[`app.pot`](https://www.transifex.com/projects/p/alaveteli/resource/apppot/).

Puede establecer su propio idioma y proporcionar aquí sus traducciones, así como utilizar
software especializado en su propio ordenador (consulte las páginas de ayuda de Transifex).

Existen (en el momento en que se redacta este texto) alrededor de 1.000 frases o fragmentos
de frase diferentes (conocidos como «strings» o «cadenas de texto») para traducir. El significado
de la mayor parte de cadenas de texto debería resultar obvio, pero el de otras no tanto. Hasta que 
redactemos una guía para traductores, la mejor opción es traducir todo lo posible y después
consultar a su asistente técnico o la lista de correo del proyecto sobre cualquier detalle 
que genere dudas.

Con el tiempo, a medida que se solucionan errores y se añaden nuevas funcionalidades, también 
aparecen nuevas cadenas de texto en el archivo. Por tanto, necesita consultar el archivo `app.pot` de vez en cuando
para revisar posibles cadenas de texto pendientes de traducción.

<a name="step-5"> </a>

## Paso cinco: pruebe el sitio

Para el lanzamiento su asistente técnico debería revisar las [buenas prácticas
para el servidor de producción]({{ page.baseurl }}/docs/running/server/).

Un lanzamiento discreto, informando a solo unas pocas personas de confianza, suele ser
una buena idea. Así puede revisar cómo funciona todo y evaluar las respuestas de las 
autoridades. Es probable que las respuestas varíen ampliamente entre jurisdicciones y
dentro de ellas y, por tanto, la forma adecuada de hacer que su sitio web sea un éxito
variará de acuerdo con estas respuestas.

<a name="step-6"> </a>

## Paso seis: promocione el sitio en el mercado

En general la mejor manera de dirigirse a las autoridades consiste en una combinación de
ánimo y exposición. En privado puede explicar que, además de ayudar a llevar a cabo sus requisitos
legales y obligaciones civiles, reducirá su carga de trabajo al evitar solicitudes repetidas.
En público puede trabajar con periodistas para felicitar a los organismos que estén haciendo un
buen trabajo y destacar a los que se niegan a participar. Por tanto, es muy importante contactar
con periodistas interesados en la información pública.

Otra herramienta de marketing importante es [Google
Grants](http://www.google.com/grants/), un esquema gestionado por Google que ofrece
AdWords (palabras clave) gratuitas a organizaciones benéficas en numerosos países de todo el mundo.
Le resultarán increíblemente prácticas en la captación de tráfico para su sitio web.
Vale la pena darse de alta como organización benéfica solo para poder aprovechar este programa.

<a name="step-7"> </a>

## Paso siete: mantenga el sitio

Para gestionar satisfactoriamente un sitio web basado en Alaveteli se requiere una colaboración
regular y constante. Esto resulta más sencillo si se lleva a cabo entre un pequeño grupo de personas
que comparten tareas. Con suerte será lo bastante afortunado como para recibir subvenciones con las que
pagar a personas por estas tareas. Sin embargo, también es posible que necesite la ayuda de 
voluntarios. Hemos escrito [una publicación en nuestro blog sobre la importancia de los 
voluntarios](https://www.mysociety.org/2011/07/29/you-need-volunteers-to-make-your-website-work/), que debería leer.

Necesitará crear una dirección de correo electrónico de grupo para todas las personas que 
gestionen el sitio web. Todas las consultas de usuarios del sitio se dirigirán a dicha dirección,
así como las notificaciones automáticas de Alaveteli. Una dirección de grupo es realmente práctica
para coordinar respuestas, debatir sobre las políticas, etc.

Podría dedicar tan solo una o dos horas semanales para mantenerse al tanto de la
«sala de espera» del sitio, donde se recogen todos los mensajes que el sitio no sabe
cómo gestionar (como correo no deseado, mensajes con un destinatario incorrecto,
etc.). Sin embargo, cuanto más esfuerzo invierta en él, más satisfactorio resultará su sitio web. 
Para garantizar su éxito debería llevar a cabo tareas como estas:

* Responder a las solicitudes de ayuda de los usuarios por correo electrónico
* Monitorizar nuevas solicitudes, buscar personas que puedan necesitar ayuda y publicar comentarios alentadores en sus solicitudes
* Monitorizar las respuestas de las autoridades y buscar a las que intentan evitar responder, ofreciendo ayuda a la persona que realizó la solicitud,
  posiblemente generando publicidad «avergonzante» para que la autoridad responda
* Publicar en Twitter sobre solicitudes y respuestas interesantes
* Redactar publicaciones en su blog sobre el progreso del proyecto
* Comentar con periodistas las historias potencialmente interesantes
* Conseguir voluntarios para ayudar en el sitio
* Categorizar las solicitudes no clasificadas

Consulte también el [manual de administrador]({{ page.baseurl}}/docs/running/admin_manual/), que describe
algunas tareas típicas que deberá llevar a cabo cuando su sitio esté en funcionamiento.

### ¿Qué más?

Si considera que sería realmente practico incluir algo más en esta guía de inicio, infórmenos para que podamos añadirlo.
