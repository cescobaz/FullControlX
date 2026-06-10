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

  fcx_runner *runner = fcx_runner_create(app->mouse, app->keyboard);
  if (runner == NULL) {
    FCX_LOG_ERR("fcx_runner_create failed");
    return 1;
  }

  // Stop the run loop on EOF or error and let main() do the single cleanup
  // pass below. __block so the handler can write the exit status back.
  __block int exit_code = 0;
  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ, app->input, 0, dispatch_get_main_queue());
  dispatch_source_set_event_handler(source, ^{
    uintptr_t data_to_read = dispatch_source_get_data(source);
    int r = read(app->input, app->buffer, MIN(app->buffer_size, data_to_read));
    if (r == 0) {
      CFRunLoopStop(CFRunLoopGetMain());
      return;
    }
    if (fcx_runner_handle(runner, (const uint8_t *)app->buffer, (size_t)r,
                          &write_response, (void *)&app->output) != 0) {
      FCX_LOG_ERR("fcx_runner_handle error");
      exit_code = 1;
      CFRunLoopStop(CFRunLoopGetMain());
      return;
    }
  });

  dispatch_resume(source);

  CFRunLoopRun();

  FCX_LOG_INFO("main CFRunLoop ends.");

  dispatch_source_cancel(source);
  dispatch_release(source);
  fcx_runner_destroy(runner);
  fcx_app_free(app);

  return exit_code;
}
