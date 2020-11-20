---
layout: es/landing
title: Implementaciones
---
<meta charset="utf-8">

<div class="deployments__intro">
    <div class="container">
    <h1>Más de {{ site.languages }} idiomas, {{ site.jurisdictions }} jurisdicciones
    <span>{{ site.requests | replace: ",", "." }} solicitudes de información</span></h1>
    <p>Alaveteli puede colaborar en la transparencia del gobierno en cualquier país,
en cualquier idioma y dentro de cualquier marco legal</p>
    </div>
</div>

<div class="deployments__content">
    <div class="container">
        <h2>Implementaciones de Alaveteli</h2>
        <div class="row">
          {% assign major_deployments = site.data.deployments | where: "featured", "true" %}
          {% for deployment in major_deployments %}
            <div class="col-md-6">
                {% include deployment-major.html title=deployment.title url=deployment.url image=deployment.image country=deployment.country.es description=deployment.description.es pro=deployment.pro %}
            </div>
          {% endfor %}
        </div>
        <div class="row">
          {% assign minor_deployments = site.data.deployments | where: "featured", "false" %}
          {% for deployment in minor_deployments %}
            <div class="col-6 col-sm-4 col-md-3 col-lg-2">
                {% include deployment-minor.html title=deployment.title url=deployment.url image=deployment.image country=deployment.country.es pro=deployment.pro %}
            </div>
          {% endfor %}
        </div>
    </div>
</div>


<div class="get-started">
  <div class="container">
    <h2>Primeros pasos</h2>
    <div class="get-started__grid-unit get-started__grid-unit--wide">
        <div class="get-started__item get-started__item--primary">
            <p>Desde los miembros del equipo hasta los encargados de mantenimiento, nuestra guía de inicio recorre todo el proceso de planificación, inicio y gestión de su propio sitio web basado en Alaveteli</p>
            <p><a href="{{ page.baseurl }}/docs/getting_started/" class="button">Primeros pasos</a></p>
        </div>
    </div><!--
    --><div class="get-started__grid-unit">
        <div class="get-started__item get-started__item">
            <h3>Obtenga el código</h3>
            <p>Alaveteli es de código abierto y está disponible para su consulta, descarga y modificación en GitHub</p>
            <p><a href="https://github.com/mysociety/alaveteli/" class="button">Github</a></p>
        </div>
    </div><!--
    --><div class="get-started__grid-unit">
        <div class="get-started__item get-started__item">
            <h3>Hable con nosotros</h3>
            <p>¿Necesita ayuda? Coméntenos sus planes</p>
            <p class="push-top"><a href="{{ page.baseurl }}/community" class="button">Póngase en contacto</a></p>
        </div>
    </div>
  </div>
</div>
