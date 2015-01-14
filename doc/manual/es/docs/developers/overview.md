---
layout: es/page
title: Vista general de alto nivel
---

# Vista general de alto nivel

<p class="lead">
    Esta página describe el proceso y las entidades que forman Alaveteli.
    Es una vista de alto nivel sobre cómo trabaja Alaveteli para ayudarle a orientarse respecto al código.
</p>

_Consulte también el [esquema](#esquema) en la parte inferior de esta página._

La entidad principal es **InfoRequest**, que representa una solicitud de información por parte de un
**User** a un **PublicBody**. Una nueva InfoRequest resulta en un **OutgoingMessage** inicial, que
representa el primer correo electrónico.

Una vez elaborada una InfoRequest, se monitoriza su estado mediante **InfoRequestEvents**. Por
ejemplo, el estado inicial de una nueva InfoRequest es `awaiting_response` y cuenta con un
InfoRequestEvent asociado del tipo `initial_request`. Un evento de InfoRequest puede disponer de
un OutgoingMessage o de un IncomingMessage, así como no tener ninguno asociado.

Las respuestas son recibidas por el sistema mediante el flujo de mensajes de correo de tipo raw (representados por **RawEmail**)
desde el MTA en un script ubicado en `scripts/mailin`. Esta acción analiza el correo, intenta identificar la
InfoRequest asociada y genera un **IncomingMessage**, que hace referencia tanto al RawEmail como a la InfoRequest.

Cualquier User puede elaborar **Comments** en las InfoRequests.

Todos los eventos (por ejemplo, Comments y OutgoingMessages) son monitorizados en InfoRequestEvent.

Una **TrackThing** consiste en una búsqueda delimitada que permite a los usuarios recibir alertas cuando se encuentran
eventos coincidentes con sus criterios. (Su funcionamiento cambió después de que lo lanzáramos, así que
aún existe código obsoleto propio de características que hemos descartado).

El **MailServerLog** representa los archivos de registro analizados por el MTA. Las entradas del
MailServerLog son creadas por un administrador de tipo cron que ejecuta
`scripts/load-mail-server-logs`. Esta acción comprueba los correos entrantes y los asocia con las
InfoRequests; después `script/check-recent-requests-send` comprueba estos registros para garantizar que
cuentan con información de remitente (envelope-from) en el encabezado (con el objetivo de combatir el spam).

## Esquema

<a href="{{ site.baseurl }}assets/img/railsmodels.png"><img src="{{ site.baseurl }}assets/img/railsmodels.png"></a>

Este esquema de los modelos de Rails fue generado a partir del código el 19 de diciembre de 2012 utilizando
[Railroad](http://railroad.rubyforge.org/).

El comando de railroad es: `railroad -M | dot -Tpng > railsmodels.png`
