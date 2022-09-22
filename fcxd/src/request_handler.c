#include "request_handler.h"
#include "fcx_apps.h"
#include "fcx_system.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char fcx_req_ui_apps[] = "ui_apps";
const char fcx_req_apps_observe[] = "apps_observe";
const char fcx_req_system_info[] = "system_info";

fcx_request_handler_t *
fcx_request_handler_create(struct json_object *req,
                           fcx_handle_request_cb callback, void *ctx) {
  fcx_request_handler_t *handler = malloc(sizeof(fcx_request_handler_t));
  handler->request = json_object_get(req);
  handler->callback = callback;
  handler->context = ctx;
  handler->ref_count = 1;
  handler->subscription = NULL;
  return handler;
}

fcx_request_handler_t *
fcx_request_handler_retain(fcx_request_handler_t *handler) {
  handler->ref_count += 1;
  return handler;
}
int fcx_request_handler_release(fcx_request_handler_t *handler) {
  if (handler->ref_count == 1) {
    if (handler->request) {
      json_object_put(handler->request);
    }
    if (handler->subscription) {
      json_object_put(handler->subscription);
    }
    memset(handler, 0, sizeof(fcx_request_handler_t));
    free(handler);
    return 1;
  }
  handler->ref_count -= 1;
  return 0;
}

void fcx_handle_request_result(struct json_object *result, void *data) {
  fcx_request_handler_t *handler = data;
  struct json_object *response = json_object_new_object();
  json_object_object_add(response, "request",
                         json_object_get(handler->request));
  json_object_object_add(response, "response", result);
  handler->callback(response, handler->context);
  json_object_put(response);
}

int fcx_handle_request(fcx_request_handler_t *handler) {
  if (!json_object_is_type(handler->request, json_type_array)) {
    return 1;
  }

  size_t req_len = json_object_array_length(handler->request);
  struct json_object *function_obj =
      json_object_array_get_idx(handler->request, 1);
  if (req_len < 2 || function_obj == NULL ||
      !json_object_is_type(function_obj, json_type_string)) {
    return 2;
  }
  const char *function = json_object_get_string(function_obj);

  struct json_object *result = NULL;
  if (strcmp(function, fcx_req_ui_apps) == 0) {
    result = fcx_ui_apps();
  } else if (strcmp(function, fcx_req_apps_observe) == 0) {
    fcx_request_handler_retain(handler);
    handler->subscription =
        fcx_apps_observe(&fcx_handle_request_result, handler);
    result = json_object_new_string("subscription");
  } else if (strcmp(function, fcx_req_system_info) == 0) {
    result = fcx_system_info();
  } else {
    result = NULL;
  }

  fcx_handle_request_result(result, handler);

  return 0;
}
