#!/bin/bash

ENGINE_NAME="alaveteli_core"
ENGINE_PATH="engines/$ENGINE_NAME"

# Clean up from any old runs
rm -r engines/
git reset --hard

# Create a new skeleton engine
bundle exec rails plugin new $ENGINE_NAME --mountable --database=postgresql --skip-javascript --skip-test-unit --skip-active-record --skip-sprockets --skip-git --skip-bundle
mkdir -p engines
mv $ENGINE_NAME engines
cd $ENGINE_PATH
bundle install

# Cleanup the things rails gives us that we don't want and we can't turn off
# via arguments to rails plugin new
rm README.rdoc
rm MIT-LICENSE
rm app/controllers/$ENGINE_NAME/application_controller.rb
rm app/helpers/$ENGINE_NAME/application_helper.rb
rm app/views/layouts/$ENGINE_NAME/application.html.erb
rm app/assets/stylesheets/$ENGINE_NAME/application.css
rm script/rails
rm config/routes.rb
rm -r lib/tasks
rm Gemfile
rm Rakefile

# Copy across alaveteli's code
cd ../..

# Fonts
mkdir -p $ENGINE_PATH/app/assets/fonts/$ENGINE_NAME
git mv app/assets/fonts/* $ENGINE_PATH/app/assets/fonts/$ENGINE_NAME

# Images
mkdir -p $ENGINE_PATH/app/assets/images/$ENGINE_NAME
git mv app/assets/images/* $ENGINE_PATH/app/assets/images/$ENGINE_NAME

# Javascripts
mkdir -p $ENGINE_PATH/app/assets/javascripts/$ENGINE_NAME
git mv app/assets/javascripts/* $ENGINE_PATH/app/assets/javascripts/$ENGINE_NAME

# Stylesheets
mkdir -p $ENGINE_PATH/app/assets/stylesheets/$ENGINE_NAME
git mv app/assets/stylesheets/* $ENGINE_PATH/app/assets/stylesheets/$ENGINE_NAME

# Controllers
mkdir -p $ENGINE_PATH/app/controllers/$ENGINE_NAME
git mv app/controllers/* $ENGINE_PATH/app/controllers/$ENGINE_NAME
# Concerns end up somewhere slightly different, so move them again
mkdir -p $ENGINE_PATH/app/controllers/concerns/$ENGINE_NAME
git mv $ENGINE_PATH/app/controllers/$ENGINE_NAME/concerns/* $ENGINE_PATH/app/controllers/concerns/$ENGINE_NAME
rmdir $ENGINE_PATH/app/controllers/$ENGINE_NAME/concerns

# Helpers
mkdir -p $ENGINE_PATH/app/helpers/$ENGINE_NAME
git mv app/helpers/* $ENGINE_PATH/app/helpers/$ENGINE_NAME

# Mailers
mkdir -p $ENGINE_PATH/app/mailers/$ENGINE_NAME
git mv app/mailers/* $ENGINE_PATH/app/mailers/$ENGINE_NAME

# Models
mkdir -p $ENGINE_PATH/app/models/$ENGINE_NAME
git mv app/models/* $ENGINE_PATH/app/models/$ENGINE_NAME
# Concerns end up somewhere slightly different, so move them again
mkdir -p $ENGINE_PATH/app/models/concerns/$ENGINE_NAME
git mv $ENGINE_PATH/app/models/$ENGINE_NAME/concerns/* $ENGINE_PATH/app/models/concerns/$ENGINE_NAME
rmdir $ENGINE_PATH/app/models/$ENGINE_NAME/concerns

# Views
mkdir -p $ENGINE_PATH/app/views/$ENGINE_NAME
git mv app/views/* $ENGINE_PATH/app/views/$ENGINE_NAME

# Config
# Not everything in config is version controlled, but we want to move
# everything. Note I'm copying not moving, otherwise there's no way to get
# it back when we rm the engines folder on a re-rerun
git ls-files --other config | xargs cp -t $ENGINE_PATH/config
# We want the gitignore too
cp config/.gitignore $ENGINE_PATH/config
git mv -k config/* $ENGINE_PATH/config

# Migrations
# db/structure.sql isn't version controlled, so we don't move that
mkdir -p $ENGINE_PATH/db
git mv db/migrate $ENGINE_PATH/db/migrate
git mv db/seeds.rb $ENGINE_PATH/db/seeds.rb

# Documentation
mkdir -p $ENGINE_PATH/doc
git mv doc/* $ENGINE_PATH/doc

# Lib
# lib/themes is probably empty, so git mv -k skips any errors
git mv -k lib/* $ENGINE_PATH/lib

# Locale
mkdir -p $ENGINE_PATH/locale
git mv locale/* $ENGINE_PATH/locale

# Script
git mv script/* $ENGINE_PATH/script

# Spec
git mv spec $ENGINE_PATH/spec


# Gemfile
# We should turn this into a gemspec at some point, but we have a lot of git
# based gems which won't work well with that.
cp Gemfile $ENGINE_PATH/Gemfile

# Rakefile
cp Rakefile $ENGINE_PATH/Rakefile

function insert_module_around_class() {
  # Open a module around the class
  sed -i \
      -r \
      -e "s/^(class (.*)$2)/module AlaveteliCore\n\\1/" \
      $1
}

function insert_module_around_module() {
  # Open a module around the module
  sed -i \
      -r \
      -e "s/^(module (.*))/module AlaveteliCore\n\\1/" \
      $1
}

function cleanup_module() {
  # Indent all of the lines of code
  sed -i \
      -r \
      -e "s/^/  /" \
      $1

  # Close the module
  sed -i \
      -r \
      -e "s/^  end/  end\nend/" \
      $1

  # Unindent the lines that shouldn't be indented
  sed -i \
      -r \
      -e "s/^  ((#|require|module AlaveteliCore).*)/\\1/" \
      $1

  # Cleanup blank lines
  sed -i \
      -r \
      -e "s/^  $//" \
      $1
}

function wrap_class_in_module() {
  insert_module_around_class $1 $2
  cleanup_module $1
}

function wrap_module_in_module() {
  insert_module_around_module $1
  cleanup_module $1
}
export -f wrap_class_in_module

# Namespace all the controllers
for file in $(find $ENGINE_PATH/app/controllers/$ENGINE_NAME -name "*_controller.rb"); do
  wrap_class_in_module $file Controller
done

# Namespace the controller concerns
for file in $(find $ENGINE_PATH/app/controllers/concerns/$ENGINE_NAME -name "*.rb"); do
  wrap_module_in_module $file
done

# Namespace all the helpers
for file in $(find $ENGINE_PATH/app/helpers/$ENGINE_NAME -name "*_helper.rb"); do
  wrap_module_in_module $file
done

# Namespace all the mailers
for file in $(find $ENGINE_PATH/app/mailers/$ENGINE_NAME -name "*_mailer.rb"); do
  wrap_class_in_module $file Mailer
done

# Namespace all the models
for file in $(find $ENGINE_PATH/app/models/$ENGINE_NAME -name "*_model.rb"); do
  wrap_class_in_module $file Model
done

# Namespace the model concerns
for file in $(find $ENGINE_PATH/app/models/concerns/$ENGINE_NAME -name "*.rb"); do
  wrap_module_in_module $file
done

# Now we can run bundle install for real
cd $ENGINE_PATH
bundle install
