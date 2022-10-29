#include <Carbon/Carbon.h>
#include <IOKit/hidsystem/ev_keymap.h>

#define SYMBOLS_COUNT (kVK_UpArrow + 1)

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

  _fcx_keyboard_map_symbols[kVK_Return] = "return";
  _fcx_keyboard_map_symbols[kVK_Tab] = "tab";
  _fcx_keyboard_map_symbols[kVK_Space] = "space";
  _fcx_keyboard_map_symbols[kVK_Delete] = "delete";
  _fcx_keyboard_map_symbols[kVK_Escape] = "escape";
  _fcx_keyboard_map_symbols[kVK_Command] = "command";
  _fcx_keyboard_map_symbols[kVK_Shift] = "shift";
  _fcx_keyboard_map_symbols[kVK_CapsLock] = "capslock";
  _fcx_keyboard_map_symbols[kVK_Option] = "option";
  _fcx_keyboard_map_symbols[kVK_Control] = "control";
  _fcx_keyboard_map_symbols[kVK_RightCommand] = "rightcommand";
  _fcx_keyboard_map_symbols[kVK_RightShift] = "rightshift";
  _fcx_keyboard_map_symbols[kVK_RightOption] = "rightoption";
  _fcx_keyboard_map_symbols[kVK_RightControl] = "rightcontrol";
  _fcx_keyboard_map_symbols[kVK_Function] = "function";
  _fcx_keyboard_map_symbols[kVK_F17] = "f17";
  //_fcx_keyboard_map_symbols[kVK_VolumeUp] = "volumeup";
  //_fcx_keyboard_map_symbols[kVK_VolumeDown] = "volumedown";
  //_fcx_keyboard_map_symbols[kVK_Mute] = "mute";
  _fcx_keyboard_map_symbols[kVK_F18] = "f18";
  _fcx_keyboard_map_symbols[kVK_F19] = "f19";
  _fcx_keyboard_map_symbols[kVK_F20] = "f20";
  _fcx_keyboard_map_symbols[kVK_F5] = "f5";
  _fcx_keyboard_map_symbols[kVK_F6] = "f6";
  _fcx_keyboard_map_symbols[kVK_F7] = "f7";
  _fcx_keyboard_map_symbols[kVK_F3] = "f3";
  _fcx_keyboard_map_symbols[kVK_F8] = "f8";
  _fcx_keyboard_map_symbols[kVK_F9] = "f9";
  _fcx_keyboard_map_symbols[kVK_F11] = "f11";
  _fcx_keyboard_map_symbols[kVK_F13] = "f13";
  _fcx_keyboard_map_symbols[kVK_F16] = "f16";
  _fcx_keyboard_map_symbols[kVK_F14] = "f14";
  _fcx_keyboard_map_symbols[kVK_F10] = "f10";
  _fcx_keyboard_map_symbols[kVK_F12] = "f12";
  _fcx_keyboard_map_symbols[kVK_F15] = "f15";
  _fcx_keyboard_map_symbols[kVK_Help] = "help";
  _fcx_keyboard_map_symbols[kVK_Home] = "home";
  _fcx_keyboard_map_symbols[kVK_PageUp] = "pageup";
  _fcx_keyboard_map_symbols[kVK_ForwardDelete] = "forwarddelete";
  _fcx_keyboard_map_symbols[kVK_F4] = "f4";
  _fcx_keyboard_map_symbols[kVK_End] = "end";
  _fcx_keyboard_map_symbols[kVK_F2] = "f2";
  _fcx_keyboard_map_symbols[kVK_PageDown] = "pagedown";
  _fcx_keyboard_map_symbols[kVK_F1] = "f1";
  _fcx_keyboard_map_symbols[kVK_LeftArrow] = "left";
  _fcx_keyboard_map_symbols[kVK_RightArrow] = "right";
  _fcx_keyboard_map_symbols[kVK_DownArrow] = "down";
  _fcx_keyboard_map_symbols[kVK_UpArrow] = "up";

  _fcx_keyboard_map_symbols_initialized = 1;
  return _fcx_keyboard_map_symbols;
}

#define SYSTEM_AUX_SYMBOLS_COUNT (NX_KEYTYPE_ILLUMINATION_TOGGLE + 1)

static char *_fcx_keyboard_map_system_aux_symbols[SYSTEM_AUX_SYMBOLS_COUNT];

int fcx_keyboard_map_system_aux_symbols_size() {
  return SYSTEM_AUX_SYMBOLS_COUNT;
}

static int _fcx_keyboard_map_system_aux_symbols_initialized = 0;

char **fcx_keyboard_map_system_aux_symbols() {
  if (_fcx_keyboard_map_system_aux_symbols_initialized) {
    return _fcx_keyboard_map_system_aux_symbols;
  }
  for (int i = 0; i < SYSTEM_AUX_SYMBOLS_COUNT; i++) {
    _fcx_keyboard_map_system_aux_symbols[i] = 0;
  }

  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_SOUND_UP] = "volumeup";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_SOUND_DOWN] = "volumedown";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_BRIGHTNESS_UP] =
      "brightnessup";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_BRIGHTNESS_DOWN] =
      "brightnessdown";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_CAPS_LOCK] = "caps_lock";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_HELP] = "help";
  _fcx_keyboard_map_system_aux_symbols[NX_POWER_KEY] = "power_key";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_MUTE] = "mute";
  _fcx_keyboard_map_system_aux_symbols[NX_UP_ARROW_KEY] = "up";
  _fcx_keyboard_map_system_aux_symbols[NX_DOWN_ARROW_KEY] = "down";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_NUM_LOCK] = "num_lock";

  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_CONTRAST_UP] = "contrast_up";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_CONTRAST_DOWN] =
      "contrast_down";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_LAUNCH_PANEL] =
      "launch_panel";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_EJECT] = "eject";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_VIDMIRROR] = "vidmirror";

  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_PLAY] = "playpause";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_NEXT] = "forward";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_PREVIOUS] = "back";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_FAST] = "fast";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_REWIND] = "rewind";

  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_ILLUMINATION_UP] =
      "illumination_up";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_ILLUMINATION_DOWN] =
      "illumination_down";
  _fcx_keyboard_map_system_aux_symbols[NX_KEYTYPE_ILLUMINATION_TOGGLE] =
      "illumination_toggle";

  _fcx_keyboard_map_system_aux_symbols_initialized = 1;
  return _fcx_keyboard_map_system_aux_symbols;
}
