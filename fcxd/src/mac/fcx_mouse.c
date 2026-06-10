#include "../fcx_mouse.h"
#include "fcx_io_hid.h"
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <MacTypes.h>
#include <mach/kern_return.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

struct fcx_mouse {
  io_connect_t hid_connect;
};

fcx_mouse_t *fcx_mouse_create() {
  struct fcx_mouse *mouse = malloc(sizeof(struct fcx_mouse));
  mouse->hid_connect = fcx_io_hid_connect();
  return mouse;
}

void fcx_mouse_free(fcx_mouse_t *mouse) { free(mouse); }

void _fcx_mouse_location(CGPoint *cg_location) {
  CGEventRef event = CGEventCreate(nil);
  *cg_location = CGEventGetLocation(event);
  CFRelease(event);
}

fcx_mouse_location_t fcx_mouse_location(fcx_mouse_t *mouse) {
  CGPoint cg_location;
  _fcx_mouse_location(&cg_location);

  fcx_mouse_location_t location = {(int)cg_location.x, (int)cg_location.y};
  return location;
}

int fcx_mouse_move(fcx_mouse_t *mouse, int x, int y) {
  if (x == 0 && y == 0) {
    return 0;
  }

  IOGPoint location = {0, 0};

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouseMove.dx = (SInt32)x;
  event.mouseMove.dy = (SInt32)y;
  event.mouseMove.subType = NX_SUBTYPE_DEFAULT;

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect, NX_MOUSEMOVED,
                        location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags,
                        kIOHIDSetRelativeCursorPosition);
}

int fcx_mouse_left_down(fcx_mouse_t *mouse) {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect, NX_LMOUSEDOWN,
                        location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags, kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_left_up(fcx_mouse_t *mouse) {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect, NX_LMOUSEUP,
                        location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags, kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_left_click(fcx_mouse_t *mouse) {
  fcx_mouse_left_down(mouse);
  return fcx_mouse_left_up(mouse);
}

int fcx_mouse_right_down(fcx_mouse_t *mouse) {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect, NX_RMOUSEDOWN,
                        location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags, kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_right_up(fcx_mouse_t *mouse) {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect, NX_RMOUSEUP,
                        location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags, kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_right_click(fcx_mouse_t *mouse) {
  fcx_mouse_right_down(mouse);
  return fcx_mouse_right_up(mouse);
}

int fcx_mouse_double_click(fcx_mouse_t *mouse) {
  fcx_mouse_left_click(mouse);
  return fcx_mouse_left_click(mouse);
}

int fcx_mouse_scroll_wheel(fcx_mouse_t *mouse, int x, int y) {
  if (x == 0 && y == 0) {
    return 0;
  }

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));

  if (abs(x) > abs(y)) {
    if (x > 0) {
      event.scrollWheel.deltaAxis2 = -1;
    } else {
      event.scrollWheel.deltaAxis2 = 1;
    }
  } else {
    if (y > 0) {
      event.scrollWheel.deltaAxis1 = -1;
    } else {
      event.scrollWheel.deltaAxis1 = 1;
    }
  }

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect,
                        NX_SCROLLWHEELMOVED, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_drag(fcx_mouse_t *mouse, int x, int y) {
  if (x == 0 && y == 0) {
    return 0;
  }

  IOGPoint location = {0, 0};

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouseMove.dx = (SInt32)x;
  event.mouseMove.dy = (SInt32)y;
  event.mouseMove.subType = NX_SUBTYPE_DEFAULT;

  return IOHIDPostEvent(((struct fcx_mouse *)mouse)->hid_connect,
                        NX_LMOUSEDRAGGED, location, &event, kNXEventDataVersion,
                        kIOHIDSetGlobalEventFlags,
                        kIOHIDSetRelativeCursorPosition);
}
