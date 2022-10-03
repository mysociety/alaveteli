Tips and tricks for using the Alaveteli Docker setup.

Run the development app server:

```
docker/server
```

Run the rails console:

```
dc run --rm app bin/rails c
```

Run other rails commands:

```
dc run --rm app bin/rails routes
dc run --rm app bin/rails runner "puts 1"
# etc…
```

Run a command with an environment variable set:

```
dc run -e RAILS_ENV=test --rm app bin/rails db:migrate
```

Use `-T` to pipe local files to scripts run in the app container.

```
cat spec/fixtures/files/incoming-request-plain.email | dc run --rm -T app script/mailin
```
