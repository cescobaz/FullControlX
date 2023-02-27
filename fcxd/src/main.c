#include "fcx_app.h"
#include "logger.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <io.h>
#define STDIN_FILENO _fileno(stdin)
#else
#include <unistd.h>
#endif

int main(int argc, char *argv[]) {
  fcx_app_t *app = fcx_app_init(argc, argv);

  int rc = 0;
  while (1) {
#ifdef _WIN32
    int r = _read(STDIN_FILENO, app->buffer, app->buffer_size);
#else
    int r = read(STDIN_FILENO, app->buffer, app->buffer_size);
#endif
    if (r == 0) {
      FCX_LOG_INFO("input ends, terminating");
      break;
    }
    rc = fcx_app_handle_data(app, r);
    if (rc != 0) {
      FCX_LOG_ERR("json_tokener_parse_ex error %s",
                  json_tokener_error_desc(app->error));
      break;
    }
  }

  fcx_app_free(app);
  return rc;
}
