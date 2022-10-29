#include <IOKit/hidsystem/ev_keymap.h>

#define SYMBOLS_COUNT (NX_KEYTYPE_ILLUMINATION_TOGGLE + 1)

static char *_fcx_keyboard_map_symbols[SYMBOLS_COUNT];

int fcx_keyboard_map_symbols_size() { return SYMBOLS_COUNT; }

static int _fcx_keyboard_map_symbols_initialized = 0;

char **fcx_keyboard_map_symbols() {
  if (_fcx_keyboard_map_symbols_initialized) {
    return _fcx_keyboard_map_symbols;
  }
  for (int i = 0; i < SYMBOLS_COUNT; i++) {
    _fcx_keyboard_map_symbols[i] = 0;
  }

  _fcx_keyboard_map_symbols[NX_KEYTYPE_SOUND_UP] = "volumeup";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_SOUND_DOWN] = "volumedown";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_BRIGHTNESS_UP] = "brightnessup";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_BRIGHTNESS_DOWN] = "brightnessdown";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_CAPS_LOCK] = "caps_lock";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_HELP] = "help";
  _fcx_keyboard_map_symbols[NX_POWER_KEY] = "power_key";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_MUTE] = "mute";
  _fcx_keyboard_map_symbols[NX_UP_ARROW_KEY] = "up";
  _fcx_keyboard_map_symbols[NX_DOWN_ARROW_KEY] = "down";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_NUM_LOCK] = "num_lock";

  _fcx_keyboard_map_symbols[NX_KEYTYPE_CONTRAST_UP] = "contrast_up";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_CONTRAST_DOWN] = "contrast_down";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_LAUNCH_PANEL] = "launch_panel";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_EJECT] = "eject";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_VIDMIRROR] = "vidmirror";

  _fcx_keyboard_map_symbols[NX_KEYTYPE_PLAY] = "play";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_NEXT] = "next";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_PREVIOUS] = "previous";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_FAST] = "fast";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_REWIND] = "rewind";

  _fcx_keyboard_map_symbols[NX_KEYTYPE_ILLUMINATION_UP] = "illumination_up";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_ILLUMINATION_DOWN] = "illumination_down";
  _fcx_keyboard_map_symbols[NX_KEYTYPE_ILLUMINATION_TOGGLE] =
      "illumination_toggle";

  return _fcx_keyboard_map_symbols;
}
