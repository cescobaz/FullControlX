
typedef void fcx_keyboard_t;

#define FCX_KEYBOARD_MODIFIER_SUPER "super"
#define FCX_KEYBOARD_MODIFIER_CMD "cmd"
#define FCX_KEYBOARD_MODIFIER_WINDOWS "windows"
#define FCX_KEYBOARD_MODIFIER_ALT "alt"
#define FCX_KEYBOARD_MODIFIER_SHIFT "shift"
#define FCX_KEYBOARD_MODIFIER_CTRL "ctrl"

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name);
void fcx_keyboard_free(fcx_keyboard_t *keyboard);

int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text);

int fcx_keyboard_type_symbol(fcx_keyboard_t *keyboard, const char *symbol);

int fcx_keyboard_type(fcx_keyboard_t *keyboard, const char **modifiers,
                      const char *symbol);
