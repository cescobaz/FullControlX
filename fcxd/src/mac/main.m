#include "../fcx_app.h"
#include "../logger.h"
#include "src/fullcontrol_x_config.h"
#include <Foundation/Foundation.h>
#include <stdlib.h>
#include <unistd.h>

void handle_input_data(void *ctx) {}

int main(int argc, char *argv[]) {

  fcx_app_t *app = fcx_app_init(argc, argv);

  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ, app->input, 0, dispatch_get_main_queue());
  dispatch_set_context(source, &app);
  dispatch_source_set_event_handler(source, ^{
    uintptr_t data_to_read = dispatch_source_get_data(source);
    int r = read(app->input, app->buffer, MIN(app->buffer_size, data_to_read));
    if (r == 0) {
      exit(0);
      return;
    }
    if (fcx_app_handle_data(app, r) != 0) {
      FCX_LOG_ERR("json_tokener_parse_ex error %s",
                  json_tokener_error_desc(app->error));
      exit(1);
      return;
    }
  });

  dispatch_resume(source);

  [[NSRunLoop currentRunLoop] run];

  FCX_LOG_INFO("main NSRunLoop ends.");

  return 0;
}
