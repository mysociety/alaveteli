---
layout: es/page
title: Estados de solicitud
---

# Estados de solicitud

<p class="lead">
  Una <a href="{{ page.baseurl }}/docs/glossary/#request" class="glossary__link">solicitud</a>
  atraviesa distintos <strong>estados</strong> durante su proceso. Estos pueden variar
  de una jurisdicción a otra.
</p>

Los estados de solicitud están definidos en el código de Alaveteli y le recomendamos su
uso (siempre que concuerden con la <a href="{{ page.baseurl }}/docs/glossary/#foi"
class="glossary__link">ley de información pública</a> de su propia jurisdicción). Pero si necesita
personalizarlos, puede consultar la
<a href="{{ page.baseurl }}/docs/customising/themes/#personalizar-los-estados-de-solicitud">personalización de los estados de solicitud</a>
para obtener más información.

## Ejemplo de WhatDoTheyKnow

Las solicitudes efectuadas en el sitio basado en Alaveteli del Reino Unido, [WhatDoTheyKnow](https://www.whatdotheyknow.com),
pueden hallarse en cualquiera de los estados descritos a continuación.

Su sitio no tiene por qué utilizar los mismos estados que utiliza WhatDoTheyKnow. Por ejemplo,
el sitio de Kosovo utiliza unos estados ligeramente distintos: consulte
[esta comparación de las diferencias entre ambos]({{ page.baseurl }}/docs/customising/states_informatazyrtare/).

### Estados

<ul class="definitions">
  <li><a href="#waiting_response">waiting_response</a></li>
  <li><a href="#waiting_classification">waiting_classification</a></li>
  <li><a href="#waiting_response_overdue">waiting_response_overdue</a></li>
  <li><a href="#waiting_response_very_overdue">waiting_response_very_overdue</a></li>
  <li><a href="#waiting_clarification">waiting_clarification</a></li>
  <li><a href="#gone_postal">gone_postal</a></li>
  <li><a href="#not_held">not_held</a></li>
  <li><a href="#rejected">rejected</a></li>
  <li><a href="#successful">successful</a></li>
  <li><a href="#partially_successful">partially_successful</a></li>
  <li><a href="#internal_review">internal_review</a></li>
  <li><a href="#error_message">error_message</a></li>
  <li><a href="#requires_admin">requires_admin</a></li>
  <li><a href="#user_withdrawn">user_withdrawn</a></li>
  <li><a href="#awaiting_description">awaiting_description</a></li>
</ul>


<dl class="glossary">

  <dt>
    <a name="waiting_response">waiting_response</a>
  </dt>
  <dd>
    Esperando a que la autoridad pública responda.
    <ul>
      <li>Estado inicial por defecto.</li>
      <li>No se puede pasar a este estado desde internal_review.</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_classification">waiting_classification</a>
  </dt>
  <dd>
    Esperando la clasificación de una respuesta.
    <ul>
      <li>Estado por defecto tras recibir una respuesta.</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_response_overdue">waiting_response_overdue</a>
  </dt>
  <dd>
    Se ha esperado una respuesta durante demasiado tiempo.
    <ul>
      <li>Automático, si la fecha actual coincide con la fecha de la solicitud + festivos + 20 días.</li>
      <li>Cuando un usuario actualiza/visita un elemento en este estado, se le da las gracias y se le indica cuánto tiempo debería tener que esperar.</li>
      <li>Se alerta al usuario por correo cuando alguna solicitud se halla fuera de plazo.</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_response_very_overdue">waiting_response_very_overdue</a>
  </dt>
  <dd>
    Se ha esperado una respuesta durante muchísimo tiempo.
    <ul>
      <li>Automático, si la fecha actual coincide con la fecha de la solicitud + festivos + (60 días (para escuelas) o 40 días (todos los demás)).</li>
      <li>Cuando un usuario actualiza/visita un elemento en este estado, se le sugiere que efectúe una reclamación, mostrando las acciones que puede emprender.</li>
      <li>Se alerta al usuario por correo cuando alguna solicitud se halla en este estado.</li>
    </ul>
  </dd>

  <dt>
    <a name="waiting_clarification">waiting_clarification</a>
  </dt>
  <dd>
    La autoridad pública solicita una explicación sobre una parte de la solicitud.
    <ul>
      <li>Se envía una petición al usuario para que incluya información al respecto.</li>
      <li>Si el usuario envía un mensaje saliente en una solicitud en este estado, esta pasa automáticamente al estado {{waiting_response}}.</li>
      <li>Tres días más tarde de pasar a este estado, se envía un recordatorio al usuario para que actúe al respecto (suponiendo que el usuario no está bloqueado).</li>
      <li>No es posible pasar a este estado desde internal_review.</li>
    </ul>
  </dd>

  <dt>
    <a name="gone_postal">gone_postal</a>
  </dt>
  <dd>
    La autoridad pública desea responder o ha respondido por correo postal.
    <ul>
      <li>Si está seleccionado este estado, se recuerda al usuario que en numerosos casos la autoridad debería responder por correo electrónico y se le anima a insistir.</li>
      <li>Se proporciona la dirección de correo electrónico más reciente de la autoridad al usuario para que se solicite la comunicación postal por correo electrónico privado.</li>
      <li>Se anima al usuario a actualizar la solicitud con una anotación en una fecha posterior.</li>
    </ul>
  </dd>

  <dt>
    <a name="not_held">not_held</a>
  </dt>
  <dd>
    La autoridad pública no dispone de la información solicitada.
    <ul>
      <li>Se sugiere al usuario que pruebe con una autoridad diferente o que efectúe una reclamación.</li>
    </ul>
  </dd>

  <dt>
    <a name="rejected">rejected</a>
  </dt>
  <dd>
    La solicitud ha sido rechazada por la autoridad pública.
    <ul>
      <li>Se muestra la página de posibles pasos a seguir.</li>
    </ul>
  </dd>


  <dt>
    <a name="successful">successful</a>
  </dt>
  <dd>
    Se ha recibido toda la información solicitada.
    <ul>
      <li>Se sugiere que el usuario añada un comentario o haga una donación.</li>
    </ul>
  </dd>


  <dt>
    <a name="partially_successful">partially_successful</a>
  </dt>
  <dd>
    Se ha recibido parte de la información solicitada.
    <ul>
      <li>Se sugiere al usuario que haga una donación y se ofrecen ideas sobre qué pasos seguir.</li>
    </ul>
  </dd>

  <dt>
    <a name="internal_review">internal_review</a>
  </dt>
  <dd>
    Esperando a que la autoridad pública complete una revisión interna de su gestión respecto a la solicitud.
    <ul>
      <li>Se indica al usuario que debería esperar una respuesta dentro de los primeros 20 días.</li>
      <li>Cuando se envía un correo a la autoridad, se añade «Revisión interna de» en el asunto.</li>
      <li>Se puede pasar a este estado desde el formulario de seguimiento.</li>
    </ul>
  </dd>

  <dt>
    <a name="error_message">error_message</a>
  </dt>
  <dd>
    Se ha recibido un mensaje de error, por ejemplo, un fallo de entrega.
    <ul>
    <li>Se da las gracias al usuario por informar sobre el tema y se sugiere el uso de un formulario para que proporcione una nueva dirección de correo de la autoridad, si este es el problema.</li>
    <li>Se marca para revisión por parte de un administrador.</li>
    </ul>
  </dd>

  <dt>
    <a name="requires_admin">requires_admin</a>
  </dt>
  <dd>
    Una respuesta extraña que requiere atención por parte del equipo de WhatDoTheyKnow.
    <ul>
    <li>Un usuario se confunde y no sabe qué estado asignar para que intervenga un administrador.</li>
    <li>Se redirige al usuario a un formulario para solicitar más información.</li>
    <li>Se marca para revisión por parte de un administrador.</li>
    </ul>
  </dd>

  <dt>
    <a name="user_withdrawn">user_withdrawn</a>
  </dt>
  <dd>
    El solicitante ha abandonado la solicitud por algún motivo.
    <ul>
      <li>Se solicita al usuario que escriba un mensaje para avisar a la autoridad.</li>
    </ul>
  </dd>

  <dt>
    <a name="awaiting_description">awaiting_description</a>
  </dt>
  <dd>
    El awaiting_description no es realmente de un estado, sino de un distintivo que indica que no hay ningún estado.
  </dd>

</dl>

