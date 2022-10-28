#include "fcx_app.h"
#include "logger.h"
#include <json-c/json_tokener.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_SIZE 2048

fcx_app_t *fcx_app_init(int argc, char *argv[]) {
  char *locale_value = setlocale(LC_ALL, "en_US.UTF-8");
  FCX_LOG_INFO("Using locale %s", locale_value);

  fcx_app_t *app = calloc(1, sizeof(fcx_app_t));
  app->input = STDIN_FILENO;
  app->output = STDOUT_FILENO;
  app->buffer = malloc(BUFFER_SIZE);
  app->buffer_size = BUFFER_SIZE;
  app->tokener = json_tokener_new();
  app->keyboard = fcx_keyboard_create("us");
  app->request_handler = fcx_request_handler_create();
  app->request_handler->keyboard = app->keyboard;
  return app;
}

void fcx_app_free(fcx_app_t *app) {
  free(app->buffer);
  json_tokener_free(app->tokener);
  fcx_request_handler_free(app->request_handler);
  fcx_keyboard_free(app->keyboard);
  free(app);
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

int fcx_app_handle_data(fcx_app_t *app, size_t size) {
  size_t buffer_start = 0;
  while (buffer_start < size) {
    struct json_object *req_obj = json_tokener_parse_ex(
        app->tokener, &(app->buffer)[buffer_start], size - buffer_start);
    buffer_start += json_tokener_get_parse_end(app->tokener);
    app->error = json_tokener_get_error(app->tokener);
    if (app->error == json_tokener_continue) {
      return 0;
    }
    if (app->error != json_tokener_success) {
      return 1;
    }

    FCX_LOG_DEBUG("request: %s", json_object_to_json_string(req_obj));

    fcx_request_ctx_t *req_ctx =
        fcx_request_ctx_create(req_obj, &__fcx_app_handle_request_cb, app);
    fcx_handle_request(app->request_handler, req_ctx);
    fcx_request_ctx_release(req_ctx);
    json_object_put(req_obj);
  }
  return 0;
}
