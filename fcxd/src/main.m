#include "fcx_app.h"
#include "src/fullcontrol_x_config.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <MacTypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void handle_input_data(void *ctx) {}

int main(int argc, char *argv[]) {

  fcx_app *app = fcx_app_init(STDIN_FILENO, STDOUT_FILENO);

  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ, app->input, 0, dispatch_get_main_queue());
  dispatch_set_context(source, &app);
  dispatch_source_set_event_handler(source, ^{
    uintptr_t data_to_read = dispatch_source_get_data(source);
    int r = read(app->input, app->buffer, MIN(BUFFER_SIZE, data_to_read));
    if (r == 0) {
      exit(0);
      return;
    }
    if (fcx_app_handle_data(app, app->buffer, r) != 0) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(app->error));
    }
  });

  dispatch_resume(source);

  [[NSRunLoop currentRunLoop] run];

  fprintf(stderr, "[info] main NSRunLoop ends.\n");

  return 0;
}
