#include "fcx_io_interface.h"
#include "src/fullcontrol_x_config.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <pthread.h>
#include <stdio.h>
#include <sys/_pthread/_pthread_attr_t.h>

void handle_request(struct json_object *req_obj, FILE *output, void *data) {
  NSRunLoop *runLoop = (NSRunLoop *)data;
  [runLoop
      performInModes:@[ NSDefaultRunLoopMode ]
               block:^{
                 NSLog(@"[debug] running in runLoop but triggered from thread");
                 fcx_io_interface_handle_request(req_obj, output);
                 json_object_put(req_obj);
               }];
}

void *run_thread(void *data) {
  FILE *input = stdin;
  FILE *output = stdout;
  int err = fcx_io_interface_run_ex(input, output, &handle_request, data);
  NSRunLoop *runLoop = (NSRunLoop *)data;

  return NULL;
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

  fprintf(stderr, "thread exits with status %d\n", *(int *)status);

  return 0;
}
