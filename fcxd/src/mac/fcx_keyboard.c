#include "../fcx_keyboard.h"

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name) { return 0; }
void fcx_keyboard_free(fcx_keyboard_t *keyboard) {}

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text) {
  return 1;
}

int fcx_keyboard_type_keycode(fcx_keyboard_t *keyboard, int keycode) {
  return 1;
}