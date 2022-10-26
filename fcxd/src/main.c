#include "fcx_app.h"
#include "fcx_keyboard.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  fprintf(stderr, "Hello linux\n");

  fcx_app_t *app = fcx_app_init(STDIN_FILENO, STDOUT_FILENO);

  while (1) {
    int r = read(STDIN_FILENO, app->buffer, app->buffer_size);
    if (r == 0) {
      return 0;
    }
    int res = fcx_app_handle_data(app, app->buffer, r);
    if (res != 0) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(app->error));
      return res;
    }
  }

  return 0;
}
