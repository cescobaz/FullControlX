#ifndef FCX_RUNNER_H
#define FCX_RUNNER_H

#include <stddef.h>
#include <stdint.h>

// Opaque handle to the Zig Runner (defined in RunnerC.zig).
typedef struct fcx_runner fcx_runner;

// Create / destroy a runner. fcx_runner_create returns NULL on allocation
// failure.
fcx_runner *fcx_runner_create(void);
void fcx_runner_destroy(fcx_runner *runner);

// Feed a chunk of input bytes. Each complete request is dispatched and its
// response bytes are delivered to write_cb(ctx, buf, len), possibly across
// several calls. Returns 0 on success, -1 on error.
int fcx_runner_handle(fcx_runner *runner, const uint8_t *data, size_t len,
                      void (*write_cb)(void *ctx, const uint8_t *buf,
                                       size_t len),
                      void *ctx);

#endif // FCX_RUNNER_H
