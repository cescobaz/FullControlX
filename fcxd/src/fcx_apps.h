#include <json-c/json.h>

struct json_object *fcx_ui_apps();

struct json_object *fcx_apps_observe(void (*callback)(struct json_object *apps,
                                                      void *data),
                                     void *data);
