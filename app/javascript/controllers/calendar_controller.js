import { Controller } from "@hotwired/stimulus"

const FULLCALENDAR_URL = "https://cdn.jsdelivr.net/npm/fullcalendar@6.1.15/index.global.min.js"

let fullCalendarLoader = null
function loadFullCalendar() {
  if (window.FullCalendar) return Promise.resolve(window.FullCalendar)
  if (fullCalendarLoader) return fullCalendarLoader
  fullCalendarLoader = new Promise((resolve, reject) => {
    const s = document.createElement("script")
    s.src = FULLCALENDAR_URL
    s.async = true
    s.onload = () => resolve(window.FullCalendar)
    s.onerror = () => reject(new Error("Falha ao baixar FullCalendar de " + FULLCALENDAR_URL))
    document.head.appendChild(s)
  })
  return fullCalendarLoader
}

export default class extends Controller {
  static values = { eventsUrl: String, newUrl: String }

  async connect() {
    this.element.innerHTML = '<div class="text-gray-400 text-sm p-4">Carregando agenda…</div>'
    try {
      const FC = await loadFullCalendar()
      this.element.innerHTML = ""
      this.calendar = new FC.Calendar(this.element, {
        initialView: "timeGridWeek",
        locale: "pt-br",
        firstDay: 0,
        height: 720,
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
    } catch (err) {
      console.error("FullCalendar error:", err)
      this.element.innerHTML = `<div class="text-red-600 text-sm p-4">Erro ao carregar agenda: ${err.message}</div>`
    }
  }

  disconnect() {
    if (this.calendar) this.calendar.destroy()
  }
}
