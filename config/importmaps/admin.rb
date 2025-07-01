pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"

pin "admin", to: "admin/new.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/admin/controllers", under: "controllers", to: "admin/controllers"
