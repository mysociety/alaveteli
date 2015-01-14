---
layout: es/page
title: Traducción
---

# Traducción de Alaveteli

<p class="lead">
	Hemos diseñado Alaveteli para ser utilizado en numerosas jurisdicciones
	diferentes de todo el mundo. Si aún no soporta el idioma que necesita, puede
	ayudar a traducirlo. Esta página explica cómo.
</p>

## ¡Alaveteli ya incluye traducciones!

Alaveteli incluye varias versiones en distintos idiomas listas para su uso.
Si Alaveteli ya se ha traducido al idioma (o idiomas) que necesita, solo
deberá configurarlo: consulte
[`AVAILABLE_LOCALES`]({{ page.baseurl }}/docs/customising/config/#available_locales).

[Consulte el directorio `locale/`](https://github.com/mysociety/alaveteli/tree/master/locale)
para ver qué traducciones hay actualmente disponibles. Algunas son traducciones completas del
sitio, mientras que otras son parciales, bien porque las traducciones aún no se han finalizado,
o bien porque los traductores no han actualizado los textos desde la última vez que los
desarrolladores añadieron texto al sitio.

Existen dos motivos por los que la traducción puede necesitar más trabajo antes de poder utilizarse:

* **El idioma que desea no es uno de los que ya tenemos** <br> En este caso
  no habrá ninguna entrada en ``locale/`` para este idioma porque Alaveteli aún
  no ha sido traducido a su idioma por nadie. Consulte el resto de esta
  página para averiguar cómo añadir una nueva traducción.

* **La traducción a su idioma está incompleta o atrasada** <br>
  Este estado puede deberse simplemente a que es una tarea en proceso. Además, a veces
  una traducción incompleta ya cubre todas las áreas del sitio que necesita.
  Por supuesto, puede añadir contenido a una traducción parcial, pero es una buena idea
  consultarnos primero, ya que seguramente sabremos quién está trabajando en la traducción
  actual y el estado de dicha traducción.

Los traductores son miembros de la
[comunidad]({{ page.baseurl }}/community/) de Alaveteli y a menudo trabajan con
independencia de los desarrolladores. Por tanto, las traducciones pueden retrasarse
bastante respecto al código. Sin embargo, nuestro proceso de actualización incluye
una «detección de la traducción», que ofrece a los traductores la oportunidad de 
ponerse al día. Consulte el resto de esta página para obtener más información.

## Traducciones de Alaveteli

No necesita ser programador para traducir Alaveteli, pues utilizamos un sitio web
externo llamado Transifex para ayudar en la gestión de las traducciones. Así se facilita
el trabajo de los traductores, pero significa que su equipo técnico necesitará realizar
cierto trabajo adicional para incluir las traducciones resultantes de vuelta en 
Alaveteli, una vez se hallen disponibles.

El proyecto Transifex se halla en
[https://www.transifex.net/projects/p/alaveteli](https://www.transifex.net/projects/p/alaveteli).
Probablemente le interese crear una cuenta (pregunte en la lista de correo). Esta plataforma ofrece una
interfaz de uso sencillo para contribuir en las traducciones.

Alaveteli localiza cadenas de texto mediante el uso de gettext de GNU y
<a href="{{ page.baseurl }}/docs/glossary/#po" class="glossary__link">archivos <code>.pot</code> y <code>.po</code></a>.
Si es un desarrollador, debería consultar la
[internacionalización de Alaveteli]({{ page.baseurl }}/docs/developers/i18n/).


## Qué necesita hacer un traductor

**Si solamente está trabajando en la traducción de Alaveteli a un idioma que conoce,
esta es la sección que debe consultar.**

> Recuerde que Alaveteli
> [ya incluye algunas traducciones](#alaveteli-already-contains-translations),
> por lo que se recomienda que compruebe primero si realmente necesita efectuar la traducción.
> ¡Tal vez alguien haya traducido ya Alaveteli al idioma que necesita!

Cuando un desarrollador añade una nueva funcionalidad a la interfaz de usuario de Alaveteli,
utiliza cierto código para destacar las frases o palabras (cadenas de texto o «strings»)
que considera que deben traducirse.

Cuando el
<a href="{{ page.baseurl }}/docs/glossary/#release" class="glossary__link">gestor de actualizaciones</a>
de Alaveteli planee una nueva actualización, cargará una plantilla que contenga todas las
cadenas de texto que deben traducirse (conocida como
<a href="{{ page.baseurl }}/docs/glossary/#po" class="glossary__link">archivo <code>.pot</code></a>)
en Transifex. Así sus propias traducciones en Transifex se actualizarán con las últimas
cadenas de texto.

Al visitar Transifex, la plataforma le invitará a rellenar los valores para todas las
cadenas de texto nuevas o modificadas. Cuando una cadena haya sido ligeramente modificada,
por ejemplo, solamente en la puntuación (de «Hello» a «Hello!»), Transifex
sugerirá una traducción adecuada (busque la pestaña de sugerencias, *Suggestions*,
debajo de la cadena de texto original).

Para que esta característica funcione correctamente, el gestor de actualizaciones debe
descargar sus traducciones, ejecutar un programa que inserta las sugerencias y después
cargarlas de nuevo. Por tanto, cuando se anuncie una nueva actualización candidata, asegúrese de
haber cargado todas las traducciones pertinentes o las perderá.

Cuando se informa de una nueva actualización, se entra en un periodo de **detención de la traducción**:
durante este periodo los desarrolladores no deben añadir ninguna cadena de texto nueva al software, así
que puede confiar en que está traduciendo todo lo que habrá en la versión final.

El gestor de actualizaciones también le indicará la **fecha límite de traducción**. Después de esta fecha
puede continuar contribuyendo en nuevas traducciones, pero ya no se incluirán en la versión actual.


### Notas generales sobre la traducción en Transifex

Algunas cadenas tendrán comentarios adjuntos a ellas introducidos por los desarrolladores de
Alaveteli sobre el contexto donde aparece el texto dentro de la aplicación. Estos comentarios
aparecen en la pestaña de detalles *Details* del texto en Transifex.

Algunas cadenas incluirán **placeholders** (marcadores de contenido) para indicar que Alaveteli
insertará algo de texto por sí mismo cuando las muestre. Estarán rodeados de
llaves dobles y tendrán este aspecto:

<code>
    some text with a &#123;&#123;placeholder&#125;&#125; in it
</code>
    
En estas cadenas no deberá traducir estos elementos. Necesitan mantenerse
exactamente del mismo modo en que se presentan para que el texto pueda insertarse
correctamente:

<code>
    algo de texto con un &#123;&#123;placeholder&#125;&#125; en él
</code>

Análogamente, algunas cadenas pueden contener pequeños fragmentos de código HTML, que se
mostrarán entre corchetes angulares (es probable que indiquen que el texto es un enlace o que 
necesita un formato especial). Por ejemplo: 

<code>
    please &lt;a href=\"&#123;&#123;url&#125;&#125;\"&gt;send it to us&lt;/a&gt;
</code>

Del mismo modo, no deberá editar estos fragmentos entre corchetes. Manténgalos en la 
traducción y edite solamente el texto a su alrededor. Así, el ejemplo se convertiría en:

<code>
    por favor &lt;a href=\"&#123;&#123;url&#125;&#125;\"&gt;envíenoslo&lt;/a&gt;
</code>

Algunas cadenas de texto se hallan en forma de dos porciones de texto separadas por una barra vertical
(`|`), por ejemplo: `IncomingMessage|Subject`. Esta barra representa nombres de atributos, de forma que
`IncomingMessage|Subject` es el atributo correspondiente al asunto («Subject») de un mensaje entrante («IncomingMessage»)
en el sitio. No priorice estos tipos de texto al traducir, pues actualmente no aparecen en 
ningún lugar del sitio y, al hacerlo, solo se utilizan dentro de la interfaz de administración. Si los traduce,
solo debe modificar el texto situado *después* de las barras `|`.


## Cómo se incorporan las traducciones en Alaveteli

Para incorporar las cadenas te texto traducidas de Transifex en Alaveteli, siga las 
instrucciones indicadas en estas [notas de implementación]({{ page.baseurl }}/docs/developers/i18n/#notas-de-implementacin).
Este trabajo corresponde al departamento técnico de su equipo (o incluso al
gestor de actualizaciones de mySociety). Si los traductores no disponen de conocimientos técnicos,
pueden utilizar Transifex sin preocuparse por este tema.


## Desarrolladores e internacionalización

Si está escribiendo código nuevo para Alaveteli, es un desarrollador
y necesita entender cómo generar el texto para facilitar el trabajo de los
traductores. Consulte la página sobre la
[internacionalización de Alaveteli]({{ page.baseurl }}/docs/developers/i18n/).

Si es un desarrollador o traductor que está trabajando activamente en la internacionalización
del código de Alaveteli, debería hablar con nosotros para averiguar cuándo está programada la
próxima actualización, con el objetivo de preparar sus traducciones a tiempo para que se incluyan en ella.

