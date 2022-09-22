#include "request_handler.h"
#include <json-c/json.h>
#include <stdio.h>

int fcx_io_interface_run(FILE *input, FILE *output);

int fcx_io_interface_run_ex(FILE *input, FILE *output,
                            void (*handle_request)(fcx_request_handler_t *,
                                                   struct json_object *, FILE *,
                                                   void *),
                            void *ctx);

void fcx_io_interface_handle_request(fcx_request_handler_t *req_handler,
                                     struct json_object *req_obj, FILE *output);
