---
layout: es/page
title: Estados de solicitud (InformataZyrtare)
---

# Estados de solicitud: comparación de ejemplo

<p class="lead">
  Esta página muestra las diferencias entre los estados utilizados en dos implementaciones
  distintas de Alaveteli: una en Kosovo y otra en Reino Unido. Se trata de un ejemplo
  práctico que muestra que es posible personalizar los estados que su sitio utiliza.
</p>

Los estados des solicitud están definidos en el código de Alaveteli y le recomendamos 
utilizarlos (siempre que concuerden con la <a href="{{ page.baseurl }}/docs/glossary/#foi"
class="glossary__link">ley de información pública</a> de su propia jurisdicción).

## Ejemplo de InformataZyrtare.org (Kosovo)

Las solicitudes realizadas en la implementación de Alaveteli de Kosovo,
[InformataZyrtare](http://informatazyrtare.org), utilizan unos estados ligeramente diferentes
a los utilizados en la implementación de Reino Unido, [WhatDoTheyKnow](http://www.whatdotheyknow.com)
(WDTK).

En general estas diferencias se deben a que la legislación local o el modo en que funcionan
los grupos que gestionan los sitios son distintos y se hallan en distintos lugares. Alavateli
facilita los cambios permitiendo personalizar los estados que se utilizan.

Este ejemplo muestra claramente que puede utilizar distintos estados dependiendo de sus 
requisitos locales y el aspecto que pueden tener. Consulte la [personalización de los estados
de solicitud]({{ page.baseurl }}/docs/customising/themes/) para obtener detalles sobre cómo hacerlo.

### Estados utilizados por InformataZyrtare, pero no por WDTK

   * <a href="#deadline_extended">deadline_extended</a>
   * <a href="#partial_rejected">partial_rejected</a>
   * <a href="#wrong_response">wrong_response</a>

### Estados utilizados por WDTK, pero no por InformataZyrtare

   * <a href="{{ page.baseurl }}/docs/customising/states/#awaiting_description">awaiting_description</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#gone_postal">gone_postal</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#internal_review">internal_review</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#user_withdrawn">user_withdrawn</a>
   * <a href="{{ page.baseurl }}/docs/customising/states/#waiting_response_very_overdue">waiting_response_very_overdue</a>

Para obtener más información, consulte todos los [estados utilizados por WhatDoTheyKnow]({{ page.baseurl }}/docs/customising/states/).


---

&nbsp;

### Detalles de los estados de InformataZytare

Los estados no representados dentro de los [estados de WDTK]({{ page.baseurl }}/docs/customising/states/) 
se describen aquí más detalladamente:

<ul class="definitions">
  <li><a href="#deadline_extended">deadline_extended</a></li>
  <li><a href="#partial_rejected">partial_rejected</a></li>
  <li><a href="#wrong_response">wrong_response</a></li>
</ul>

<dl class="glossary">
  <dt>
    <a name="deadline_extended">deadline_extended</a>
  </dt>
  <dd>
      La autoridad ha solicitado una extensión del tiempo disponible para responder.
  </dd>
  <dt>
    <a name="partial_rejected">partial_rejected</a>
  </dt>
  <dd>
      Solo se ha rechazado parte de la solicitud, pero la parte satisfactoria de la solicitud
      no se ha adjuntado.
  </dd>
  <dt>
    <a name="wrong_response">wrong_response</a>
  </dt>
  <dd>
    La autoridad ha respondido, pero la respuesta no corresponde a la solicitud realizada.
  </dd>

</dl>

