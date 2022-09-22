#include "request_handler.h"
#include "fcx_apps.h"
#include "fcx_system.h"
#include <stdint.h>
#include <string.h>

const char fcx_req_ui_apps[] = "ui_apps";
const char fcx_req_system_info[] = "system_info";

struct json_object *_fcx_handle_request(struct json_object *req_obj,
                                        const char *function) {
  if (strcmp(function, fcx_req_ui_apps) == 0) {
    return fcx_ui_apps();
  } else if (strcmp(function, fcx_req_system_info) == 0) {
    return fcx_system_info();
  } else {
    return NULL;
  }
}

struct json_object *fcx_handle_request(struct json_object *req_obj) {
  if (!json_object_is_type(req_obj, json_type_array)) {
    return NULL;
  }

  size_t req_len = json_object_array_length(req_obj);
  struct json_object *function_obj = json_object_array_get_idx(req_obj, 1);
  if (req_len < 2 || function_obj == NULL ||
      !json_object_is_type(function_obj, json_type_string)) {
    return NULL;
  }
  const char *function = json_object_get_string(function_obj);

  struct json_object *result = _fcx_handle_request(req_obj, function);
  if (result == NULL) {
    return NULL;
  }

  struct json_object *response = json_object_new_object();
  json_object_get(req_obj);
  json_object_object_add(response, "request", req_obj);
  json_object_object_add(response, "response", result);
  return response;
}
