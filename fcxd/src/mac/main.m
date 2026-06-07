#include "../fcx_app.h"
#include "../fcx_runner.h"
#include "../logger.h"
#include <Foundation/Foundation.h>
#include <stdlib.h>
#include <unistd.h>

// Write a slice of a response back to the client fd (ctx points at the fd).
static void write_response(void *ctx, const uint8_t *buf, size_t len) {
  int fd = *(int *)ctx;
  write(fd, buf, len);
  fsync(fd);
}

int main(int argc, char *argv[]) {

  fcx_app_t *app = fcx_app_init(argc, argv);

  fcx_runner *runner = fcx_runner_create();
  if (runner == NULL) {
    FCX_LOG_ERR("fcx_runner_create failed");
    return 1;
  }

  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ, app->input, 0, dispatch_get_main_queue());
  dispatch_set_context(source, &app);
  dispatch_source_set_event_handler(source, ^{
    uintptr_t data_to_read = dispatch_source_get_data(source);
    int r = read(app->input, app->buffer, MIN(app->buffer_size, data_to_read));
    if (r == 0) {
      fcx_runner_destroy(runner);
      exit(0);
      return;
    }
    if (fcx_runner_handle(runner, (const uint8_t *)app->buffer, (size_t)r,
                          &write_response, &app->output) != 0) {
      FCX_LOG_ERR("fcx_runner_handle error");
      fcx_runner_destroy(runner);
      exit(1);
      return;
    }
  });

  dispatch_resume(source);

  CFRunLoopRun();

  FCX_LOG_INFO("main CFRunLoop ends.");

  fcx_runner_destroy(runner);

  return 0;
}
