#include "fcx_io_interface.h"
#include "request_handler.h"
#include "stream_parser.h"
#include <stdio.h>

void log_request_error(char *message, struct json_object *req_obj) {
  const char *req = json_object_to_json_string(req_obj);
  fprintf(stderr, "[error] %s. -> %s <-\n", message, req);
}

int fcx_io_interface_run_ex(FILE *input, FILE *output,
                            void (*handle_request)(struct json_object *, FILE *,
                                                   void *),
                            void *user_data) {

  struct json_tokener *tokener = json_tokener_new();

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

    log_request_error("DEBUG", req_obj);

    handle_request(req_obj, output, user_data);
  };
  json_tokener_free(tokener);

  return 0;
}

void fcx_io_interface_handle_request(struct json_object *req_obj,
                                     FILE *output) {
  struct json_object *response = fcx_handle_request(req_obj);

  if (response != NULL) {
    const char *response_str =
        json_object_to_json_string_ext(response, JSON_C_TO_STRING_PLAIN);
    fputs(response_str, output);
    fflush(output);
    json_object_put(response);
  }
}

void fcx_io_interface_handle_request_wrapper(struct json_object *req_obj,
                                             FILE *output, void *data) {
  fcx_io_interface_handle_request(req_obj, output);
  json_object_put(req_obj);
}

int fcx_io_interface_run(FILE *input, FILE *output) {
  return fcx_io_interface_run_ex(
      input, output, &fcx_io_interface_handle_request_wrapper, NULL);
}
