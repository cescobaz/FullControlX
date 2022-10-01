const handleTouchEvent = function (event) {
  event.preventDefault()
  event.stopPropagation()
  const el = event.target
  const eventName = el.getAttribute(`phx-${event.type}`)
  if (!eventName) {
    return
  }
  const bodyRect = document.body.getBoundingClientRect(),
        elemRect = el.getBoundingClientRect(),
        offsetY   = elemRect.top - bodyRect.top,
        offsetX   = elemRect.left - bodyRect.left;
  const touches = []
  for (const touch of event.changedTouches) {
    touches.push({
      id: touch.identifier,
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
