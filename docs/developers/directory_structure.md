---
layout: page
title: Directory structure
---


# Alaveteli's directory structure

<p class="lead">This page gives you an overview of where to find things in Alaveteli's
directories.</p>

**You'll probably never need to worry about this** if you're just installing
Alaveteli -- this is really more useful if you're a developer planning on
making more substantive changes to the code. You don't need to be familiar with
Ruby to install or make basic [customisations to your
installation](/docs/customising/).

<!--  (and if you do,
remember to read the page about [feeding your changes back](/feeding-back)).-->

Alaveteli uses Ruby on Rails, which is a common "Model-View-Controller" web
framework &mdash; if you're familiar with Rails this will look very familiar. For
more information about the Rails structure see the [Ruby on Rails
website](http://guides.rubyonrails.org/getting_started.html).

## Key directories and what they're for

<dl class="dir-structure">
  <dt>
      app
  </dt>
  <dd>
    <p><em>the core Alaveteli application code</em></p>
    <dl>
      <dt>
        assets
      </dt>
      <dd>
          <em>static assets that require precompilation before being served</em>
          <dl>
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
                  <p><em>stylesheets in CSS or <a href="http://sass-lang.com/">SCSS</a> format.</em></p>
                  <p>SCSS stylesheets are compiled to CSS.</p>
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
        javascript
      </dt>
      <dt>
        jobs
      </dt>
      <dd>
          <em>background jobs run via Active Job.</em>
      </dd>
      <dt>
        mailers
      </dt>
      <dt>
        models
      </dt>
      <dt>
        services
      </dt>
      <dt>
        validators
      </dt>
      <dt class="last">
        views
      </dt>
    </dl>
  </dd>
  <dt>
    bin
  </dt>
  <dd>
    <p><em>executable wrapper scripts ("binstubs") for commands provided by the application and its gems, such as <code>rails</code> and <code>rake</code></em></p>
  </dd>
  <dt>cache
  </dt>
  <dd><p><em>cached files for downloads, attachments and templates.</em></p>
  </dd>
  <dt>
    commonlib
  </dt>
  <dd>
    <p><em>mySociety's library of common functions</em></p>
    <p>
      We maintain a <a href="https://github.com/mysociety/commonlib">common
      library</a> that we use across many of our projects (not just
      Alaveteli). This is implemented as a <a
      href="http://git-scm.com/book/en/Git-Tools-Submodules">git submodule</a>,
      so Alaveteli contains it even though the code is separate. Normally, you
      don't need to think about this (because git handles it automatically)...
      but if you really <em>do</em> need to change anything here, be aware that
      it is a separate git repository.
    </p>
  </dd>
  <dt>
    config
  </dt>
  <dd>
    <p><em>configuration files</em></p>
    <p>
      The primary configuration file is <code>general.yml</code>. This file isn't in the git
      repository (since it will contain information specific to your installation, including
      the database password), but example files are.
    </p>
  </dd>
  <dt>
    db
  </dt>
  <dd>
    <p><em>database files</em></p>
    <dl>
        <dt class="last">
            migrate
        </dt>
        <dd class="last">
            Rails' migration (updating the database scheme up or down
            as the code develops).
        </dd>
    </dl>
  </dd>
  <dt>
      doc
  </dt>
  <dd>
    <p><em>documentation</em></p>
    <p>
        These are technical notes. This is in addition to the <a
        href="http://code.alaveteli.org/docs/">core documentation</a> &mdash; which
        you are reading now &mdash; which is actually stored in the git
        repository in the <code>gh-pages</code> branch, and published as GitHub
        pages.
    </p>
  </dd>
  <dt>
    docker
  </dt>
  <dd>
    <p><em>files for running Alaveteli in Docker containers</em></p>
    <p>
      Includes the <code>Dockerfile</code>, entrypoint and bootstrap scripts,
      and environment defaults used by the
      <a href="{{ page.baseurl }}/docs/installing/docker/">Docker installation</a>.
    </p>
  </dd>
  <dt>
    gems
  </dt>
  <dd>
    <p><em>internal gems containing parts of Alaveteli's functionality</em></p>
  </dd>
  <dt>
    lib
  </dt>
  <dd>
    <p><em>custom libraries</em></p>
    <dl>
        <dt>
            tasks
        </dt>
        <dd><a href="http://guides.rubyonrails.org/command_line.html#rake">Rake</a> tasks.
        </dd>
        <dt class="last">
            themes
        </dt>
        <dd class="last">This is where your Alaveteli theme lives.
        </dd>
    </dl>
  </dd>
  <dt>
    locale
  </dt>
  <dd>
    <p><em>translations (internationalisation/i18n)</em></p>
    <p>
      The translation strings are stored in <code>.po</code> files in directories specific to
      the locale and encoding. For example, <code>es/</code> contains the translations for the Spanish site.
    </p>
  </dd>
  <dt>
    locale_alaveteli_pro
  </dt>
  <dd>
    <p><em>translations for Alaveteli Pro</em></p>
  </dd>
  <dt>
    log
  </dt>
  <dd>
    <p><em>application log files.</em></p>
  </dd>
  <dt>
    public
  </dt>
  <dd> <p><em>static files that can be served directly.</em></p>
  </dd>
  <dt>
    script
  </dt>
  <dd>
    <p><em>server-side shell scripts</em></p>
    <p>
      For example, <code>alert-overdue-requests</code> for running the script
      which finds overdue requests and mails them out.
    </p>
  </dd>
  <dt>
    spec
  </dt>
  <dd>
    <p><em>tests</em></p>
    <p>
      Alaveteli's test suite runs under <a href="http://rspec.info/">rspec</a>.
    </p>
  </dd>
  <dt>
    tmp
  </dt>
  <dd>
    <p>
      <em>temporary files</em>
    </p>
  </dd>
  <dt class="last">
      vendor
  </dt>
  <dd class="last">
    <p><em>third-party software</em></p>
    <dl>
      <dt>assets</dt>
      <dt class="last">javascript</dt>
      <dd class="last">
          <p>
              <em>vendored third-party front-end assets and JavaScript.</em>
          </p>
          <p>
              The gems needed to run Alaveteli are installed by
              <a href="https://bundler.io/">Bundler</a> (into
              <code>vendor/bundle</code> unless you configure a different path);
              that directory is created at install time and is not part of the
              git repository.
          </p>
      </dd>
    </dl>
  </dd>
</dl>

We've missed out some of the less important subdirectories here just to keep
things clear.
