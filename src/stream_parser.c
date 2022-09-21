#include "stream_parser.h"

inline struct json_object *parse(struct json_tokener *tokener,
                                 enum json_tokener_error *err_out,
                                 FILE *input) {
  struct json_object *jobj = NULL;
  do {
    int result = getc(input);
    if (result == EOF) {
      *err_out = json_tokener_error_parse_eof;
      break;
    }
    char c = (char)result;

    jobj = json_tokener_parse_ex(tokener, &c, sizeof(char));
    *err_out = json_tokener_get_error(tokener);
  } while (*err_out == json_tokener_continue);

  return jobj;
}
