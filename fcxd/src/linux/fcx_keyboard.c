#include "../fcx_keyboard.h"
#include <fcntl.h>
#include <linux/uinput.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct fcx_keyboard {
  struct uinput_setup usetup;
  int fd;
};

fcx_keyboard_t *fcx_keyboard_create() {
  struct fcx_keyboard *keyboard = malloc(sizeof(struct fcx_keyboard));
  keyboard->fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);

  ioctl(keyboard->fd, UI_SET_EVBIT, EV_KEY);
  for (int i = 1; i <= 68; i++) {
    ioctl(keyboard->fd, UI_SET_KEYBIT, i);
  }

  memset(&keyboard->usetup, 0, sizeof(keyboard->usetup));
  keyboard->usetup.id.bustype = BUS_USB;
  keyboard->usetup.id.vendor = 0x1234;  /* sample vendor */
  keyboard->usetup.id.product = 0x8765; /* sample product */
  strcpy(keyboard->usetup.name, "FullControlX Keyboard");

  ioctl(keyboard->fd, UI_DEV_SETUP, &keyboard->usetup);
  ioctl(keyboard->fd, UI_DEV_CREATE);

  return keyboard;
}

void fcx_keyboard_destroy(fcx_keyboard_t *keyboard) {
  struct fcx_keyboard *kb = keyboard;
  ioctl(kb->fd, UI_DEV_DESTROY);
  close(kb->fd);
  free(kb);
}

int fcx_keyboard_type(fcx_keyboard_t *keyboard, const char *text) { return 0; }
