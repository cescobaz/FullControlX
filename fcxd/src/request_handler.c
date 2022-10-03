#include "request_handler.h"
#include "fcx_apps.h"
#include "fcx_mouse.h"
#include "fcx_system.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char fcx_req_system_info[] = "system_info";
const char fcx_req_mouse_move[] = "mouse_move";
const char fcx_req_mouse_left_click[] = "mouse_left_click";
const char fcx_req_mouse_right_click[] = "mouse_right_click";
const char fcx_req_mouse_double_click[] = "mouse_double_click";
const char fcx_req_mouse_scroll_wheel[] = "mouse_scroll_wheel";
const char fcx_req_ui_apps[] = "ui_apps";
const char fcx_req_apps_observe[] = "apps_observe";
const char fcx_req_ignore_all[] = "ignore_all";
const char fcx_req_ignore[] = "ignore";

fcx_request_handler_t *fcx_request_handler_create() {
  return json_object_new_array();
}

void fcx_request_handler_free(fcx_request_handler_t *handler) {
  json_object_put(handler);
}

fcx_request_ctx_t *fcx_request_ctx_create(struct json_object *req,
                                          fcx_handle_request_cb callback,
                                          void *ctx) {
  fcx_request_ctx_t *req_ctx = malloc(sizeof(fcx_request_ctx_t));
  req_ctx->request = json_object_get(req);
  req_ctx->callback = callback;
  req_ctx->context = ctx;
  req_ctx->ref_count = 1;
  req_ctx->subscription = NULL;
  return req_ctx;
}

fcx_request_ctx_t *fcx_request_ctx_retain(fcx_request_ctx_t *req_ctx) {
  req_ctx->ref_count += 1;
  return req_ctx;
}
int fcx_request_ctx_release(fcx_request_ctx_t *req_ctx) {
  if (req_ctx->ref_count == 1) {
    if (req_ctx->request) {
      json_object_put(req_ctx->request);
    }
    if (req_ctx->subscription) {
      json_object_put(req_ctx->subscription);
    }
    memset(req_ctx, 0, sizeof(fcx_request_ctx_t));
    free(req_ctx);
    return 1;
  }
  req_ctx->ref_count -= 1;
  return 0;
}

void fcx_handle_request_result(struct json_object *result, void *data) {
  fcx_request_ctx_t *req_ctx = data;
  struct json_object *response = json_object_new_object();
  json_object_object_add(response, "request",
                         json_object_get(req_ctx->request));
  json_object_object_add(response, "response", result);
  req_ctx->callback(response, req_ctx->context);
  json_object_put(response);
}

void __fcx_request_ctx_delete(struct json_object *obj, void *userdata) {
  int is_free = fcx_request_ctx_release(userdata);
  fprintf(stderr, "[debug] released req_ctx %d\n", is_free);
}

int fcx_handle_request(fcx_request_handler_t *handler,
                       fcx_request_ctx_t *req_ctx) {
  if (!json_object_is_type(req_ctx->request, json_type_array)) {
    return 1;
  }

  size_t req_len = json_object_array_length(req_ctx->request);
  struct json_object *function_obj =
      json_object_array_get_idx(req_ctx->request, 1);
  if (req_len < 2 || function_obj == NULL ||
      !json_object_is_type(function_obj, json_type_string)) {
    return 2;
  }
  const char *function = json_object_get_string(function_obj);

  struct json_object *result = NULL;
  if (strcmp(function, fcx_req_mouse_move) == 0) {
    int x = json_object_get_int(json_object_array_get_idx(req_ctx->request, 2));
    int y = json_object_get_int(json_object_array_get_idx(req_ctx->request, 3));
    int r = fcx_mouse_move(x, y);
    result = json_object_new_int(r);
  } else if (strcmp(function, fcx_req_mouse_left_click) == 0) {
    result = json_object_new_int(fcx_mouse_left_click());
  } else if (strcmp(function, fcx_req_mouse_right_click) == 0) {
    result = json_object_new_int(fcx_mouse_right_click());
  } else if (strcmp(function, fcx_req_mouse_double_click) == 0) {
    result = json_object_new_int(fcx_mouse_double_click());
  } else if (strcmp(function, fcx_req_mouse_scroll_wheel) == 0) {
    int x = json_object_get_int(json_object_array_get_idx(req_ctx->request, 2));
    int y = json_object_get_int(json_object_array_get_idx(req_ctx->request, 3));
    result = json_object_new_int(fcx_mouse_scroll_wheel(x, y));
  } else if (strcmp(function, fcx_req_system_info) == 0) {
    result = fcx_system_info();
  } else if (strcmp(function, fcx_req_ui_apps) == 0) {
    result = fcx_ui_apps();
  } else if (strcmp(function, fcx_req_apps_observe) == 0) {
    req_ctx->subscription =
        fcx_apps_observe(&fcx_handle_request_result, req_ctx);

    fcx_request_ctx_retain(req_ctx);
    struct json_object *j_req_ctx = json_object_new_object();
    json_object_set_userdata(j_req_ctx, req_ctx, &__fcx_request_ctx_delete);
    json_object_array_add(handler, j_req_ctx);

    result = json_object_new_string("subscription");
  } else if (strcmp(function, fcx_req_ignore_all) == 0) {
    int len = json_object_array_length(handler);
    json_object_array_del_idx(handler, 0, len);
    result = json_object_new_string("ok");
  } else {
    result = NULL;
  }

  fcx_handle_request_result(result, req_ctx);

  return 0;
}
