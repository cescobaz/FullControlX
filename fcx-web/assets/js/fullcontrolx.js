const touch_el_width = 128
const touch_el_height = 128

function getTouchElId(touch) {
  return `touch_${touch.identifier}`
}

function drawTouches(touches) {
  const parent = document.getElementById('placeholder')
  for (const touch of touches) {
    const touch_el_id = getTouchElId(touch)
    let touch_el = document.getElementById(touch_el_id)
    if (!touch_el) {
      touch_el = document.createElement("div")
      touch_el.id = touch_el_id
      touch_el.className = 'absolute rounded-full bg-blue-900'
      touch_el.style.width = `${touch_el_width}px`
      touch_el.style.height = `${touch_el_height}px`
      parent.appendChild(touch_el)
    }

    const bodyRect = document.body.getBoundingClientRect(),
          elemRect = parent.getBoundingClientRect(),
          offsetY   = elemRect.top - bodyRect.top,
          offsetX   = elemRect.left - bodyRect.left;

    const left = touch.clientX - offsetX - Math.round(touch_el_width / 2)
    const top = touch.clientY - offsetY - Math.round(touch_el_height / 2)

    touch_el.style.left = `${left}px`
    touch_el.style.top = `${top}px`
  }
}

function removeTouches(touches) {
  for (const touch of touches) {
    document.getElementById(getTouchElId(touch)).remove()
  }
}
function handleTouchEvent(event) {
  event.preventDefault()
  event.stopPropagation()
  drawTouches(event.targetTouches)
  if (event.type === 'touchend' || event.type === 'touchcancel') {
    removeTouches(event.changedTouches)
  }
  const el = event.target
  const eventName = el.getAttribute(`phx-${event.type}`)
  if (!eventName) {
    return
  }
  const bodyRect = document.body.getBoundingClientRect(),
        elemRect = el.getBoundingClientRect(),
        offsetY   = elemRect.top - bodyRect.top,
        offsetX   = elemRect.left - bodyRect.left;
  const ts = Date.now()
  const touches = []
  for (const touch of event.changedTouches) {
    touches.push({
      id: touch.identifier,
      ts,
      x: touch.clientX - offsetX, y: touch.clientY - offsetY
    })
  }
  const args = {...el.dataset, touches}
  const target = el.getAttribute("phx-target")
  if (target) {
    const querySelector = `[data-phx-component="${target}"]`
    this.pushEventTo(querySelector, eventName, args)
  } else {
    this.pushEvent(eventName, args)
  }
}

const hooks = {}

hooks.Trackpad = {
  mounted() {
    this.el.ontouchstart = handleTouchEvent.bind(this)
    this.el.ontouchmove = handleTouchEvent.bind(this)
    this.el.ontouchend = handleTouchEvent.bind(this)
    this.el.ontouchcancel = handleTouchEvent.bind(this)
  }
}

module.exports = { hooks }
