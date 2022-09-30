#include "../fcx_mouse.h"
#include "fcx_io_hid.h"
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <MacTypes.h>
#include <math.h>
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
  CGPoint current_location;
  _fcx_mouse_location(&current_location);
  IOGPoint location;
  location.x = (SInt32)roundf(current_location.x + (CGFloat)x);
  location.y = (SInt32)roundf(current_location.y + (CGFloat)y);

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));

  kern_return_t res = IOHIDPostEvent(
      fcx_io_hid_connect(), NX_MOUSEMOVED, location, &event,
      kNXEventDataVersion, kIOHIDSetGlobalEventFlags, kIOHIDSetCursorPosition);

  return res;
}
