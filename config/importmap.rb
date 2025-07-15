# Pin npm packages by running ./bin/importmap

pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "sortablejs" # @1.15.2

pin "public", to: "public/index.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/public/controllers", under: "controllers", to: "public/controllers"
pin_all_from "app/javascript/public/helpers", under: "helpers", to: "public/helpers"
