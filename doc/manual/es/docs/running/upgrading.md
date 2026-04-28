---
layout: es/page
title: Actualización
---
Actualización de Alaveteli
====================

<p class="lead">
  Alaveteli se halla en desarrollo activo; no permita que la versión que utiliza se retrase
  demasiado respecto a nuestra última
  <a href="{{ page.baseurl }}/docs/glossary/#release" class="glossary__link">actualización</a>.
  Esta página describe cómo mantener su sitio actualizado.
</p>

## Cómo actualizar el código

* Si utiliza Capistrano para la implementación,
  simplemente [despliegue el código]({{ page.baseurl }}/docs/installing/deploy/#uso):
  defina el repositorio y la rama en `deploy.yml` en función a la versión que desee.
  Le recomendamos que establezca estos valores con el nombre explícito de la etiqueta (por ejemplo,
  `0.18` y no `master`) para que no exista ningún riesgo de desplegar por error
  una nueva versión antes de ser consciente de que se ha publicado.
* Si no, puede actualizar ejecutando `git pull`.

## Ejecutar el script posterior al despliegue

A menos que utilice [Capistrano para la implementación]({{ page.baseurl }}/docs/installing/deploy/),
siempre debería ejectuar el script `script/rails-post-deploy` después de cada
despliegue. Dicho script efectúa todas las migraciones de bases de datos, además de otras
diversas tareas que pueden automatizarse en el despliegue.

## Números de versión de Alaveteli

Alaveteli utiliza una versión modificada de [semver](http://semver.org).

- Serie `W`
- Mayor `X`
- Menor `Y`
- Parche `Z`

En el momento de redacción de esta documentación, la versión actual es `0.19.0.6`:

- Serie `0`
- Mayor `19`
- Menor `0`
- Parche `6`

Alaveteli evolucionará a la especificación de [semver](http://semver.org) al alcanzar `1.0.0`.

## La rama maestra contiene la última versión estable

La política del equipo de desarrollo indica que la rama maestra `master` siempre debe
contener la última versión estable; así que, si extrae los datos de la rama `master`,
siempre estará actualizado. Sin embargo, debería saber exactamente qué versión se está
ejecutando en su
<a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">servidor
de producción</a> e implementar Alaveteli a partir de una [etiqueta de versión
*específica*](https://github.com/mysociety/alaveteli/releases).

Es posible que la actualización solo requiera obtener el código más actual, pero tal vez también
necesite efectuar otros cambios («acciones adicionales»). Debido a este motivo, para todo lo que no se trate
de un *parche* (consulte la información inferior), lea siempre el documento
[`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md)
**antes** de efectuar una actualización. De este modo podrá preparar otros posibles cambios que puedan
ser necesarios para que el código nuevo funcione.

## Parches

Los aumentos de versión de parche (por ejemplo, 0.1.2.3 &rarr; 0.1.2.**4**) no deberían requerir ninguna acción adicional por su parte. Serán retrocompatibles con la versión menor actual.

## Actualizaciones menores

Los aumentos menores de versión (por ejemplo, 0.1.2.4 &rarr; 0.1.**3**.0) habitualmente requerirán acciones adicionales. Debería leer el documento [`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md) para ver qué ha cambiado desde su último despliegue, prestando especial atención a todo lo indicado 
en las secciones «notas de actualización».

Toda actualización puede incluir nuevas cadenas de texto de traducción, ya sean mensajes nuevos o modificados
para el usuario, que necesitan traducirse para su localización. Debería visitar Transifex
e intentar conseguir su traducción al 100% en cada actualización. Al no conseguirlo,
cualquier palabra añadida al código fuente de Alaveteli aparecerá en su sitio web
en inglés por defecto. Si sus traducciones no alcanzaron la última versión,
deberá descargar el archivo actualizado `app.po` para su localización
desde Transifex y guardarlo en la carpeta `locale/`.

Las actualizaciones menores serán retrocompatibles con la versión mayor actual.

## Actualizaciones mayores

Los aumentos mayores de versión (por ejemplo, 0.1.2.4 &rarr; 0.**2**.0.0) habitualmente requerirán acciones adicionales. Debería leer el documento [`CHANGES.md`](https://github.com/mysociety/alaveteli/blob/master/doc/CHANGES.md) para ver qué ha cambiado desde su último despliegue, prestando especial atención a todo lo indicado 
en las secciones «notas de actualización».

Solamente las actualizaciones mayores pueden eliminar funcionalidades existentes. Recibirá alertas respecto a la eliminación de funcionalidades con una advertencia sobre características obsoletas en una actualización menor previa antes de que la actualización mayor elimine las funcionalidades.

## Actualizaciones de serie

Estas actualizaciones vienen acompañadas de instrucciones especiales.

## Advertencias sobre características obsoletas

Es posible que empiece a ver advertencias sobre características obsoletas en su registro de aplicación. Tendrán este aspecto:

    DEPRECATION WARNING: Object#id will be deprecated; use Object#object_id

Las advertencias sobre características obsoletas nos permiten comunicarle que algunas funcionalidades se modificarán o eliminarán en una actualización futura de Alaveteli.

### Qué hacer al ver una advertencia sobre características obsoletas

Normalmente verá una advertencia sobre características obsoletas si ha estado utilizando una funcionalidad en su tema que se va a modificar o eliminar próximamente. La advertencia debería proporcionarle suficientes explicaciones sobre qué hacer con ella. En general se trata siempre de eliminar o modificar métodos. El [registro de cambios](https://github.com/mysociety/alaveteli/blob/develop/doc/CHANGES.md) incluirá información más detallada sobre características obsoletas y sobre cómo llevar a cabo las modificaciones pertinentes.

Si tiene alguna consulta, no dude en preguntar en la [lista de correo de desarrollo](https://groups.google.com/group/alaveteli-dev) o en [el canal IRC de Alaveteli](http://www.irc.mysociety.org/).

### ¿Cuándo se efectuará el cambio?

Introducimos advertencias sobre características obsoletas en una actualización **menor**. La actualización **mayor** posterior efectuará el cambio, a menos que se indique de otra manera en la advertencia.
