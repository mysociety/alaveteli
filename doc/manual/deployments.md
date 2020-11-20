---
layout: landing
title: Deployments
redirect_from: /about/where-has-alaveteli-been-installed/
---
<div class="deployments__intro">
    <div class="container">
    <h1>{{ site.languages }}+ languages, {{ site.jurisdictions }} jurisdictions
    <span>{{ site.requests }} requests for information</span></h1>
    <p>Alaveteli can help open up government in any country,
in any language, and within any legislation</p>
    </div>
</div>

<div class="deployments__content">
    <div class="container">
        <h2>Deployments of Alaveteli</h2>
        <div class="row">
          {% assign major_deployments = site.data.deployments | where: "featured", "true" %}
          {% for deployment in major_deployments %}
            <div class="col-md-6">
                {% include deployment-major.html title=deployment.title url=deployment.url image=deployment.image country=deployment.country.en description=deployment.description.en pro=deployment.pro %}
            </div>
          {% endfor %}
        </div>
        <div class="row">
          {% assign minor_deployments = site.data.deployments | where: "featured", "false" %}
          {% for deployment in minor_deployments %}
            <div class="col-6 col-sm-4 col-md-3 col-lg-2">
                {% include deployment-minor.html title=deployment.title url=deployment.url image=deployment.image country=deployment.country.en pro=deployment.pro %}
            </div>
          {% endfor %}
        </div>
    </div>
</div>


<div class="get-started">
  <div class="container">
    <h2>Get started</h2>
    <div class="get-started__grid-unit get-started__grid-unit--wide">
        <div class="get-started__item get-started__item--primary">
            <p>From team members to maintenance, our get started guide will walk you through the process of planning, starting and running your own Alaveteli website</p>
            <p><a href="{{ page.baseurl }}/docs/getting_started/" class="button">Get started</a></p>
        </div>
    </div><!--
    --><div class="get-started__grid-unit">
        <div class="get-started__item get-started__item">
            <h3>Get the code</h3>
            <p>Alaveteli is open source and available to view, download and modify on GitHub</p>
            <p><a href="https://github.com/mysociety/alaveteli/" class="button">Github</a></p>
        </div>
    </div><!--
    --><div class="get-started__grid-unit">
        <div class="get-started__item get-started__item">
            <h3>Speak to us</h3>
            <p>Need some help? Tell us about your plans</p>
            <p class="push-top"><a href="{{ page.baseurl }}/community" class="button">Get in touch</a></p>
        </div>
    </div>
  </div>
</div>
