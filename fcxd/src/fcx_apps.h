#include <json-c/json.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct {
  uint32_t pid;
  bool focus;
  char *localized_name;
} fcx_ui_app_t;

struct json_object *fcx_ui_apps();

struct json_object *fcx_apps_observe(void (*callback)(struct json_object *apps,
                                                      void *data),
                                     void *data);
