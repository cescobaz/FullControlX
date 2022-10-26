
typedef void fcx_keyboard_t;

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name);
void fcx_keyboard_free(fcx_keyboard_t *keyboard);

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text);
