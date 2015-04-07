---
layout: es/page
title: Temas
---

# Temas de Alaveteli

<p class="lead">
    Alaveteli utiliza <strong>temas</strong> para que el sitio tenga un aspecto
    y un funcionamiento distintos del predeterminado..
    Los cambios pequeños, como el color y el logotipo, son relativamente sencillos, pero los temas
    también pueden controlar detalles más complejos, como el <em>comportamiento</em> del sitio.
</p>

Al personalizar su sitio basado en Alaveteli, existen numerosos detalles que puede modificar
con tan solo editar los [ajustes de configuración]({{ page.baseurl }}/docs/customising/config/).
Pero si desea modificar el aspecto del sitio o añadir comportamientos más específicos,
necesitará elaborar un **tema**.

No necesita ser programador para realizar pequeños cambios, pero necesitará tener la suficiente
confianza para copiar y modificar algunos archivos. Si no está seguro sobre este tema,
¡[pida ayuda](/community/)!

## Qué le puede interesar cambiar

El requisito más habitual es añadir una marca al sitio, por lo menos,
[insertar su propio logotipo](#modificar-el-logotipo) y su [esquema de colores](#modificar-el-esquema-de-colores). 
Es posible que también desee modificar los distintos estados en los que puede
hallarse una solicitud. También querrá editar las categorías en las que los organismos públicos pueden
aparecer (por ejemplo, los grupos a mano izquierda de la página
«[View authorities](https://www.whatdotheyknow.com/body/list/all)» en
WhatDoTheyKnow).

Es posible que desee personalizar otras opciones; escriba a la lista de correo de
desarrollo para comentar sus necesidades. ¡Seguimos trabajando para encontrar
el mejor método de llevar a cabo este tipo de modificaciones!

En todo caso, el principio importante a tener en cuenta es que cuanto menos
sobrescriba y personalice el código, más sencillo será el mantenimiento de su
sitio a largo plazo. Toda personalización es posible, pero
para cada modificación más allá de los casos sencillos aquí documentados,
pregúntese (o pregunte a su cliente): «¿podemos vivir sin esto?». Si la 
respuesta es «no», considere iniciar un debate sobre una forma
de implementar los cambios mediante un complemento en lugar de sobrescribir el código central.

## Principios generales

Intentamos encapsular todas las funcionalidades específicas del sitio en uno
de los siguientes lugares:

* [Configuración]({{ page.baseurl }}/docs/customising/config/) del sitio
  (por ejemplo, el nombre de su sitio, los idiomas
  disponibles, etc., en `config/general.yml`).
* Datos (por ejemplo, los organismos públicos a lso que deben dirigirse las solicitudes).
* Un tema, instalado en `lib/themes`.

Este documento trata sobre lo que puede hacer en un tema.

Por defecto, el tema de muestra («alavetelitheme») ya está instalado.
Consulte la opción
[`THEME_URLS`]({{ page.baseurl }}/docs/customising/config/#theme_urls)
en `general.yml` para obtener información.

También puede instalar el tema de muestra manualmente ejecutando:

    bundle exec rake themes:install

El tema de muestra contiene ejemplos para prácticamente todo lo que pueda
interesarle personalizar. Probablemente le interese efectuar una copia, renombrarla
y utilizarla como base para su propio tema.

## Asegúrese de que su tema es lo más ligero posible

Cuanto más añade a su tema, más difícil resulta actualizarlo a versiones
futuras de Alaveteli. Toda la información que añade a su tema
sobrescribe detalles del tema central, así que, si elabora una nueva «plantilla
principal», los nuevos widgets que aparezcan en el tema principal no aparecerán
en su sitio web.

Por tanto, debería considerar cómo puede adaptar el sitio a su marca sin
modificar el tema principal en exceso. Lo ideal sería que pudiese adaptar el
sitio modificando únicamente los estilos CSS. También necesitará añadir 
páginas de ayuda personalizadas, como se describe a continuación.

## Adaptar el sitio a su marca

Las plantillas principales que comprenden la apariencia y la interfaz de usuario de un 
sitio basado en Alaveteli se hallan en `app/views/` y utilizan la sintaxis ERB de Rails.
Por ejemplo, la plantilla para la página de inicio se encuentra en
`app/views/general/frontpage.html.erb` y la correspondiente a la página de información
del sitio, en `app/views/help/about.html.erb`.

Evidentemente *podría* editar directamente estos archivos centrales, pero no sería una
buena idea, puedes cada vez le resultaría más difícil aplicar actualizaciones.
Dicho esto, a veces le interesará modificar las plantillas centrales de forma que 
ofrezcan ventajas para todo el mundo, en cuyo caso, puede debatir los cambios en la
lista de correo, aplicarlos en una adaptación de Alaveteli y publicar una solicitud
de extracción (pull request).

Sin embargo, normalmente debería sobrescribir estas páginas **en su propio
tema**, situándolas en la ubicación correspondiente dentro del directorio 
`lib/` del tema. Es decir, se mostrará el archivo ubicado en
`lib/themes/alavetelitheme/lib/views/help/about.html.erb` en 
lugar del archivo principal de información sobre el sitio.

### Modificar el logotipo

Alaveteli utiliza el [flujo de atributos](http://guides.rubyonrails.org/asset_pipeline.html) de Rails para convertir y comprimir las hojas de estilos escritas en
<a href="{{ page.baseurl }}/docs/glossary/#sass" class="glossary__link">Sass</a>,
la extensión del lenguaje CSS, en CSS minimizados y concatenados. Los atributos se almacenan en el núcleo de Alaveteli, en `app/assets`, como `fonts`, `images`, `javascripts` y `stylesheets`.
El tema predeterminado incluye los directorios de atributos correspondientes en `alavetelitheme/assets`. Los archivos añadidos a estos directorios tendrán prioridad sobre los ubicados en los directorios centrales. Al igual que con las plantillas, aparecerá el archivo `lib/themes/alavetelitheme/assets/images/logo.png` en el sitio en lugar del logotipo `app/assets/images/logo.png`.

### Modificar el esquema de colores

Alaveteli utiliza un conjunto básico de módulos de
<a href="{{ page.baseurl }}/docs/glossary/#sass" class="glossary__link">Sass</a>
para definir la apariencia del sitio en dispositivos de distintos tamaños, así como algunos estilos básicos. Estos módulos se hallan en `app/assets/stylesheets/responsive`. Los colores y fuentes se añaden en el tema, alavetelitheme los define en `lib/themes/alavetelitheme/assets/stylesheets/responsive/custom.scss`. Los colores utilizados en el tema se definen como variables en la parte superior de este archivo, donde pueden editarse.

### Modificar otros detalles de estilo

Para modificar otras opciones de estilo, puede añadir o editar los estilos en `lib/themes/alavetelitheme/assets/stylesheets/responsive/custom.scss`. Los estilos definidos aquí tendrán prioridad sobre los ubicados en los módulos Sass, en `app/assets/stylesheets/responsive`, pues serán importados en último lugar por `app/assets/stylesheets/responsive/all.scss`. Sin embargo, si desea modificar significativamente el modo en que se muestra una parte concreta del sitio, puede interesarle sobrescribir uno de los módulos principales Sass. Puede sobrescribir la apariencia de la página de inicio, por ejemplo copiando `app/assets/stylesheets/responsive/_frontpage_layout.scss` a `lib/themes/alavetelitheme/assets/stylesheets/responsive/_frontpage_layout.scss` y editándolo después.

Puede cargar hojas de estilos y archivos javascript adicionales añadiéndolos a `lib/themes/alavetelitheme/lib/views/general/_before_head_end.html.erb`.

## Añadir sus propias categorías de organismos públicos

En Alaveteli las categorías se implementan utilizando etiquetas. Pueden utilizarse
etiquetas específicas para agrupar autoridades en categorías. Las categorías
se agrupan a su vez bajo encabezados de categoría en el margen de la página
de visualización de autoridades, «View authorities». Puede crear, editar y reorganizar 
categorías y encabezados de categoría desde la interfaz de administración, en el
elemento «Categories» del menú. Puede aplicar las etiquetas de categoría creadas
a las autoridades en el elemento «Authorities» del menú de administración. Para que
una autoridad aparezca dentro de una categoría, la etiqueta de dicha categoría debe 
ser una de las aplicadas a la autoridad en cuestión.

## Personalizar los estados de solicitud

Como ya se ha mencionado, si puede vivir con los
[estados de solicitud predeterminados de Alaveteli]({{ page.baseurl }}/docs/customising/states/),
es buena idea hacerlo. Tenga en cuenta que puede definir tras cuántos días se considera
que una solicitud está «fuera de plazo» en el archivo de configuración principal del sitio: consulte
[`REPLY_LATE_AFTER_DAYS`]({{ page.baseurl }}/docs/customising/config/#reply_late_after_days).

Si no puede vivir con los estados tal y como están, existe un método muy básico para añadir otros
(que se irá mejorando con el tiempo). Actualmente no existe una forma sencilla de eliminar
un estado. Hay un ejemplo sobre cómo llevar a cabo estos cambios en el tema `alavetelitheme`.

Para añadir estados, cree dos módulos en su tema,
`InfoRequestCustomStates` y `RequestControllerCustomStates`. El primero
debe contener estos métodos:

* `theme_calculate_status`: devuelve una etiqueta para identificar el estado actual de la solicitud.
* `theme_extra_states`: devuelve una lista de etiquetas para identificar los estados adicionales que desea soportar.
* `theme_display_status`: devuelve cadenas de texto legibles por humanos correspondientes a dichas etiquetas.

El segundo debe contener el siguietne método:

* `theme_describe_state`: devuelve un aviso para el usuario correspondiente
  tras haber clasificado una solicitud y lo redirige a la página siguiente correspondiente.

Una vez añadidos los estados adicionales, necesitará crear los siguientes archivos en su tema:

* `lib/views/general/_custom_state_descriptions.html.erb`: descripciones sobre
  sus nuevos estados, adecuadas para mostrar a usuarios finales.
* `lib/views/general/_custom_state_transitions_complete.html.erb`:
  descripciones de estados nuevos que desee caracterizar como estados de
  «completación», para mostrar en el formulario de clasificación que requerimos
  que rellenen los solicitantes.
* `lib/views/general/_custom_state_transitions_pending.html.erb`: igual que el
  anterior, pero para estados nuevos que desee caracterizar como estados «pendientes».

Puede consultar ejemplos de estas personalizaciones en
[este commit](https://github.com/sebbacon/informatazyrtare-theme/commit/2b240491237bd72415990399904361ce9bfa431d)
para la versión de Kosovo de Alaveteli, Informata Zyrtare (ignore el
archivo `lib/views/general/_custom_state_transitions.html.erb`, no se utiliza).

## Añadir nuevas páginas en la navegación

`alavetelitheme/lib/config/custom-routes.rb` le permite extender las rutas básicas de
Alaveteli. El ejemplo de `alavetelitheme` añade una página de ayuda adicional.
También peude utilizar esta función para sobrescribir el comportamiento de páginas
especificas, si es necesario.

## Añadir o sobrescribir modelos o controladores

Si necesita añadir o extender el comportamiento de Alaveteli a nivel de modelo o controlador, consulte `alavetelitheme/lib/controller_patches.rb` y `alavetelitheme/lib/model_patches.rb` para obtener algunos ejemplos.

## Trabajar con temas

Puede utilizar [`script/switch-theme.rb`](https://github.com/mysociety/alaveteli/blob/master/script/switch-theme.rb) para definir el tema actual, si está trabajando con múltiples temas. Esta opción puede resultar útil para cambiar entre el tema predeterminado `alavetelitheme` y uno de su propia adaptación.
