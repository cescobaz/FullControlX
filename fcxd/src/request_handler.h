#include <json-c/json.h>

typedef void (*fcx_handle_request_cb)(struct json_object *, void *);

typedef struct {
  struct json_object *request;
  fcx_handle_request_cb callback;
  void *context;
  int ref_count;
  struct json_object *subscription;
} fcx_request_handler_t;

fcx_request_handler_t *
fcx_request_handler_create(struct json_object *req,
                           fcx_handle_request_cb callback, void *ctx);
fcx_request_handler_t *
fcx_request_handler_retain(fcx_request_handler_t *handler);
int fcx_request_handler_release(fcx_request_handler_t *handler);

int fcx_handle_request(fcx_request_handler_t *handler);
