#include "../fcx_keyboard.h"
#include <fcntl.h>
#include <kbdfile.h>
#include <keymap/common.h>
#include <keymap/context.h>
#include <keymap/dump.h>
#include <keymap/kmap.h>
#include <linux/input-event-codes.h>
#include <linux/kd.h>
#include <linux/uinput.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct fcx_keyboard {
  struct kbdfile_ctx *kfctx;
  struct lk_ctx *lkctx;
  struct uinput_setup usetup;
  int fd;
};

// copied from https://github.com/legionus/kbd/blob/master/src/loadkeys.c
// #define DATADIR "/usr/lib/kbd"
// example /usr/share/kbd/keymaps/i386/qwerty/us.map.gz
#define DATADIR "/usr/share/kbd"
#define KEYMAPDIR "keymaps"
/*
 * Default keymap, and where the kernel copy of it lives.
 */
#ifdef __sparc__
#define DEFMAP "sunkeymap.map"
#define KERNDIR "/usr/src/linux/drivers/sbus/char"
#else
#define DEFMAP "defkeymap.map"
#define KERNDIR "/usr/src/linux/drivers/tty/vt"
#endif
static const char *const dirpath1[] = {"", DATADIR "/" KEYMAPDIR "/**",
                                       KERNDIR "/", NULL};
static const char *const suffixes[] = {"", ".kmap", ".map", NULL};

int fcx_load_keymap(struct fcx_keyboard *keyboard, const char *keymap_name) {
  struct kbdfile_ctx *file_ctx = kbdfile_context_new();
  struct kbdfile *fp = kbdfile_new(file_ctx);
  int rc;
  if (keymap_name == NULL) {
    rc = kbdfile_find(DEFMAP, dirpath1, suffixes, fp);
  } else {
    rc = kbdfile_find(keymap_name, dirpath1, suffixes, fp);
  }
  if (rc != 0) {
    kbdfile_free(fp);
    kbdfile_context_free(file_ctx);
    return rc;
  }
  struct lk_ctx *ctx = lk_init();
  rc = lk_parse_keymap(ctx, fp);
  kbdfile_free(fp);

  keyboard->kfctx = file_ctx;
  keyboard->lkctx = ctx;
  return rc;
}

struct kbentry _fcx_keyboard_kbentry_from_unicode(fcx_keyboard_t *kb,
                                                  int unicode) {
  struct kbentry kbe = {0, 0, -1};
  struct lk_ctx *ctx = ((struct fcx_keyboard *)kb)->lkctx;
  for (int table = K_NORMTAB; table <= K_ALTSHIFTTAB; table++) {
    int totalKeys = lk_get_keys_total(ctx, table);
    for (int keycode = 0; keycode < totalKeys; keycode++) {
      if (!lk_key_exists(ctx, table, keycode)) {
        continue;
      }
      int ucode = lk_get_key(ctx, table, keycode);
      if (ucode == unicode) {
        kbe.kb_table = table;
        kbe.kb_index = keycode;
        kbe.kb_value = unicode;
        return kbe;
      }
    }
  }
  return kbe;
}

void fcx_free_keymap(fcx_keyboard_t *keyboard) {
  struct fcx_keyboard *kb = keyboard;
  lk_free(kb->lkctx);
  kbdfile_context_free(kb->kfctx);
}

fcx_keyboard_t *fcx_keyboard_create(const char *keymap_name) {
  struct fcx_keyboard *keyboard = malloc(sizeof(struct fcx_keyboard));
  fcx_load_keymap(keyboard, keymap_name);
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

void fcx_keyboard_free(fcx_keyboard_t *keyboard) {
  struct fcx_keyboard *kb = keyboard;
  ioctl(kb->fd, UI_DEV_DESTROY);
  close(kb->fd);
  fcx_free_keymap(keyboard);
  free(kb);
}

int _fcx_keyboard_emit(int fd, int type, int code, int val) {
  struct input_event ie;
  ie.type = type;
  ie.code = code;
  ie.value = val;
  ie.time.tv_sec = 0;
  ie.time.tv_usec = 0;
  return write(fd, &ie, sizeof(ie));
}
int fcx_keyboard_type_keycode_down(fcx_keyboard_t *keyboard, int keycode) {
  struct fcx_keyboard *kb = keyboard;
  _fcx_keyboard_emit(kb->fd, EV_KEY, keycode, 1);
  _fcx_keyboard_emit(kb->fd, EV_SYN, SYN_REPORT, 0);
  return 0;
}
int fcx_keyboard_type_keycode_up(fcx_keyboard_t *keyboard, int keycode) {
  struct fcx_keyboard *kb = keyboard;
  _fcx_keyboard_emit(kb->fd, EV_KEY, keycode, 0);
  _fcx_keyboard_emit(kb->fd, EV_SYN, SYN_REPORT, 0);
  return 0;
}
int fcx_keyboard_type_keycode(fcx_keyboard_t *keyboard, int keycode) {
  fcx_keyboard_type_keycode_down(keyboard, keycode);
  fcx_keyboard_type_keycode_up(keyboard, keycode);
  return 0;
}
int fcx_keyboard_type_text(fcx_keyboard_t *keyboard, const char *text) {
  struct fcx_keyboard *kb = keyboard;
  int len = strlen(text);
  char ksym[4] = {0, 0, 0, 0};
  for (int i = 0; i < len; i++) {
    ksym[0] = text[i];
    // int unicode = lk_ksym_to_unicode(kb->lkctx, ksym);
    int unicode = text[i];
    if (unicode <= 0) {
      fprintf(stderr, "[error] lk_ksym_to_unicode returns %d, skip\n", unicode);
      continue;
    }
    struct kbentry kbe = _fcx_keyboard_kbentry_from_unicode(keyboard, unicode);
    if (kbe.kb_value != unicode) {
      fprintf(stderr,
              "[error] _fcx_keyboard_kbentry_from_unicode unicode %C (%d) not "
              "found, skip\n",
              unicode, unicode);
      continue;
    }
    switch (kbe.kb_table) {
    case K_NORMTAB:
      fcx_keyboard_type_keycode(keyboard, kbe.kb_index);
      break;
    case K_SHIFTTAB: {
      fcx_keyboard_type_keycode_down(keyboard, KEY_LEFTSHIFT);
      fcx_keyboard_type_keycode(keyboard, kbe.kb_index);
      fcx_keyboard_type_keycode_up(keyboard, KEY_LEFTSHIFT);
    } break;
    case K_ALTTAB: {
      fcx_keyboard_type_keycode_down(keyboard, KEY_LEFTALT);
      fcx_keyboard_type_keycode(keyboard, kbe.kb_index);
      fcx_keyboard_type_keycode_up(keyboard, KEY_LEFTALT);
    } break;
    case K_ALTSHIFTTAB: {
      fcx_keyboard_type_keycode_down(keyboard, KEY_LEFTSHIFT);
      fcx_keyboard_type_keycode_down(keyboard, KEY_LEFTALT);
      fcx_keyboard_type_keycode(keyboard, kbe.kb_index);
      fcx_keyboard_type_keycode_up(keyboard, KEY_LEFTALT);
      fcx_keyboard_type_keycode_up(keyboard, KEY_LEFTSHIFT);
    } break;
    default:
      fprintf(stderr, "[error] fcx_keyboard unknown kb_table %d", kbe.kb_table);
      break;
    }
  }

  return 0;
}
