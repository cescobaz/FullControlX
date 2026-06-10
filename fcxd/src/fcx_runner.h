#ifndef FCX_RUNNER_H
#define FCX_RUNNER_H

#include "fcx_keyboard.h"
#include "fcx_mouse.h"
#include <stddef.h>
#include <stdint.h>

// Opaque handle to the Zig Runner (defined in RunnerC.zig).
typedef struct fcx_runner fcx_runner;

// Create / destroy a runner. The mouse and keyboard handles are caller-owned:
// the runner borrows them and does not free them. fcx_runner_create returns
// NULL on allocation failure.
fcx_runner *fcx_runner_create(fcx_mouse_t *mouse, fcx_keyboard_t *keyboard);
void fcx_runner_destroy(fcx_runner *runner);

// Feed a chunk of input bytes. Each complete request is dispatched and its
// response bytes are delivered to write_cb(ctx, buf, len), possibly across
// several calls. Returns 0 on success, -1 on error.
int fcx_runner_handle(fcx_runner *runner, const uint8_t *data, size_t len,
                      void (*write_cb)(void *ctx, const uint8_t *buf,
                                       size_t len),
                      void *ctx);

#endif // FCX_RUNNER_H
