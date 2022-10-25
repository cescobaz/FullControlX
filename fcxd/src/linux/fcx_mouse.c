#include "../fcx_mouse.h"
#include <fcntl.h>
#include <linux/input-event-codes.h>
#include <linux/uinput.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct fcx_mouse {
  struct uinput_setup usetup;
  int fd;
};

struct fcx_mouse *_fcx_mouse_init() {
  struct fcx_mouse *mouse = malloc(sizeof(struct fcx_mouse));

  int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);

  /* enable mouse button left and relative events */
  ioctl(fd, UI_SET_EVBIT, EV_KEY);
  ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);

  ioctl(fd, UI_SET_EVBIT, EV_REL);
  ioctl(fd, UI_SET_RELBIT, REL_X);
  ioctl(fd, UI_SET_RELBIT, REL_Y);

  memset(&mouse->usetup, 0, sizeof(mouse->usetup));
  mouse->usetup.id.bustype = BUS_USB;
  mouse->usetup.id.vendor = 0x1234;  /* sample vendor */
  mouse->usetup.id.product = 0x5678; /* sample product */
  strcpy(mouse->usetup.name, "FullControlX Mouse");

  ioctl(fd, UI_DEV_SETUP, &mouse->usetup);
  ioctl(fd, UI_DEV_CREATE);

  mouse->fd = fd;
  return mouse;
}

void _fcx_mouse_release(struct fcx_mouse *mouse) {}

static struct fcx_mouse *_fcx_mouse = NULL;

struct fcx_mouse *_fcx_mouse_get() {
  if (_fcx_mouse == NULL) {
    _fcx_mouse = _fcx_mouse_init();
  }
  return _fcx_mouse;
}

int emit(int fd, int type, int code, int val) {
  struct input_event ie;
  ie.type = type;
  ie.code = code;
  ie.value = val;
  ie.time.tv_sec = 0;
  ie.time.tv_usec = 0;
  return write(fd, &ie, sizeof(ie));
}

struct json_object *fcx_mouse_location() {
  return NULL;
}

int fcx_mouse_move(int x, int y) {
  struct fcx_mouse *mouse = _fcx_mouse_get();
  emit(mouse->fd, EV_REL, REL_X, x);
  emit(mouse->fd, EV_REL, REL_Y, y);
  emit(mouse->fd, EV_SYN, SYN_REPORT, 0);
  return 0;
}

int fcx_mouse_left_down() { return 0; }
int fcx_mouse_left_up() { return 0; }
int fcx_mouse_left_click() { return 0; }

int fcx_mouse_right_down() { return 0; }
int fcx_mouse_right_up() { return 0; }
int fcx_mouse_right_click() { return 0; }

int fcx_mouse_double_click() { return 0; }

int fcx_mouse_scroll_wheel(int x, int y) { return 0; }

int fcx_mouse_drag(int x, int y) { return 0; }
