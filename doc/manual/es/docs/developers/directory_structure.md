---
layout: es/page
title: Estructura de directorios
---


# Estructura de directorios de Alaveteli

<p class="lead">Esta página ofrece una vista general sobre dónde encontrar distintos datos en
los directorios de Alaveteli.</p>

Si solo está instalando Alaveteli, **probablemente nunca necesite preocuparse de esto**;
es bastante más práctico cuando un desarrollador planea llevar a cabo cambios más
significativos en el código. No necesita estar familiarizado con
Ruby para realizar la instalación o aplicar [modificaciones básicas en
ella]({{ page.baseurl }}/docs/customising/).

<!--  (y en caso de hacerlo,
recuerde consultar la página sobre [cómo comentar los cambios realizados]({{ page.baseurl }}/feeding-back)).-->

Alaveteli utiliza Ruby on Rails, una infraestructura web de tipo «modelo-vista-controlador» común; 
si está familiarizado con Rails, ya conocerá estos detalles. Para obtener más información
sobre la estructura de Rails, consulte el [sitio web de Ruby on Rails](http://guides.rubyonrails.org/getting_started.html).

## Directorios principales y funciones de cada uno de ellos

<dl class="dir-structure">
  <dt>
      app
  </dt>
  <dd>
    <p><em>núcleo del código de aplicación de Alaveteli</em></p>
    <dl>
      <dt>
        assets
      </dt>
      <dd>
          <em>recursos estáticos que requieren una compilación previa para poder dar servicio</em>
          <dl>
              <dt>
                  fonts
              </dt>
              <dt>
                  images
              </dt>
              <dt>
                  javascripts
              </dt>
              <dt class="last">
                  stylesheets
              </dt>
              <dd class="last">
                  <p><em>hojas de estilo en formato CSS o <a href="http://sass-lang.com/">SCSS</a></em></p>
                  <p>Las hojas de estilo SCSS se compilan como CSS.</p>
              </dd>
          </dl>
      </dd>
      <dt>
        controllers
      </dt>
      <dt>
        helpers
      </dt>
      <dt>
        mailers
      </dt>
      <dt>
        models
      </dt>
      <dt class="last">
        views
      </dt>
    </dl>
  </dd>
  <dt>cache
  </dt>
  <dd><p><em>archivos temporales de descarga, datos adjuntos y plantillas</em></p>
  </dd>
  <dt>
    commonlib
  </dt>
  <dd>
    <p><em>librería de funciones comunes de mySociety</em></p>
    <p>
      Mantenemos una <a href="https://github.com/mysociety/commonlib">librería
      común</a>, que utilizamos en muchos de nuestros proyectos (no solo en
      Alaveteli). Está implementada como un <a
      href="http://git-scm.com/book/en/Git-Tools-Submodules">submódulo de git</a>
      para que Alaveteli la contenga aunque el código sea independiente. Normalmente no
      es necesario tener nada de esto en cuenta (ya que git lo gestiona automáticamente),
      pero si realmente <em>necesita</em> cambiar algo al respecto, tenga en cuenta que
      se trata de un repositorio independiente.
    </p>
  </dd>
  <dt>
    config
  </dt>
  <dd>
    <p><em>archivos de configuración</em></p>
    <p>
      El archivo primario de configuración es <code>general.yml</code>. Este archivo no se halla en el 
      repositorio de git (ya que contendrá información específica de su instalación, incluida la 
      contraseña de la base de datos), pero hay archivos de ejemplo.
    </p>
  </dd>
  <dt>
    db
  </dt>
  <dd>
    <p><em>archivos de base de datos</em></p>
    <dl>
        <dt class="last">
            migrate
        </dt>
        <dd class="last">
            Migración de Rails (actualización del esquema de la base de datos hacia arriba
            o abajo a medida que se desarrolla el código).
        </dd>
    </dl>
  </dd>
  <dt>
      doc
  </dt>
  <dd>
    <p><em>documentación</em></p>
    <p>
        Se trata de información técnica adicional añadida a la <a
        href="{{ page.baseurl }}/docs/">documentación principal</a> (la que
        está leyendo actualmente), que se almacena en el  repositorio de git,
        en la rama <code>gh-pages</code> y se publica como páginas de GitHub.
    </p>
  </dd>
  <dt>
    lib
  </dt>
  <dd>
    <p><em>librerías personalizadas</em></p>
    <dl>
        <dt>
            tasks
        </dt>
        <dd>Tareas de <a href="http://guides.rubyonrails.org/command_line.html#rake">Rake</a>.
        </dd>
        <dt class="last">
            themes
        </dt>
        <dd class="last">Aquí vive su tema de Alaveteli.
        </dd>
    </dl>
  </dd>
  <dt>
    locale
  </dt>
  <dd>
    <p><em>traducciones (internacionalización/i18n)</em></p>
    <p>
      Las cadenas de texto de traducción se almacenan en archivos <code>.po</code> dentro de directorios específicos para
      la localización y codificación. Por ejemplo, <code>es/</code> contiene las traducciones para el sitio en español.
    </p>
  </dd>
  <dt>
    log
  </dt>
  <dd>
    <p><em>archivos de registro de aplicación</em></p>
  </dd>
  <dt>
    public
  </dt>
  <dd> <p><em>archivos estáticos que pueden dar servicio directamente</em></p>
  </dd>
  <dt>
    script
  </dt>
  <dd>
    <p><em>shell scripts para el servidor</em></p>
    <p>
      Por ejemplo, <code>alert-overdue-requests</code> ejecuta el script
      que encuentra solicitudes que han superado el límite de tiempo y las envía por 
	  correo electrónico.
    </p>
  </dd>
  <dt>
    spec
  </dt>
  <dd>
    <p><em>pruebas</em></p>
    <p>
      El entorno de pruebas de Alaveteli funciona con <a href="http://rspec.info/">rspec</a>.
    </p>
  </dd>
  <dt>
    tmp
  </dt>
  <dd>
    <p>
      <em>archivos temporales</em>
    </p>
  </dd>
  <dt class="last">
      vendor
  </dt>
  <dd class="last">
    <p><em>software de terceros</em></p>
    <dl>
      <dt class="last">bundle</dt>
      <dd class="last">
          <p>
              <em>paquete de gems necesario para ejecutar Alaveteli</em>
          </p>
      </dd>
    </dl>
  </dd>
</dl>

Hemos omitido algunos subdirectorios menos importantes para mantener la claridad.
