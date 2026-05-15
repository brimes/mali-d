# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Action Text + Trix editor
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"

# FullCalendar (agenda)
pin "@fullcalendar/core", to: "https://ga.jspm.io/npm:@fullcalendar/core@6.1.15/index.js"
pin "@fullcalendar/daygrid", to: "https://ga.jspm.io/npm:@fullcalendar/daygrid@6.1.15/index.js"
pin "@fullcalendar/timegrid", to: "https://ga.jspm.io/npm:@fullcalendar/timegrid@6.1.15/index.js"
pin "@fullcalendar/interaction", to: "https://ga.jspm.io/npm:@fullcalendar/interaction@6.1.15/index.js"
