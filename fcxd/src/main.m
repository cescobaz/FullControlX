#include "fcx_io_interface.h"
#include "src/fullcontrol_x_config.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <MacTypes.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

void handle_request(fcx_request_handler_t *req_handler,
                    struct json_object *req_obj, FILE *output, void *data) {

  json_object_get(req_obj);
  NSRunLoop *runLoop = (NSRunLoop *)data;
  [runLoop performBlock:^{
    fputs("[debug] handle_request in runLoop\n", stderr);
    fcx_io_interface_handle_request(req_handler, req_obj, output);
    json_object_put(req_obj);
  }];
}

void *run_thread(void *data) {
  FILE *input = stdin;
  FILE *output = stdout;

  int64_t err = fcx_io_interface_run_ex(input, output, &handle_request, data);
  fprintf(stderr,
          "[info] fcx_io_interface_run_ex ends (%llu), stopping runLoop.\n",
          err);

  NSRunLoop *runLoop = (NSRunLoop *)data;
  [runLoop performBlock:^{
    exit(err);
  }];

  fputs("[info] thread is ending.\n", stderr);

  return (void *)err;
}

int main(int argc, char *argv[]) {

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

  pthread_t thread;
  pthread_attr_t thread_attr;
  int err = pthread_attr_init(&thread_attr);
  if (err != 0) {
    return err;
  }
  err = pthread_create(&thread, &thread_attr, run_thread, runLoop);
  if (err != 0) {
    return err;
  }

  [runLoop run];
  [pool release];

  fprintf(stderr, "[info] main NSRunLoop ends, waiting for thread end.\n");

  void *status = NULL;
  err = pthread_join(thread, &status);
  if (err != 0) {
    fprintf(stderr, "fail to pthread_join %d\n", err);
  }

  fprintf(stderr, "thread exits with status %llu\n", (int64_t)status);

  return 0;
}
