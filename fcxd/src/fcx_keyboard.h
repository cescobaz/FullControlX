
typedef void fcx_keyboard_t;

fcx_keyboard_t *fcx_keyboard_create();
void fcx_keyboard_destroy(fcx_keyboard_t *keyboard);

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text);
