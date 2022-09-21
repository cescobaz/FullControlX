#include "src/fullcontrol_x_config.h"
#include <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <json-c/json.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

void list_running_applications(FILE *output) {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSArray<NSRunningApplication *> *apps = [workspace runningApplications];
  for (NSRunningApplication *app in apps) {
    if (app.activationPolicy == 0) {
      NSString *process =
          [NSString stringWithFormat:@"proc %d %d %@\n", app.processIdentifier,
                                     app.active, app.localizedName];
      fputs([process UTF8String], output);
    }
  }
}

void get_cursor_position(FILE *output) {
  CGEventRef event = CGEventCreate(NULL);
  CGPoint currentCoord = CGEventGetLocation(event);
  CFRelease(event);

  fprintf(output, "cursor %f %f\n", currentCoord.x, currentCoord.y);
}

int read_until(char *buffer, size_t buf_size, char delimiter, FILE *input) {
  int index = 0;
  char c = '\0';

  while (index < buf_size) {
    c = getc(input);
    if (c == EOF || c == delimiter) {
      buffer[index] = '\0';
      return index;
    }
    buffer[index] = c;
    index += 1;
  }

  return index;
}

void log_request_error(char *message, struct json_object *req_obj) {
  const char *req = json_object_to_json_string(req_obj);
  fprintf(stderr, "[error] %s. %s\n", message, req);
}

#define IS_REQUEST(rl, rr) (strncmp(rl, rr, strlen(rr)) == 0)

const char list_ui_apps[] = "list_ui_apps";
const char get_cursor_pos[] = "get_cursor_pos";

//#define BUFFER_SIZE 2048
#define BUFFER_SIZE 1

int main(int argc, char *argv[]) {

  FILE *input = stdin;
  FILE *output = stdout;
  char buffer[BUFFER_SIZE];

  struct json_tokener *tokener = json_tokener_new();
  size_t buffer_offset = BUFFER_SIZE;
  int buffer_len = 0;

  while (true) {

    enum json_tokener_error jerr;
    struct json_object *req_obj;
    do {
      buffer_offset = json_tokener_get_parse_end(tokener);
      buffer_len -= buffer_offset;

      if (buffer_len <= 0) {
        buffer_offset = 0;
        buffer_len = fread(buffer, sizeof(char), BUFFER_SIZE, input);
        if (buffer_len <= 0) {
          return 0;
        }
      }

      req_obj =
          json_tokener_parse_ex(tokener, buffer + buffer_offset, buffer_len);
      jerr = json_tokener_get_error(tokener);
      /*
      printf("[debug] %s %lu %d\n", json_tokener_error_desc(jerr),
             buffer_offset, buffer_len);
             */
    } while (jerr == json_tokener_continue);

    if (jerr != json_tokener_success) {
      fprintf(stderr, "[error] json_tokener_parse_ex error %s\n",
              json_tokener_error_desc(jerr));
      return 1;
    }

    if (!json_object_is_type(req_obj, json_type_array)) {
      json_object_put(req_obj);
      log_request_error("request is not an array", req_obj);
      continue;
    }

    size_t req_len = json_object_array_length(req_obj);
    struct json_object *function_obj = json_object_array_get_idx(req_obj, 0);
    if (req_len == 0 || function_obj == NULL ||
        !json_object_is_type(function_obj, json_type_string)) {
      json_object_put(req_obj);
      log_request_error("request is malformed", req_obj);
      continue;
    }
    const char *function = json_object_get_string(function_obj);

    if (strcmp(function, list_ui_apps) == 0) {
      list_running_applications(output);
    } else if (strcmp(function, get_cursor_pos) == 0) {
      get_cursor_position(output);
    } else {
      log_request_error("request is unknown", req_obj);
    }

    json_object_put(req_obj);
  };
  json_tokener_free(tokener);
  return 0;
}
