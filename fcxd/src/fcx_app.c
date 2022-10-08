#include "fcx_app.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_SIZE 2048

fcx_app_t *fcx_app_init(int input, int output) {
  fcx_app_t *app = calloc(1, sizeof(fcx_app_t));
  app->input = input;
  app->output = output;
  app->buffer = malloc(BUFFER_SIZE);
  app->buffer_size = BUFFER_SIZE;
  app->tokener = json_tokener_new();
  app->request_handler = fcx_request_handler_create();
  return app;
}

void __log_request_error(char *message, struct json_object *req_obj) {
  const char *req = json_object_to_json_string(req_obj);
  fprintf(stderr, "[error] %s. -> %s <-\n", message, req);
}

void __fcx_app_handle_request_cb(struct json_object *response, void *ctx) {
  fcx_app_t *app = (fcx_app_t *)ctx;

  if (response != NULL) {
    const char *response_str =
        json_object_to_json_string_ext(response, JSON_C_TO_STRING_PLAIN);
    write(app->output, response_str, strlen(response_str) + 1);
    fsync(app->output);
  }
}

int fcx_app_handle_data(fcx_app_t *app, void *buffer, size_t size) {
  struct json_object *req_obj =
      json_tokener_parse_ex(app->tokener, app->buffer, size);
  app->error = json_tokener_get_error(app->tokener);
  if (app->error == json_tokener_continue) {
    return 0;
  }
  if (app->error != json_tokener_success) {
    return 1;
  }
  __log_request_error("[DEBUG]", req_obj);
  fcx_request_ctx_t *req_ctx =
      fcx_request_ctx_create(req_obj, &__fcx_app_handle_request_cb, app);
  fcx_handle_request(app->request_handler, req_ctx);
  fcx_request_ctx_release(req_ctx);
  json_object_put(req_obj);
  return 0;
}
