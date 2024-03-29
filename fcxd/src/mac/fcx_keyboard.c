#include "../fcx_keyboard.h"
#include "../logger.h"
#include "fcx_io_hid.h"
#include "fcx_keyboard_symbols_map.h"
#include <Carbon/Carbon.h>
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/ev_keymap.h>
#include <MacTypes.h>
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/_types/_mbstate_t.h>
#include <sys/fcntl.h>
#include <unistd.h>
#include <wchar.h>

#define UNICODE_STRING_MAX_LEN 3

// The Carbon key modifiers parameter is a UInt32, not a UInt16. But
// EventModifiers is UInt16. However activeFlag and btnState make no
// sense and they use the first 8 bits. So I shift of 8 bits.
static UInt32 shift = shiftKey >> 8;                             // 0x0002;
static UInt32 option = optionKey >> 8;                           // 0x0008;
static UInt32 option_shift = (shiftKey >> 8) | (optionKey >> 8); // 0x000A;

struct fcx_keyboard_keycode_mapping {
  // The encoding seems to be NSUTF16LittleEndianStringEncoding, indeed the
  // following works:
  /*
   * [[NSString alloc] initWithBytes:unicode_string
   *                   length:unicode_string_len * sizeof(UniChar)
   *                   encoding:NSUTF16LittleEndianStringEncoding];
   */
  UniChar unicode_string[UNICODE_STRING_MAX_LEN];

  UniCharCount unicode_string_len;
  UInt32 modifiers;
  UInt16 keycode;
};

struct fcx_keyboard {
  TISInputSourceRef keyboard_layout_ref;
  struct fcx_keyboard_keycode_mapping *keycode_mapping;
  UInt32 keycode_mapping_len;
};

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name) {
  UInt32 keyboardType = LMGetKbdType();
  // TODO: extern const CFStringRef
  // kTISNotifySelectedKeyboardInputSourceChanged
  // AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER;
  TISInputSourceRef keyboardLayoutRef =
      TISCopyCurrentKeyboardLayoutInputSource();
  if (keyboardLayoutRef == NULL) {
    FCX_LOG_ERR("keyboardLayoutRef == NULL");
    return NULL;
  }
  struct fcx_keyboard *keyboard = malloc(sizeof(struct fcx_keyboard));
  keyboard->keyboard_layout_ref = keyboardLayoutRef;

  CFDataRef keyboardLayoutDataRef = (CFDataRef)TISGetInputSourceProperty(
      keyboardLayoutRef, kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout *keyboardLayout =
      (const UCKeyboardLayout *)CFDataGetBytePtr(keyboardLayoutDataRef);
  UInt32 keycode_index = 0;
  UInt32 keycode_len = 0;
  UniCharCount unicodeStringMaxLen = UNICODE_STRING_MAX_LEN;
  UniChar unicodeString[UNICODE_STRING_MAX_LEN];
  UniCharCount unicodeStringLen;
  UInt32 modifiers[] = {0, shift, option, option_shift, alphaLock >> 8};
  UInt16 modifiers_len = 5;
  for (int op = 0; op < 2; op++) {
    if (op == 1) {
      keyboard->keycode_mapping =
          malloc(sizeof(struct fcx_keyboard_keycode_mapping) * keycode_len);
      assert(keyboard->keycode_mapping != NULL);
      keyboard->keycode_mapping_len = keycode_len;
    }
    for (UInt16 i = 0; i < modifiers_len; i++) {
      UInt32 modifier = modifiers[i];

      for (int keycode = 0; keycode < NX_NUMKEYCODES; keycode++) {
        UInt32 deadKeyState = 0;
        unicodeStringLen = 0;
        OSStatus rc = UCKeyTranslate(
            keyboardLayout, keycode, kUCKeyActionDown, modifier, keyboardType,
            kUCKeyTranslateNoDeadKeysMask, &deadKeyState, unicodeStringMaxLen,
            &unicodeStringLen, unicodeString);
        if (rc != 0) {
          FCX_LOG_DEBUG("UCKeyTranslate fails, rc: %d", rc);
          continue;
        }
        if (unicodeStringLen == 0) {
          continue;
        }
        if (deadKeyState != 0) {
          FCX_LOG_DEBUG("UCKeyTranslate deadKeyState: %d", deadKeyState);
          continue;
        }
        if (op == 0) {
          keycode_len += 1;
        } else {
          struct fcx_keyboard_keycode_mapping keycode_mapping;
          keycode_mapping.keycode = keycode;
          keycode_mapping.modifiers = modifier;
          keycode_mapping.unicode_string_len = unicodeStringLen;
          memset(keycode_mapping.unicode_string, 0, sizeof(UniChar));
          memcpy(keycode_mapping.unicode_string, unicodeString,
                 unicodeStringLen * sizeof(UniChar));
          keyboard->keycode_mapping[keycode_index] = keycode_mapping;
          keycode_index += 1;
        }
      }
    }
  }
  return keyboard;
}

void fcx_keyboard_free(fcx_keyboard_t *keyboard) {
  struct fcx_keyboard *kb = (struct fcx_keyboard *)keyboard;
  free(kb->keycode_mapping);
  free(kb);
}

struct fcx_keyboard_keycode_mapping *
_fcx_keyboard_keycode_mapping_from_unicode(fcx_keyboard_t *keyboard,
                                           UniChar c) {
  struct fcx_keyboard *kb = (struct fcx_keyboard *)keyboard;
  for (int mi = 0; mi < kb->keycode_mapping_len; mi++) {
    struct fcx_keyboard_keycode_mapping km = kb->keycode_mapping[mi];
    if (km.unicode_string[0] == c) {
      return &(kb->keycode_mapping[mi]);
    }
  }
  FCX_LOG_WARN(
      "_fcx_keyboard_keycode_mapping_from_unicode not found char 0x%04X", c);
  return NULL;
}

int fcx_keyboard_set_modifiers(fcx_keyboard_t *keyboard,
                               UInt32 modifiers_mask) {
  IOGPoint loc = {0, 0};
  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  return IOHIDPostEvent(fcx_io_hid_connect(), NX_FLAGSCHANGED, loc, &event,
                        kNXEventDataVersion, modifiers_mask,
                        kIOHIDSetGlobalEventFlags);
}

int fcx_keyboard_set_keycode_state(fcx_keyboard_t *keyboard, int keycode,
                                   int state) {
  IOGPoint loc = {0, 0};
  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.key.keyCode = keycode;
  return IOHIDPostEvent(fcx_io_hid_connect(), state, loc, &event,
                        kNXEventDataVersion, 0, kIOHIDPostHIDManagerEvent);
}

int fcx_keyboard_type_keycode(fcx_keyboard_t *keyboard, int keycode) {
  fcx_keyboard_set_keycode_state(keyboard, keycode, NX_KEYDOWN);
  fcx_keyboard_set_keycode_state(keyboard, keycode, NX_KEYUP);
  return 0;
}

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text) {
  struct fcx_keyboard *kb = (struct fcx_keyboard *)keyboard;
  mbstate_t utf_state;
  mbrtowc(NULL, NULL, 0, &utf_state);
  assert(mbsinit(&utf_state) != 0);
  wchar_t wchar;
  const char *end = text + strlen(text) + 1;
  while (text < end) {
    size_t parsed = mbrtowc(&wchar, text, end - text, &utf_state);
    if (parsed == -1) {
      FCX_LOG_ERR("Unable to parse multibyte text, errno %d", errno);
      return 2;
    }
    if (parsed == 0) {
      return 0;
    }
    text += parsed;
    struct fcx_keyboard_keycode_mapping *km =
        _fcx_keyboard_keycode_mapping_from_unicode(keyboard, wchar);
    if (km == NULL) {
      continue;
    }
    UInt32 modifiers_mask = 0;
    if ((km->modifiers & shift) != 0) {
      modifiers_mask |= NX_SHIFTMASK;
    }
    if ((km->modifiers & option) != 0) {
      modifiers_mask |= NX_ALTERNATEMASK;
    }
    FCX_LOG_DEBUG("fcx_keyboard_type_text modifiers_mask: %08X, keycode: %d",
                  modifiers_mask, km->keycode);
    fcx_keyboard_set_modifiers(keyboard, modifiers_mask);
    fcx_keyboard_type_keycode(keyboard, km->keycode);
    fcx_keyboard_set_modifiers(keyboard, 0);
  }
  return 0;
}

int fcx_keyboard_set_sys_aux_keytype_state(fcx_keyboard_t *keyboard,
                                           int special, int state) {
  IOGPoint loc = {0, 0};
  NXEventData event;
  memset(&event, 0, sizeof(NXEventData));
  event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
  event.compound.misc.C[1] = state;
  event.compound.misc.C[2] = special;
  memset(&event.compound.misc.C[4], 0xFF, 8); // maybe useless

  return IOHIDPostEvent(fcx_io_hid_connect(), NX_SYSDEFINED, loc, &event,
                        kNXEventDataVersion, 0, kIOHIDPostHIDManagerEvent);
}
int fcx_keyboard_type_symbol(fcx_keyboard_t *keyboard, const char *symbol) {

  int symbols_len = fcx_keyboard_map_symbols_size();
  char **symbols_map = fcx_keyboard_map_symbols();
  for (int i = 0; i < symbols_len; i++) {
    char *sm = symbols_map[i];
    if (sm != NULL && strcmp(symbol, sm) == 0) {
      return fcx_keyboard_type_keycode(keyboard, i);
    }
  }

  symbols_len = fcx_keyboard_map_system_aux_symbols_size();
  symbols_map = fcx_keyboard_map_system_aux_symbols();
  for (int i = 0; i < symbols_len; i++) {
    char *sm = symbols_map[i];
    if (sm != NULL && strcmp(symbol, sm) == 0) {
      fcx_keyboard_set_sys_aux_keytype_state(keyboard, i, NX_KEYDOWN);
      fcx_keyboard_set_sys_aux_keytype_state(keyboard, i, NX_KEYUP);
      return 0;
    }
  }

  FCX_LOG_WARN("symbol not found: %s", symbol);
  return 1;
}
