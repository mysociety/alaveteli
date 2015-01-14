---
layout: es/page
title: API
---

# API de Alaveteli 

<p class="lead">
    Existen dos partes del API para acceder a datos o insertarlos programáticamente: el API de lectura y el API de escritura.
</p>

## API de lectura

Se proporciona a través de las versiones JSON de la mayoría de las entidades del sistema, así como mediante
fuentes de difusión Atom para las entidades de listados:

### Fuentes de difusión Atom

Hay fuentes Atom en la mayoría de páginas que incluyen listados de solicitudes de información pública,
que pueden utilizarse para recibir actualizaciones y enlaces en formato XML. Puede encontrar la URL de la fuente Atom de
las siguientes maneras:

* Busque los enlaces de la fuente RSS.
* Examine la etiqueta `<link rel="alternate" type="application/atom+xml">` en el encabezado del código HTML.
* Añada `/feed` al inicio de otra URL.

Incluso las solicitudes complejas de búsqueda cuentan con fuentes Atom. Puede utilizarlas de múltiples maneras,
por ejemplo, para realizar búsquedas por autoridad, por tipo de archivo, por intervalo de fechas o por estado.
Consulte los consejos de búsqueda avanzada para obtener más información.

### Datos JSON estructurados

Hay unas cuantas páginas con versiones JSON, que permiten descargar información sobre
objetos de forma estructurada. Puede encontrarlas de los siguientes modos:

* Añada `.json` al final de la URL.
* Busque la etiqueta `<link rel="alternate" type="application/json">` en el encabezado del código HTML.

Los usuarios, autoridades y solicitudes disponen de versiones JSON que contienen información
básica sobre ellos. Cada fuente Atom tiene su equivalente en JSON, que incluye información
sobre el listado de eventos de la fuente.

### Iniciar nuevas solicitudes programáticamente

Para animar a los usuarios a crear enlaces hacia una autoridad pública en particular, utilice direcciones URL
con el formato `http://<susitio>/new/<nombre_url_organismopublico>`. Estos son los
parámetros que puede añadir a estas URL, ya sea propiamente en la URL o a partir de un formulario:

* `title`: resumen por defecto de la nueva solicitud.
* `default_letter`: texto por defecto del cuerpo de la carta. El saludo y la firma locales lo rodean.
* `body`: constituye una alternativa a `default_letter` y permite editar el texto completo de la solicitud, permitiendo modificar el saludo y la firma.
* `tags`: lista de etiquetas separada por espacios que permite encontrar y enlazar cualquier solicitud realizada posteriormente, por ejemplo `openlylocal spending_id:12345`. El símbolo `:` indica que se trata de una etiqueta de máquina. Los valores de las etiquetas de máquina también pueden incluir puntos, útiles para identificadores URI.

## API de escritura

El API de escritura está diseñada para ser utilizada por organismos públicos al crear sus propias
solicitudes en el sistema. Actualmente se utiliza en el software de [registro de información
pública](https://github.com/mysociety/foi-register) de mySociety para soportar el uso de
Alaveteli como registro de divulgación para toda actividad de información pública procedente de
un organismo público en concreto.

Todas las solicitudes deben incluir una clave del API como una variable `k`. Esta clave puede visualizarse
en cada una de las páginas de la autoridad desde la interfaz de administración. Otras variables deben
enviarse como se indica a continuación:

* `/api/v2/request`: ENVÍA los siguientes datos json como una variable de tipo formulario `json` para crear una nueva solicitud:
  * `title`: título de la solicitud.
  * `body`: cuerpo de la solicitud.
  * `external_user_name`: nombre de la persona que ha originado la solicitud.
  * `external_url`: URL donde puede encontrarse una copia canónica de la solicitud
  Devuelve contenido JSON con una `url` para la nueva solicitud junto con su `id`.
* `/api/v2/request/<id>.json`: RECIBE toda la información sobre una solicitud.
* `/api/v2/request/<id>.json`: ENVÍA correspondencia adicional respecto a una solicitud:
  * Como variable de tipo formulario `json`:
    * `direction`: `request` (solicitud procedente del usuario, por ejemplo, como seguimiento, recordatorio, etc.) o `response` (respuesta procedente de la autoridad).
    * `body`: mensaje.
    * `state`: opcional, permite que la autoridad incluya un valor de estado `state` de solicitud al enviar una actualización. Valores permitidos: `waiting_response` (esperando respuesta), `rejected` (rechazada), `successful` (satisfactoria) y `partially_successful` (parcialmente satisfactoria). Solo se utiliza en dirección `response` (respuesta).
    * `sent_at`: hora en la que se ha enviado la correspondencia en formato ISO-8601.
  * (Opcionalmente) la variable `attachments` (adjuntos) como `multipart/form-data`:
    * Elementos adjuntos en la correspondencia. Solo pueden adjuntarse en mensajes en dirección `response` (respuesta).
* `/api/v2/request/<id>/update.json`: ENVÍA un nuevo estado para la solicitud:
  * Como variable de tipo formulario `json`:
    * `state`: estimación por parte del usuario del `state` (estado) de una solicitud que ha recibido una respuesta de la autoridad. Valores permitidos:  `waiting_response` (esperando respuesta), `rejected` (rechazada), `successful` (satisfactoria) y `partially_successful` (parcialmente satisfactoria). Solo debería utilizarse para comentarios por parte del usuario; si una autoridad desea actualizar el estado `state`, debe utilizar `/api/v2/request/<id>.json` en su lugar.




