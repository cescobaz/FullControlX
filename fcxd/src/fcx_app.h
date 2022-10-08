#include "fcx_request_handler.h"
#include <json-c/json.h>

typedef struct {
  int input;
  int output;
  void *buffer;
  size_t buffer_size;
  struct json_tokener *tokener;
  enum json_tokener_error error;
  fcx_request_handler_t *request_handler;
} fcx_app_t;

fcx_app_t *fcx_app_init(int input, int output);

int fcx_app_handle_data(fcx_app_t *app, void *buffer, size_t size);
