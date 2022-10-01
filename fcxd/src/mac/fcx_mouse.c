#include "../fcx_mouse.h"
#include "fcx_io_hid.h"
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <MacTypes.h>
#include <stdio.h>
#include <unistd.h>

void _fcx_mouse_location(CGPoint *cg_location) {
  CGEventRef event = CGEventCreate(nil);
  *cg_location = CGEventGetLocation(event);
  CFRelease(event);
}

struct json_object *fcx_mouse_location() {
  CGPoint cg_location;
  _fcx_mouse_location(&cg_location);

  struct json_object *location = json_object_new_array();
  json_object_array_add(location, json_object_new_int(cg_location.x));
  json_object_array_add(location, json_object_new_int(cg_location.y));
  return location;
}

int fcx_mouse_move(int x, int y) {
  IOGPoint location;
  location.x = (SInt16)x;
  location.y = (SInt16)y;

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouseMove.dx = location.x;
  event.mouseMove.dy = location.y;
  event.mouseMove.subType = NX_SUBTYPE_DEFAULT;

  location.x = 0;
  location.y = 0;
  return IOHIDPostEvent(fcx_io_hid_connect(), NX_MOUSEMOVED, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDSetRelativeCursorPosition);
}
