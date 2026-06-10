#pragma once

typedef void fcx_mouse_t;

typedef struct {
  int x;
  int y;
} fcx_mouse_location_t;

fcx_mouse_t *fcx_mouse_create();
void fcx_mouse_free(fcx_mouse_t *mouse);

fcx_mouse_location_t fcx_mouse_location(fcx_mouse_t *mouse);
int fcx_mouse_move(fcx_mouse_t *mouse, int x, int y);

int fcx_mouse_left_down(fcx_mouse_t *mouse);
int fcx_mouse_left_up(fcx_mouse_t *mouse);
int fcx_mouse_left_click(fcx_mouse_t *mouse);

int fcx_mouse_right_down(fcx_mouse_t *mouse);
int fcx_mouse_right_up(fcx_mouse_t *mouse);
int fcx_mouse_right_click(fcx_mouse_t *mouse);

int fcx_mouse_double_click(fcx_mouse_t *mouse);

int fcx_mouse_scroll_wheel(fcx_mouse_t *mouse, int x, int y);

int fcx_mouse_drag(fcx_mouse_t *mouse, int x, int y);
