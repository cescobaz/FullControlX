#include <json-c/json.h>
#include <stdio.h>

struct json_object *parse(struct json_tokener *tokener,
                          enum json_tokener_error *err_out, FILE *input);
