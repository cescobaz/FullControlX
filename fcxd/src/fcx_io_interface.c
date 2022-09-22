#include "fcx_io_interface.h"
#include "stream_parser.h"

void __log_request_error(char *message, struct json_object *req_obj) {
  const char *req = json_object_to_json_string(req_obj);
  fprintf(stderr, "[error] %s. -> %s <-\n", message, req);
}

void __fcx_io_interface_handle_request_cb(struct json_object *response,
                                          void *ctx) {
  FILE *output = ctx;

  if (response != NULL) {
    const char *response_str =
        json_object_to_json_string_ext(response, JSON_C_TO_STRING_PLAIN);
    fputs(response_str, output);
    fflush(output);
  }
}

void __fcx_io_interface_handle_request_wrapper(
    fcx_request_handler_t *req_handler, struct json_object *req_obj,
    FILE *output, void *data) {
  fcx_io_interface_handle_request(req_handler, req_obj, output);
}

int fcx_io_interface_run(FILE *input, FILE *output) {
  return fcx_io_interface_run_ex(
      input, output, &__fcx_io_interface_handle_request_wrapper, NULL);
}

int fcx_io_interface_run_ex(FILE *input, FILE *output,
                            void (*handle_request)(fcx_request_handler_t *,
                                                   struct json_object *, FILE *,
                                                   void *),
                            void *user_data) {

  struct json_tokener *tokener = json_tokener_new();
  fcx_request_handler_t *req_handler = fcx_request_handler_create();

  while (1) {
    enum json_tokener_error jerr;
    struct json_object *req_obj = parse(tokener, &jerr, input);

    if (jerr == json_tokener_error_parse_eof) {
      fputs("[info] parse EOF\n", stderr);
      return 0;
    }

    if (jerr != json_tokener_success) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(jerr));
      return 1;
    }

    __log_request_error("DEBUG", req_obj);

    handle_request(req_handler, req_obj, output, user_data);
    json_object_put(req_obj);
  };
  json_tokener_free(tokener);
  fcx_request_handler_free(req_handler);

  return 0;
}

void fcx_io_interface_handle_request(fcx_request_handler_t *handler,
                                     struct json_object *req_obj,
                                     FILE *output) {
  fcx_request_ctx_t *req_ctx = fcx_request_ctx_create(
      req_obj, &__fcx_io_interface_handle_request_cb, output);
  fcx_handle_request(handler, req_ctx);
  fcx_request_ctx_release(req_ctx);
}
