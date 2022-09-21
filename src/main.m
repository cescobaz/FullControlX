#include "src/fullcontrol_x_config.h"
#include <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <string.h>

void list_running_applications() {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSArray<NSRunningApplication *> *apps = [workspace runningApplications];
  for (NSRunningApplication *app in apps) {
    if (app.activationPolicy == 0) {
      NSString *process =
          [NSString stringWithFormat:@"proc %d %d %@\n", app.processIdentifier,
                                     app.active, app.localizedName];
      printf("%s", [process UTF8String]);
    }
  }
}

void get_cursor_position() {
  CGEventRef event = CGEventCreate(NULL);
  CGPoint currentCoord = CGEventGetLocation(event);
  CFRelease(event);

  printf("cursor %f %f\n", currentCoord.x, currentCoord.y);
}

#define IS_REQUEST(rl, rr) (strncmp(rl, rr, strlen(rr)) == 0)

const char list_ui_apps[] = "list_ui_apps";
const char get_cursor_pos[] = "get_cursor_pos";

int main(int argc, char *argv[]) {

  char request[1024];
  while (fgets(request, sizeof request, stdin)) {
    request[strcspn(request, "\n")] = '\0';
    if (IS_REQUEST(request, list_ui_apps)) {
      list_running_applications();
    } else if (IS_REQUEST(request, get_cursor_pos)) {
      get_cursor_position();
    } else {
      printf("error input unknown request \"%s\"\n", request);
    }
  };
  return 0;
}
