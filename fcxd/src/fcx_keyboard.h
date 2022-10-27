
typedef void fcx_keyboard_t;

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name);
void fcx_keyboard_free(fcx_keyboard_t *keyboard);

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text);

int fcx_keyboard_type_keycode(fcx_keyboard_t *keyboard, int keycode);

int fcx_keyboard_type_symbol(fcx_keyboard_t *keyboard, const char *symbol);
