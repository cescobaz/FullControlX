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

void __fcx_apps_delete_sub(struct json_object *obj, void *userdata) {
  NSLog(@"[debug] __fcx_apps_delete_sub!");
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSNotificationCenter *notificationCenter = [workspace notificationCenter];
  [notificationCenter removeObserver:userdata];
}

struct json_object *fcx_apps_observe(void (*callback)(struct json_object *apps,
                                                      void *data),
                                     void *data) {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSNotificationCenter *notificationCenter = [workspace notificationCenter];
  id block = ^(NSNotification *notification) {
    callback(fcx_ui_apps(), data);
  };
  NSArray *names = @[
    NSWorkspaceDidLaunchApplicationNotification,
    NSWorkspaceDidTerminateApplicationNotification,
    NSWorkspaceDidActivateApplicationNotification
  ];

  struct json_object *subscriptions = json_object_new_array();
  for (NSString *name in names) {
    void *subscription = [notificationCenter addObserverForName:name
                                                         object:workspace
                                                          queue:NULL
                                                     usingBlock:block];

    struct json_object *sub = json_object_new_object();
    json_object_set_userdata(sub, subscription, &__fcx_apps_delete_sub);

    json_object_array_add(subscriptions, sub);
  }

  return subscriptions;
}
