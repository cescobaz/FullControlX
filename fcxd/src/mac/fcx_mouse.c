#include "../fcx_mouse.h"
#include "fcx_io_hid.h"
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <MacTypes.h>
#include <mach/kern_return.h>
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
  IOGPoint location = {0, 0};

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouseMove.dx = (SInt32)x;
  event.mouseMove.dy = (SInt32)y;
  event.mouseMove.subType = NX_SUBTYPE_DEFAULT;

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_MOUSEMOVED, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDSetRelativeCursorPosition);
}

int fcx_mouse_left_down() {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_LMOUSEDOWN, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_left_up() {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_LMOUSEUP, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_left_click() {
  fcx_mouse_left_down();
  return fcx_mouse_left_up();
}

int fcx_mouse_right_down() {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_RMOUSEDOWN, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_right_up() {

  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.mouse.subType = NX_SUBTYPE_DEFAULT;

  IOGPoint location = {0, 0};

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_RMOUSEUP, location, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_mouse_right_click() {
  fcx_mouse_right_down();
  return fcx_mouse_right_up();
}

int fcx_mouse_double_click() {
  fcx_mouse_left_click();
  return fcx_mouse_left_click();
}
