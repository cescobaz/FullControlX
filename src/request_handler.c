#include "request_handler.h"
#include "fcx_apps.h"
#include <string.h>

const char fcx_req_ui_apps[] = "ui_apps";

struct json_object *fcx_handle_request(struct json_object *req_obj) {

  if (!json_object_is_type(req_obj, json_type_array)) {
    return NULL;
  }

  size_t req_len = json_object_array_length(req_obj);
  struct json_object *function_obj = json_object_array_get_idx(req_obj, 0);
  if (req_len == 0 || function_obj == NULL ||
      !json_object_is_type(function_obj, json_type_string)) {
    return NULL;
  }
  const char *function = json_object_get_string(function_obj);

  struct json_object *response = json_object_new_object();
  if (strcmp(function, fcx_req_ui_apps) == 0) {
    struct json_object *ui_apps = fcx_ui_apps();
    json_object_object_add(response, "response", ui_apps);
  } else if (strcmp(function, fcx_req_ui_apps) == 0) {
    json_object_put(response);
    return NULL;
  } else {
    json_object_put(response);
    return NULL;
  }

  return response;
}
