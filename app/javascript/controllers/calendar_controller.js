import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static values = { eventsUrl: String, newUrl: String }

  connect() {
    this.calendar = new Calendar(this.element, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      initialView: "timeGridWeek",
      locale: "pt-br",
      firstDay: 0,
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay"
      },
      buttonText: { today: "Hoje", month: "Mês", week: "Semana", day: "Dia" },
      slotMinTime: "07:00:00",
      slotMaxTime: "21:00:00",
      allDaySlot: false,
      nowIndicator: true,
      selectable: true,
      events: this.eventsUrlValue,
      select: (info) => {
        const params = new URLSearchParams({ start: info.startStr, end: info.endStr })
        window.location.href = `${this.newUrlValue}?${params}`
      }
    })
    this.calendar.render()
  }

  disconnect() {
    if (this.calendar) this.calendar.destroy()
  }
}
