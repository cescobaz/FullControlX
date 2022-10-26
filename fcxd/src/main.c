#include "fcx_app.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  fcx_app_t *app = fcx_app_init(argc, argv);

  int rc = 0;
  while (1) {
    int r = read(STDIN_FILENO, app->buffer, app->buffer_size);
    if (r == 0) {
      break;
    }
    rc = fcx_app_handle_data(app, r);
    if (rc != 0) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(app->error));
      break;
    }
  }

  fcx_app_free(app);
  return rc;
}
