#include "../fcx_keyboard.h"
#include "../logger.h"
#include "fcx_keyboard_map.h"
#include <ctype.h>
#include <fcntl.h>
#include <kbdfile.h>
#include <keymap/common.h>
#include <keymap/context.h>
#include <keymap/dump.h>
#include <keymap/kmap.h>
#include <limits.h>
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
  // lk_set_parser_flags(ctx, LK_FLAG_CLEAR_COMPOSE);
  lk_set_parser_flags(ctx, LK_FLAG_PREFER_UNICODE);
  rc = lk_parse_keymap(ctx, fp);
  kbdfile_free(fp);

  keyboard->kfctx = file_ctx;
  keyboard->lkctx = ctx;
  return rc;
}

struct kbentry _fcx_keyboard_kbentry_from_unicode(fcx_keyboard_t *kb,
                                                  int unicode) {
  struct kbentry kbe = {0, 0, USHRT_MAX};
  struct lk_ctx *ctx = ((struct fcx_keyboard *)kb)->lkctx;
  for (int table = 0; table <= 256; table++) {
    if (!lk_map_exists(ctx, table)) {
      FCX_LOG_DEBUG("fcx_keyboard map not exists %d", table);
      continue;
    }
    int totalKeys = lk_get_keys_total(ctx, table);
    for (int keycode = 0; keycode < 256; keycode++) {
      if (!lk_key_exists(ctx, table, keycode)) {
        FCX_LOG_DEBUG("fcx_keyboard keycode not exists %d %d", table, keycode);
        continue;
      }
      int value = lk_get_key(ctx, table, keycode);
      if (value < 0 || value >= USHRT_MAX) {
        continue;
      }
      if (value == unicode) {
        kbe.kb_table = table;
        kbe.kb_index = keycode;
        kbe.kb_value = value;
        FCX_LOG_DEBUG(
            "_fcx_keyboard_kbentry_from_unicode %C -> {%d, %d, %d (%C)}",
            unicode, table, keycode, value, value);
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
  for (int i = 1; i <= 256; i++) {
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
    // int ucode = lk_ksym_to_unicode(kb->lkctx, ksym);
    int unicode = text[i];
    if (unicode <= 0) {
      FCX_LOG_ERR("lk_ksym_to_unicode returns %d, skip", unicode);
      continue;
    }
    struct kbentry kbe = _fcx_keyboard_kbentry_from_unicode(keyboard, unicode);
    if (kbe.kb_value == USHRT_MAX) {
      /* as `man keymaps` says at the end of chapeter 'COMPLETE KEYCODE
       * DEFINITION': 'a-z' and 'A-Z' could have implicit meaning. Lets
       * implement it.
       */
      if (unicode >= 'A' && unicode <= 'Z') {
        unicode = tolower(unicode);
        kbe = _fcx_keyboard_kbentry_from_unicode(keyboard, unicode);
        kbe.kb_table = K_SHIFTTAB;
      } else if (unicode >= 'a' && unicode <= 'z') {
        unicode = toupper(unicode);
        kbe = _fcx_keyboard_kbentry_from_unicode(keyboard, unicode);
        kbe.kb_table = K_SHIFTTAB;
      }
      if (kbe.kb_value == USHRT_MAX) {
        fprintf(
            stderr,
            "[error] _fcx_keyboard_kbentry_from_unicode unicode %C (%d) not "
            "found, skip\n",
            unicode, unicode);
        continue;
      }
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
      FCX_LOG_ERR("fcx_keyboard unknown kb_table %d", kbe.kb_table);
      break;
    }
  }

  return 0;
}

int fcx_keyboard_type_symbol(fcx_keyboard_t *keyboard, const char *symbol) {
  char **symbols = fcx_keyboard_map_symbols();
  int size = fcx_keyboard_map_symbols_size();
  for (int i = 0; i < size; i++) {
    char *s = symbols[i];
    if (s != 0 && strcmp(symbol, s) == 0) {
      return fcx_keyboard_type_keycode(keyboard, i);
    }
  }
  return 1;
}
