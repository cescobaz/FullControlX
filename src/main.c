#include "request_handler.h"
#include "src/fullcontrol_x_config.h"
#include "stream_parser.h"
#include <json-c/json.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void log_request_error(char *message, struct json_object *req_obj) {
  const char *req = json_object_to_json_string(req_obj);
  fprintf(stderr, "[error] %s. -> %s <-\n", message, req);
}

int main(int argc, char *argv[]) {

  FILE *input = stdin;
  FILE *output = stdout;

  struct json_tokener *tokener = json_tokener_new();

  while (1) {

    enum json_tokener_error jerr;
    struct json_object *req_obj = parse(tokener, &jerr, input);

    if (jerr != json_tokener_success) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(jerr));
      return 1;
    }

    struct json_object *response = fcx_handle_request(req_obj);

    if (response != NULL) {
      const char *response_str =
          json_object_to_json_string_ext(response, JSON_C_TO_STRING_PLAIN);
      fputs(response_str, output);
      json_object_put(response);
    }

    json_object_put(req_obj);
  };
  json_tokener_free(tokener);
  return 0;
}
