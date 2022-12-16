---
layout: page
title: Docker
---
# Installing Alaveteli using Docker

<p class="lead">
  <a href="https://www.docker.com">Docker</a> provides an easy method to set
  up virtual development environments. We bundle an example <code>docker-compose.yml</code>
  in the repository, which builds and runs a Docker container for you.
</p>

Although this is just one of
[several ways to install Alaveteli]({{ page.baseurl }}/docs/installing/),
it's the best and easiest way to install it for
<a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development</a>.

<div class="attention-box helpful-hint">
  Remember that you <em>must</em> customise Alaveteli before it’s ready for the
  public to use, so installing a development site is a necessary part of
  <a href="{{ page.baseurl }}/docs/installing/">installing Alaveteli</a>.
</div>

The included steps will use Docker to create a development environment where
you can run the test suite and the development server, make changes to the
codebase and — significantly for [customising Alaveteli]({{ page.baseurl }}/docs/customising/) —
create your own <a href="{{ page.baseurl }}/docs/glossary/#theme" class="glossary__link">theme</a>.

<div class="attention-box info">
  <p>
    <strong>What’s Docker?</strong>
    Docker is a tool that lets you run applications in self-contained isolated
    envrionments called a container. When you use Docker to install Alaveteli,
    it creates a container that has all the dependencies Alaveteli needs.
  </p>
  <p>
    Because everything is in the container, it doesn’t need to find or change
    anything on your own machine. This means you can work on any operating
    system that runs Docker, instead of needing to match what Alaveteli
    expects.
  </p>
  <p>
    You can edit the files just like any other files on your machine (because
    the folder is "shared" between your machine and the container), and the
    container uses port-forwarding so you can access its Alaveteli server
    through your browser.
  </p>
  <p>
    See
    <a href="https://docs.docker.com/get-started/">the Docker documentation</a>
    for more information.
  </p>
</div>

### How to setup the Docker container

The supplied scripts in the `./docker` directory will create you a Docker
container which has everything you need to work on Alaveteli.

To create a Docker container with Alaveteli installed, run the setup script:

        ./docker/setup

This will build the required Docker images, download the default Alaveteli
theme, install all dependencies, create and populate the database with sample
data and create an initial search index

### How to start Alaveteli server

To start Alaveteli, run the rails server:

        ./docker/server

You can now visit the application in your browser (on the same machine that is
running Docker) at `http://0.0.0.0:3000`.

### How to run commands

While working with Alaveteli you might need to run commands within the Docker
container.

<div class="attention-box helpful-hint">
  Depending on the version of Docker installed you might need to substitute
  <code>docker&nbsp;compose</code> for <code>docker-compose</code> in the
  commands below.
</div>

The Rails console can be launch by running:

        docker compose run --rm app bin/rails console

Run other Rails commands:

        docker compose run --rm app bin/rails routes
        docker compose run --rm app bin/rails runner "puts 1"
        # etc…

Run a command with an environment variable set:

        docker compose run -e RAILS_ENV=test --rm app bin/rails db:migrate

Use <code>-T</code> to pipe local files to scripts run in the app container.

        cat spec/fixtures/files/incoming-request-plain.email |
          docker compose run --rm -T app script/mailin

### How to stop the server

You don't need to stop Alaveteli right away, but when you do this can be done
by pressing **Ctrl-C** to interrupt the `./docker/server` script.

### How reset the container

While working on Alaveteli you may find you might need to reset the container
back to its initial state. This can be done by running:

        ./docker/reset

## What next?

The Docker installation you've just done has loaded test data, which includes
an administrator account (`Joe Admin`). If you just want to dive straight into
customisation, every new Alaveteli site needs its own theme.

* follow the instruction to [create your own theme]({{ page.baseurl }}/docs/customising/make_a_new_theme/)

* if you've already done that, or want to stick with the default theme for now,
  see [other things you can do with a new installation]({{ page.baseurl }}/docs/installing/next_steps/).
