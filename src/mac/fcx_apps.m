#include "../fcx_apps.h"
#include <AppKit/AppKit.h>

struct json_object *fcx_ui_apps() {
  struct json_object *result = json_object_new_array();
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSArray<NSRunningApplication *> *apps = [workspace runningApplications];
  for (NSRunningApplication *app in apps) {
    if (app.activationPolicy == 0) {
      struct json_object *ui_app = json_object_new_object();
      json_object_object_add(ui_app, "pid",
                             json_object_new_uint64(app.processIdentifier));
      json_object_object_add(ui_app, "focus",
                             json_object_new_boolean(app.active));
      json_object_object_add(
          ui_app, "localized_name",
          json_object_new_string([app.localizedName UTF8String]));
      json_object_array_add(result, ui_app);
    }
  }
  return result;
}
