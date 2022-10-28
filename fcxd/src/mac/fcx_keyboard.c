#include "../fcx_keyboard.h"
#include "../logger.h"
#include "fcx_io_hid.h"
#include <Carbon/Carbon.h>
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/ev_keymap.h>
#include <MacTypes.h>

struct fcx_keyboard {};

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name) {
  UInt32 keyboardType = LMGetKbdType();
  // UInt32 keyboardType = kKeyboardUnknown;
  FCX_LOG_DEBUG("keyboard type: %d %d", LMGetKbdType(), kKeyboardUnknown);

  // TODO: extern const CFStringRef
  // kTISNotifySelectedKeyboardInputSourceChanged
  // AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER;
  TISInputSourceRef keyboardLayoutRef =
      TISCopyCurrentKeyboardLayoutInputSource();
  if (keyboardLayoutRef == NULL) {
    FCX_LOG_ERR("keyboardLayoutRef == NULL");
    return NULL;
  }

  CFDataRef keyboardLayoutDataRef = (CFDataRef)TISGetInputSourceProperty(
      keyboardLayoutRef, kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout *keyboardLayout =
      (const UCKeyboardLayout *)CFDataGetBytePtr(keyboardLayoutDataRef);
  EventModifiers modifiers[] = {0, shiftKey, optionKey, shiftKey | optionKey};
  UniCharCount unicodeStringMaxLen = 4;
  UniChar unicodeString[5];
  UniCharCount unicodeStringLen;
  for (int i = 0; i < 4; i++) {
    EventModifiers modifier = modifiers[i];

    for (int keycode = 1; keycode < NX_NUMKEYCODES; keycode++) {
      UInt32 deadKeyState = 0;
      unicodeStringLen = 0;
      OSStatus rc = UCKeyTranslate(
          keyboardLayout, keycode, kUCKeyActionDown, ((modifier >> 8) & 0xFFFF),
          keyboardType, kUCKeyTranslateNoDeadKeysMask, &deadKeyState,
          unicodeStringMaxLen, &unicodeStringLen, unicodeString);
      unicodeString[unicodeStringLen] = 0;
      if (rc != 0 || unicodeStringLen != 0 || deadKeyState != 0) {
        UniChar c = unicodeString[0];
        if (c < 32 || c > 255) {
          c = 0;
        }
        FCX_LOG_DEBUG(
            "UCKeyTranslate %d: modifier %08X, keycode %d, deadKeyState %d, "
            "str len %d, -- %C -- %X",
            rc, (UInt32)modifier, keycode, deadKeyState, unicodeStringLen, c,
            unicodeString[0]);
      }
    }
  }

  return 0;
}
void fcx_keyboard_free(fcx_keyboard_t *keyboard) {}

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text) {
  return 1;
}

int fcx_keyboard_set_keycode_state(fcx_keyboard_t *keyboard, int keycode,
                                   int state) {
  IOGPoint loc = {0, 0};
  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.key.keyCode = keycode;
  return IOHIDPostEvent(fcx_io_hid_connect(), state, loc, &event,
                        kNXEventDataVersion, kIOHIDSetGlobalEventFlags,
                        kIOHIDPostHIDManagerEvent);
}

int fcx_keyboard_type_keycode(fcx_keyboard_t *keyboard, int keycode) {
  fcx_keyboard_set_keycode_state(keyboard, keycode, NX_KEYDOWN);
  fcx_keyboard_set_keycode_state(keyboard, keycode, NX_KEYUP);
  return 0;
}

int fcx_keyboard_type_symbol(fcx_keyboard_t *keyboard, const char *symbol) {
  return 1;
}
