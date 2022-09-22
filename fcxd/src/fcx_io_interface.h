#include <json-c/json.h>
#include <stdio.h>

int fcx_io_interface_run(FILE *input, FILE *output);

int fcx_io_interface_run_ex(FILE *input, FILE *output,
                            void (*handle_request)(struct json_object *, FILE *,
                                                   void *),
                            void *user_data);

void fcx_io_interface_handle_request(struct json_object *req_obj, FILE *output);
