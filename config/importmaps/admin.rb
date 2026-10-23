pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "admin", to: "admin/new.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/admin/controllers", under: "controllers", to: "admin/controllers"
