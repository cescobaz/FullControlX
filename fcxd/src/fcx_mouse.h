#include <json-c/json.h>

struct json_object *fcx_mouse_location();
int fcx_mouse_move(int x, int y);

int fcx_mouse_left_down();
int fcx_mouse_left_up();
int fcx_mouse_left_click();
